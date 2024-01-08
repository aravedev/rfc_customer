use portafolio
-- Checking data
select * from [dbo].[merchant];

-- Checking unique values for user_id, Mer_id, category. 
select
	COUNT(distinct User_id) as total_customers,
	COUNT(distinct Mer_Id) as total_unique_items,
	COUNT(distinct Category_In_English) as total_categories
from [dbo].[merchant];

-- Result: total_customers: 33457 , total_unique_items:56, total_categories:7 

-- Analysis:

-- What category was the most redeemed ?
select
	Category_In_English,
	sum(Points) as total_points_redeemed, -- always use an aggregate function
	AVG(Points) as average_points_redeemed,
	ROUND(sum(Trx_Vlu), 2) as total_pounds
from [dbo].[merchant]
group by Category_In_English
order by total_points_redeemed desc;

-- Result: The most redeemed category was: Grocery (99.183.611), follow by F&B (food and beberage) (23.044.179) points.

-- Who are our top 5 customers

select TOP 5 
	User_Id,
	ROUND(sum(Trx_Vlu),2) as total_spent
from [dbo].[merchant]
group by User_Id
order by total_spent desc;

-- using RFM, where:
-- R = Recency (last order date)
-- F =  Frequency (count total orders)
-- M = Monetary value (total spend)

-- We dont have dates, but we already know the total days has passed for each transaction
-- we can find the min value of total days, and get the last transaction for each customer

select 
	User_Id,
	ROUND(sum(Trx_Vlu),3) as monetary_value,
	ROUND(avg(Trx_Vlu),3) as average_transaction,
	count(Trx_Rank) as frequency ,
	MIN(Trx_Age) as recency
from [dbo].[merchant]
group by User_id
order by 5;

-- Creating a NTILE, we are going to group our customers in 5 segments and identify based on their behavior actives and who
-- are left.
-- using windows function rfm , checking if the code is working
/*
;with rfm as (
	select 
		User_Id,
		ROUND(sum(Trx_Vlu),3) as monetary_value,
		ROUND(avg(Trx_Vlu),3) as average_transaction,
		count(Trx_Rank) as frequency ,
		MIN(Trx_Age) as recency
	from [dbo].[merchant]
	group by User_id
)
select r.*
from rfm r
*/

-- basically the results explains:
-- a higher rfm_recency means our customer has purchased recently
-- a higher rfm_frequency menas our customer has purchased a significant amount of items
-- a a higher rfm_average_transaction (avg monetary value) a expent enough money to be considered VIP
/*
;with rfm as (
	select 
		User_Id,
		ROUND(sum(Trx_Vlu),3) as monetary_value,
		ROUND(avg(Trx_Vlu),3) as average_transaction,
		count(Trx_Rank) as frequency ,
		MIN(Trx_Age) as recency
	from [dbo].[merchant]
	group by User_id
)
select r.*,
	NTILE(4) OVER (order by recency desc) as rfm_recency,
	NTILE(4) OVER (order by frequency ) as rfm_frequency,
	NTILE(4) OVER (order by average_transaction) as rfm_average_transaction
from rfm r
order by frequency desc;
*/

-- adding 2 new columns rfm_cell (sum of rfm categories) and rfm_cell_string (concatenating rfm categories)
/*
;with rfm as (
	select 
		User_Id,
		ROUND(sum(Trx_Vlu),3) as monetary_value,
		ROUND(avg(Trx_Vlu),3) as average_transaction,
		count(Trx_Rank) as frequency ,
		MIN(Trx_Age) as recency
	from [dbo].[merchant]
	group by User_id
),
-- creating a second window
rfm_calc as (
-- spliting by batches
	select r.*,
		NTILE(4) OVER (order by recency desc) as rfm_recency,
		NTILE(4) OVER (order by frequency ) as rfm_frequency,
		NTILE(4) OVER (order by average_transaction) as rfm_average_transaction
	from rfm r
) 
select c.*, 
	rfm_recency+rfm_frequency+rfm_average_transaction as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_average_transaction as varchar) as rfm_cell_string
from rfm_calc as c

*/

-- creating a temp table
DROP TABLE IF EXISTS #rfm
;with rfm as (
	select 
		User_Id,
		ROUND(sum(Trx_Vlu),3) as monetary_value,
		ROUND(avg(Trx_Vlu),3) as average_transaction,
		count(Trx_Rank) as frequency ,
		MIN(Trx_Age) as recency
	from [dbo].[merchant]
	group by User_id
),
-- creating a second window
rfm_calc as (
-- spliting by batches
	select r.*,
		NTILE(4) OVER (order by recency desc) as rfm_recency,
		NTILE(4) OVER (order by frequency ) as rfm_frequency,
		NTILE(4) OVER (order by average_transaction) as rfm_average_transaction
	from rfm r
) 
select c.*, 
	rfm_recency+rfm_frequency+rfm_average_transaction as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_average_transaction as varchar) as rfm_cell_string
into #rfm -- creating the table while you run the query
from rfm_calc as c

-- checking the #rfm temp table
select * from #rfm

-- now assigning categories for each customer
select 
	User_Id,
	rfm_recency,
	rfm_frequency,
	rfm_average_transaction,
	case 
		when rfm_cell between 10 AND 12 then 'loyal'
		when rfm_cell between 8 AND 9 then 'active'
		when rfm_cell between 6 AND 7 then 'potential churners'
		when rfm_cell between 4 AND 5 then 'new customer'
		when rfm_cell between 2 AND 3 then 'slipping away'
		when rfm_cell in (1) then 'lost customer'
	end rfm_segment
from #rfm

-- what products did sell the most?

select * from [dbo].[merchant]

-- first checking the total items sold by mer_id
select 
	Mer_Id,
	COUNT(*) as total_items
from [dbo].[merchant]
group by Mer_Id
order by 2 desc


