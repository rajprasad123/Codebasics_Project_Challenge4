-- 1  Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region. --

SELECT distinct market
 FROM gdb023.dim_customer
 where customer='Atliq Exclusive' 
        and region='APAC';
 
 
 -- 2  What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

 with 
cte20 as
(select count(distinct(product_code)) as unique_products_2020
from fact_manufacturing_cost as f 
where cost_year=2020),
cte21 as
(select count(distinct(product_code)) as unique_products_2021
from fact_manufacturing_cost as f 
where cost_year=2021)

select *,
		concat(round((unique_products_2021-unique_products_2020)*100/unique_products_2020,2),'%') as percentage_chg		
from cte20
cross join
cte21;

-- 3 Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
-- The final output contains 2 fields,
-- segment
-- product_count

select segment,
       count(distinct(product)) as product_count
from dim_product
group by segment
order by count(distinct(product)) desc;

-- 4  Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

with
cte20 as
(select 
	p.segment,
    count(distinct(f.product_code)) as product_count_2020		
from fact_sales_monthly as f
join 
	dim_product as p
using(product_code)
where fiscal_year=2020
group by segment
order by product_count_2020 desc
),
cte21 as
(select
		p.segment,
        count(distinct(f.product_code)) as product_count_2021

from fact_sales_monthly as f
join 
	dim_product as p
using(product_code)
where fiscal_year=2021
group by segment
order by product_count_2021 desc),
cte_table as 
(select 
	cte20.segment,
    product_count_2021,
    product_count_2020,
    (product_count_2021-product_count_2020) as difference
		
from cte20
join cte21
using(segment)
)

select
	segment,
    product_count_2021,
    product_count_2020,
    difference
from cte_table
order by difference desc;

 -- 5 Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cos

 select 
	p.product_code,
	p.product,
	m.manufacturing_cost
from dim_product as p
join fact_manufacturing_cost as m
using(product_code)
where 
manufacturing_cost=(select max(manufacturing_cost) from fact_manufacturing_cost) or 
manufacturing_cost=(select min(manufacturing_cost) from fact_manufacturing_cost)
order by manufacturing_cost desc;

-- 6 Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
-- The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

select distinct cust.customer_code,
cust.customer,
concat(round(avg(inv.pre_invoice_discount_pct)*100,2),'%') as average_discount_percentage 
from fact_pre_invoice_deductions as inv
 inner join dim_customer as cust
on inv.customer_code=cust.customer_code
where inv.fiscal_year=2021 and cust.market='India'
group by cust.customer_code
order by avg(inv.pre_invoice_discount_pct) desc
limit 5
;

-- 7 Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

select monthname(mth.date) as Month,
extract(year from mth.date) as Year,
 round(sum(grsp.gross_price*mth.sold_quantity),0) as gross_sales_amount
from fact_sales_monthly as mth
inner join fact_gross_price as grsp
on mth.product_code=grsp.product_code and
mth.fiscal_year=grsp.fiscal_year
inner join dim_customer as cust
on mth.customer_code=cust.customer_code
where cust.customer='Atliq Exclusive'
group by mth.date
;


-- 8 In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the 
-- total_sold_quantity,
-- Quarter
-- total_sold_quantity

select case when month(date) in (09,10,11) then 'Q1'  
            when month(date) in (12,01,02) then 'Q2' 
            when month(date) in (03,04,05) then 'Q3' 
            when month(date) in (06,07,08) then 'Q4' 
            else month(date)
            end as Quarter,
            sum(sold_quantity) as Total_sold_quantity
 from fact_sales_monthly
 where fiscal_year=2020
 group by case when month(date) in (09,10,11) then 'Q1' 
            when month(date) in (12,01,02) then 'Q2' 
            when month(date) in (03,04,05) then 'Q3' 
            when month(date) in (06,07,08) then 'Q4' 
            else month(date) 
            end
order by sum(sold_quantity) desc;           
            
 -- 9 Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
-- The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

 with cte as(
select
    c.channel,
    round(sum(s.sold_quantity*g.gross_price)/1000000,2) as gross_sales_mln
from dim_customer as c
join fact_sales_monthly as s
on
	c.customer_code=s.customer_code
join fact_gross_price as g
on
	g.product_code=s.product_code and
    g.fiscal_year=s.fiscal_year
where s.fiscal_year=2021
group by channel
order by gross_sales_mln desc
)
select
	*,
    CONCAT(round(gross_sales_mln*100/sum(gross_sales_mln) over(),2),"%")as percentage
from cte;
 
 -- 10 Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order

with 
cte1 as (
select 
    p.division,
	p.product_code,
	p.product,
	sum(s.sold_quantity) as Total_sold_quantity
from dim_product as p
join fact_sales_monthly as s
on 
   p.product_code=s.product_code
 where 
      s.fiscal_year=2021
 group by p.division,
          product_code
 order by sum(s.sold_quantity) desc
 ),
 cte2 as (
 select *,
 dense_rank() over(partition by division order by Total_sold_quantity) as rk
 from cte1
 )
 select division,
        product_code,
        product,
        Total_sold_quantity,
         rk
 from cte2
 where rk<=3;
 
 
 
 
