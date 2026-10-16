/*
Product Report

Purpose:
	- This report consolidates key product metrics and behaviors.

Highlights:
	1. Gathers essentials fields such as product name, category, subcategory, and cost.
	2. Segement products by revenue to identify High Performers, Mid-Range,or Low-Performers.
	3. Agrregation product-level metrics.
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since lst order)
		- average order value
		- average monthly spend
*/


CREATE VIEW product_report AS

WITH prod_base_query AS (

/* 1) Base query: Retrieves core columns from tables */

SELECT 
s.order_number,
s.order_date,
p.start_date,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost,
s.quantity,
s.sales_amount,
s.customer_key
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON s.product_key = p.product_key
WHERE order_date IS NOT NULL
)

, product_aggregation AS (

/* 2) Product Aggregation: Summarize key metrics at product level */

SELECT
product_key,
product_name,
category,
subcategory,
cost,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT customer_key) AS total_customers,
MAX(order_date) AS last_sales_date,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan,
ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity,0)),1) AS avg_selling_price
FROM prod_base_query
GROUP BY
product_key,
product_name,
category,
subcategory,
cost
)

/* 3) Final Query: Combine all product results into one output */

SELECT
product_key,
product_name,
category,
subcategory,
cost,
last_sales_date,
DATEDIFF(month, last_sales_date, GETDATE()) AS recency,
CASE WHEN total_sales > 50000 THEN 'High-Performer'
	WHEN total_sales >= 10000 THEN 'Mid-Range'
	ELSE 'Low-Performer'
END product_segment,
lifespan,
total_orders,
total_sales,
total_quantity,
total_customers,
avg_selling_price,
-- Average Order Revenue (AOR)
CASE WHEN total_orders = 0 THEN 0
	ELSE total_sales / total_orders 
END AS avg_order_revenue,
-- Average Monthly Revenue
CASE WHEN lifespan = 0 THEN total_sales
	ELSE total_sales / lifespan
END AS avg_monthly_revenue
FROM product_aggregation;