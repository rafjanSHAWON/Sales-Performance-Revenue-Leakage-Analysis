/*---------------------------------------------------------------------------------------------------------------------
                                PROJECT 1: Sales Performance & Revenue Leakage Dashboard
*/---------------------------------------------------------------------------------------------------------------------

/*
Business Problem:
The company's sales are growing, but profit is unstable.
Managment doesn't know:

1. Which products leak revenue.
2. Which regions underperform.
3. Why discounts hurt margins.
*/

/*
Key Metrics:
    1. Total Revenue
    2. Gross Margin %
    3. Discount Impact
    4. Region-wise Sales Growth
    5. Product-wise Profitability
*/
------------------------------------------------------------------------------------------------------------------------

--1. DATA HEALTH & VALIDATION (ALWAYS FIRST)
-- ROW COUNT

SELECT
    'customers' AS table_name,
    COUNT(*)
FROM
    customers

UNION ALL

SELECT
    'products',
    COUNT(*)
FROM
    products

UNION ALL

SELECT
    'orders',
    COUNT(*)
FROM
    orders
UNION ALL

SELECT
    'order_item',
    COUNT(*)
FROM
    order_items;
---------------------------------------------------------------------------------------------------------
--                                   Total Revenue
-----------------------------------------------------------------------------------------------------------
SELECT
    ROUND(SUM(oi.quantity * p.selling_price * (1- oi.discount)),2) AS revenue
FROM
    order_items AS oi
JOIN
    products AS p 
ON
    oi.product_id = p.product_id;
-----------------------------------------------------------------------------------------------------------
--                              cost_of_goods_sold (COGS)
-----------------------------------------------------------------------------------------------------------
SELECT
    ROUND(SUM(oi.quantity * p.cost_price),2) AS cost_of_goods_sold
FROM
    order_items AS oi
JOIN
    products AS p
ON
    oi.product_id = p.product_id;
-----------------------------------------------------------------------------------------------------------
--                                   Gross Margin %
-----------------------------------------------------------------------------------------------------------
SELECT
    ROUND(
        (SUM(oi.quantity * p.selling_price * (1 - oi.discount)) - SUM(oi.quantity * p.cost_price)) 
        / SUM(oi.quantity * p.selling_price * (1 - oi.discount)) * 100, 2) AS gross_margin_percentg
FROM
    order_items AS oi
JOIN
    products AS p
ON
    oi.product_id = p.product_id;
-----------------------------------------------------------------------------------------------------------
--                                    Discount Impact
-----------------------------------------------------------------------------------------------------------
SELECT
    ROUND(
        (SUM(oi.quantity * p.selling_price) - SUM(oi.quantity * p.selling_price * (1 - oi.discount))) 
        / SUM(oi.quantity * p.selling_price) * 100, 2) AS discount_impact_percent
FROM
    order_items AS oi
JOIN
    products AS p
ON
    oi.product_id = p.product_id;
-----------------------------------------------------------------------------------------------------------

--                                 Yearly, Monthly Revenue
-- Formula:
            -- Revenue = total_amount - discount_amount
-------------------------------------------------------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM o.order_date) AS year,
    EXTRACT(MONTH FROM o.order_date) AS month,
    SUM(p.selling_price - oi.discount) AS revenues
FROM 
    orders AS o
LEFT JOIN
    order_items AS oi
ON
    o.order_id = oi.order_id
LEFT JOIN
    products AS p
ON
    oi.product_id = p.product_id
GROUP BY 
    EXTRACT(YEAR FROM o.order_date),
    EXTRACT(MONTH FROM o.order_date)
ORDER BY
    SUM(p.selling_price - oi.discount) DESC;

-- Sales true growth year over year and month over month 
-- we can see Yearly and monthly total sale

-------------------------------------------------------------------------------------------------------------
--                                     Gross Sale
-- FORMULA:
            -- Gross Sale = SUM(total_amount)
-------------------------------------------------------------------------------------------------------------

SELECT
    EXTRACT(YEAR FROM o.order_date) AS year,
    EXTRACT(MONTH FROM o.order_date) AS month,
    SUM(selling_price) AS gross_sale
FROM 
    orders AS o
LEFT JOIN
    order_items AS oi
ON
    o.order_id = oi.order_id
LEFT JOIN
    products AS p
ON
    oi.product_id = p.product_id
GROUP BY 
    EXTRACT(YEAR FROM o.order_date),
    EXTRACT(MONTH FROM o.order_date)
ORDER BY
    SUM(selling_price) DESC;

----------------------------------------------------------------------------------------------------------
--                               orders(total transaction)
-- number of completed purchases
-- Formula:
        --Orders=Count(Distinct order_id)
----------------------------------------------------------------------------------------------------------

SELECT
    EXTRACT(YEAR FROM order_date)AS year,
    EXTRACT(MONTH FROM order_date)AS month,
    COUNT(DISTINCT order_id)AS total_order
FROM 
    orders
GROUP BY    
    EXTRACT(YEAR FROM order_date),
    EXTRACT(MONTH FROM order_date);
----------------------------------------------------------------------------------------------

--                                AVERAGE ORDER VALUE(AOV)
-- average money spend per order
--Formula: Revenue / orders
--Net Revenue = SUMX(Sales, Sales[Quantity] * Sales[UnitPrice] * (1 - Sales[Discount]))
------------------------------------------------------------------------------------------------
SELECT
    ROUND(SUM(oi.quantity * p.selling_price * (1-oi.discount)) / COUNT(DISTINCT o.order_id),2)
FROM
    orders AS o
LEFT JOIN
    order_items AS oi
ON
    o.order_id = oi.order_id
LEFT JOIN
    products AS p
ON
    oi.product_id = p.product_id;
---------------------------------------------------------------------------------------------------

--                       Time- Based sales Analysis(Very Important)
-- Monthly Revenue Trend
---------------------------------------------------------------------------------------------------

SELECT
    EXTRACT(MONTH FROM o.order_date)AS months,
    ROUND(SUM(oi.quantity * p.selling_price * (1-oi.discount)) / COUNT(DISTINCT o.order_id),2)
FROM
    orders AS o
LEFT JOIN
    order_items AS oi
ON
    o.order_id = oi.order_id
LEFT JOIN
    products AS p
ON
    oi.product_id = p.product_id
GROUP BY    
    EXTRACT(MONTH FROM o.order_date)
ORDER BY
    ROUND(SUM(oi.quantity * p.selling_price * (1-oi.discount)) / COUNT(DISTINCT o.order_id),2) DESC;
------------------------------------------------------------------------------------------------------

--                         Revenue Leakge Analysis( this is the heart)
-- Dsicount Impact on Revenue
-------------------------------------------------------------------------------------------------------
SELECT
    ROUND(AVG(oi.discount)*100,2) AS avg_discount_price,
    SUM(oi.quantity * p.selling_price * oi.discount) AS revenue_lost
FROM
    orders AS o
LEFT JOIN
    order_items AS oi
ON
    o.order_id = oi.order_id
LEFT JOIN
    products AS p
ON
    oi.product_id = p.product_id;
-- Total revenue leakage caused by discounting
-----------------------------------------------------------------------------------------------------------

--                             Revenue by Discount Bucket
SELECT
    CASE
        WHEN oi.discount = 0 THEN 'NO DISCOUNT'
        WHEN oi.discount <= 0.10 THEN 'LOW'
        WHEN oi.discount <=0.20 THEN 'MEDIUM'
        ELSE 'HIGH'
    END AS discount_level,
    ROUND(SUM(oi.quantity * p.selling_price * (1-oi.discount)),2) AS rvenues
FROM
    orders AS o
LEFT JOIN
    order_items AS oi
ON
    o.order_id = oi.order_id
LEFT JOIN
    products AS p
ON
    oi.product_id = p.product_id
GROUP BY 
    discount_level;
-----------------------------------------------------------------------------------------------------

--                                    Which product leak revenue?
-- SQL Query (product - level Revenue leakage)
SELECT
    p.product_name,
    SUM(oi.quantity * p.selling_price)AS expectd_revenue,
    SUM(oi.quantity * p.selling_price * (1- oi.discount))AS actual_revenue,
    ROUND(SUM(oi.quantity * p.selling_price * oi.discount),2)AS revenue_leakage

FROM
    orders AS o
LEFT JOIN
    order_items AS oi
ON
    o.order_id = oi.order_id
LEFT JOIN
    products AS p
ON
    oi.product_id = p.product_id
GROUP BY
    p.product_name
ORDER BY
    revenue_leakage DESC;
/*
What this shows:
1. Expected revenue - without discounts
2. Actual revenue - after discount
3.Revenue leakage - money lost due to discounting

Business Conclusion: Product at the top of this list are liking most Revenue
due to aggressive or uncontrolled discounting.
This item need pricing review, discount caps, or margin protction strategies.
*/
-------------------------------------------------------------------------------------------------------------------

--                                    Which Regions Underperform?
--Region-wise performance & leakage

SELECT
    c.region,
    COUNT(DISTINCT o.order_id)AS total_orders,
    ROUND(SUM(oi.quantity * p.selling_price * (1- oi.discount)),2) AS actual_revenues,
    ROUND(SUM(oi.quantity * p.selling_price * oi.discount),2)AS revenue_leakages
FROM
    customers AS c
LEFT JOIN
    orders AS o
ON
    c.customer_id = o.customer_id
LEFT JOIN
    order_items AS oi
ON
    o.order_id = oi.order_id
LEFT JOIN
    products AS p
ON
    oi.product_id = p.product_id
GROUP BY
    c.region
ORDER BY
    actual_revenues;
/*
What this shows
1.Orver volum per region
2.Actual revenue generated
3.Revenue lost due to discounting

Business Conclusion:
Regions with low actual revenue but high leakage are underperforming.
This indicates poor pricing disclpline, excessive discount, or weaker purchainsg power 
*/
-----------------------------------------------------------------------------------------------------------

--                Why Discounts hurt margins(The most important)
-- SQL Query(Margin Impact Analysis)

SELECT
    p.product_name,
    ROUND(SUM(oi.quantity * (p.selling_price - p.cost_price)),2)AS expected_margin,
    ROUND(SUM(oi.quantity *((p.selling_price * (1- oi.discount)) - p.cost_price)),2)AS actual_margins,
    ROUND(SUM(oi.quantity * p.selling_price * oi.discount),2)AS margin_lost_due_to_discount

FROM
    customers AS c
LEFT JOIN
    orders AS o
ON
    c.customer_id = o.customer_id
LEFT JOIN
    order_items AS oi
ON
    o.order_id = oi.order_id
LEFT JOIN
    products AS p
ON
    oi.product_id = p.product_id
GROUP BY    
    p.product_name
ORDER BY
    margin_lost_due_to_discount DESC;

/*
What this prove
1.Discount reduce revenue
2.Costs remain fixed
3.Margin shrinks faster then revenue

Business Conclusion:
Discount hurt margins because they reduce selling price while product cost
remain unchanged. Even moderate discount can turn profitable product into
low margin or loss making items. 
*/
------------------------------------------------------------------------------------------------------------

