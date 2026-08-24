-- ============================================================
-- E-COMMERCE SNOWFLAKE ETL PIPELINE
-- File: 06_business_queries.sql
--
-- Purpose:
-- This file contains business analytics queries that operate
-- on the transformed ANALYTICS layer.
--
-- These queries demonstrate how the data warehouse can be
-- used to answer common e-commerce business questions.
--
-- IMPORTANT:
-- This file does NOT modify the warehouse.
--
-- It only READS data from:
--
--     DIM_CUSTOMERS
--     DIM_PRODUCTS
--     FACT_ORDERS
--     FACT_ORDER_ITEMS
--
-- ============================================================


-- ============================================================
-- STEP 1: SELECT DATABASE, SCHEMA AND WAREHOUSE
-- ============================================================
--
-- We are working with the ANALYTICS layer because the data
-- here has already passed through the RAW and data-quality
-- stages.
-- ============================================================

USE DATABASE ECOMMERCE_DB;

USE SCHEMA ANALYTICS;

USE WAREHOUSE ECOMMERCE_WH;


-- ============================================================
-- QUERY 1: TOTAL REVENUE
-- ============================================================
--
-- Business question:
--
--     "What is the total revenue generated from completed
--      orders?"
--
-- We use FACT_ORDER_ITEMS because revenue is calculated at
-- the order-item level.
--
-- We join FACT_ORDERS so that we can filter only COMPLETED
-- orders.
--
-- Formula:
--
--     Revenue = SUM(item_total)
--
-- ============================================================

SELECT
    ROUND(SUM(oi.item_total), 2) AS total_revenue

FROM FACT_ORDER_ITEMS oi

JOIN FACT_ORDERS o
    ON oi.order_id = o.order_id

WHERE o.status = 'COMPLETED';


-- ============================================================
-- QUERY 2: MONTHLY REVENUE
-- ============================================================
--
-- Business question:
--
--     "How much revenue did we generate each month?"
--
-- DATE_TRUNC('MONTH', order_date) converts each order date
-- into its corresponding month.
--
-- Example:
--
--     2026-01-15 → 2026-01-01
--     2026-01-25 → 2026-01-01
--     2026-02-10 → 2026-02-01
--
-- Orders from the same month are then grouped together.
-- ============================================================

SELECT
    DATE_TRUNC('MONTH', o.order_date) AS sales_month,

    ROUND(
        SUM(oi.item_total),
        2
    ) AS revenue

FROM FACT_ORDERS o

JOIN FACT_ORDER_ITEMS oi
    ON o.order_id = oi.order_id

WHERE o.status = 'COMPLETED'

GROUP BY
    DATE_TRUNC('MONTH', o.order_date)

ORDER BY
    sales_month;


-- ============================================================
-- QUERY 3: TOP 10 PRODUCTS BY REVENUE
-- ============================================================
--
-- Business question:
--
--     "Which products generate the most revenue?"
--
-- FACT_ORDER_ITEMS contains the sales information.
--
-- DIM_PRODUCTS gives us descriptive information such as:
--
--     product_name
--     category
--
-- We join the two tables using product_id.
--
-- Only COMPLETED orders are included.
-- ============================================================

SELECT
    p.product_id,
    p.product_name,
    p.category,

    ROUND(
        SUM(oi.item_total),
        2
    ) AS revenue

FROM FACT_ORDER_ITEMS oi

JOIN FACT_ORDERS o
    ON oi.order_id = o.order_id

JOIN DIM_PRODUCTS p
    ON oi.product_id = p.product_id

WHERE o.status = 'COMPLETED'

GROUP BY
    p.product_id,
    p.product_name,
    p.category

ORDER BY
    revenue DESC

LIMIT 10;


-- ============================================================
-- QUERY 4: TOP 10 CUSTOMERS BY SPENDING
-- ============================================================
--
-- Business question:
--
--     "Which customers have spent the most money?"
--
-- We combine:
--
--     DIM_CUSTOMERS
--          ↓
--     FACT_ORDERS
--          ↓
--     FACT_ORDER_ITEMS
--
-- DIM_CUSTOMERS gives us customer information.
--
-- FACT_ORDERS connects customers to orders.
--
-- FACT_ORDER_ITEMS gives us the monetary value of the
-- products purchased.
-- ============================================================

SELECT
    c.customer_id,
    c.customer_name,
    c.city,

    ROUND(
        SUM(oi.item_total),
        2
    ) AS total_spending

FROM DIM_CUSTOMERS c

JOIN FACT_ORDERS o
    ON c.customer_id = o.customer_id

JOIN FACT_ORDER_ITEMS oi
    ON o.order_id = oi.order_id

WHERE o.status = 'COMPLETED'

GROUP BY
    c.customer_id,
    c.customer_name,
    c.city

ORDER BY
    total_spending DESC

LIMIT 10;


-- ============================================================
-- QUERY 5: REVENUE BY PRODUCT CATEGORY
-- ============================================================
--
-- Business question:
--
--     "Which product categories generate the most revenue?"
--
-- DIM_PRODUCTS contains category information.
--
-- FACT_ORDER_ITEMS contains item revenue.
-- ============================================================

SELECT
    p.category,

    ROUND(
        SUM(oi.item_total),
        2
    ) AS revenue

FROM FACT_ORDER_ITEMS oi

JOIN FACT_ORDERS o
    ON oi.order_id = o.order_id

JOIN DIM_PRODUCTS p
    ON oi.product_id = p.product_id

WHERE o.status = 'COMPLETED'

GROUP BY
    p.category

ORDER BY
    revenue DESC;


-- ============================================================
-- QUERY 6: AVERAGE ORDER VALUE
-- ============================================================
--
-- Business question:
--
--     "What is the average amount spent per completed order?"
--
-- Formula:
--
--     AOV = Total Revenue / Number of Orders
--
-- We use COUNT(DISTINCT order_id) because an order can contain
-- multiple order-item rows.
--
-- Example:
--
-- Order 1001:
--     Product A = 500
--     Product B = 300
--
-- FACT_ORDER_ITEMS contains:
--
-- 1001 | A | 500
-- 1001 | B | 300
--
-- COUNT(*) would return 2.
--
-- But there is only ONE order.
--
-- Therefore we use:
--
--     COUNT(DISTINCT o.order_id)
--
-- ============================================================

SELECT
    ROUND(
        SUM(oi.item_total)
        /
        NULLIF(
            COUNT(DISTINCT o.order_id),
            0
        ),
        2
    ) AS average_order_value

FROM FACT_ORDERS o

JOIN FACT_ORDER_ITEMS oi
    ON o.order_id = oi.order_id

WHERE o.status = 'COMPLETED';


-- ============================================================
-- QUERY 7: ORDER COUNT BY STATUS
-- ============================================================
--
-- Business question:
--
--     "How many orders are completed, pending and cancelled?"
--
-- This gives us a simple overview of the order lifecycle.
-- ============================================================

SELECT
    status,
    COUNT(*) AS order_count

FROM FACT_ORDERS

GROUP BY
    status

ORDER BY
    order_count DESC;


-- ============================================================
-- QUERY 8: REVENUE BY CUSTOMER CITY
-- ============================================================
--
-- Business question:
--
--     "Which cities generate the most revenue?"
--
-- DIM_CUSTOMERS provides the city.
--
-- FACT_ORDERS connects the customer to an order.
--
-- FACT_ORDER_ITEMS provides the revenue.
-- ============================================================

SELECT
    c.city,

    ROUND(
        SUM(oi.item_total),
        2
    ) AS revenue

FROM DIM_CUSTOMERS c

JOIN FACT_ORDERS o
    ON c.customer_id = o.customer_id

JOIN FACT_ORDER_ITEMS oi
    ON o.order_id = oi.order_id

WHERE o.status = 'COMPLETED'

GROUP BY
    c.city

ORDER BY
    revenue DESC;


-- ============================================================
-- QUERY 9: TOTAL QUANTITY SOLD BY PRODUCT
-- ============================================================
--
-- Business question:
--
--     "Which products have sold the most units?"
--
-- This is different from revenue.
--
-- A product could have:
--
--     High quantity sold
--     but relatively low revenue
--
-- or:
--
--     Low quantity sold
--     but very high revenue
--
-- Therefore quantity and revenue are two different metrics.
-- ============================================================

SELECT
    p.product_id,
    p.product_name,

    SUM(oi.quantity) AS total_quantity_sold

FROM FACT_ORDER_ITEMS oi

JOIN FACT_ORDERS o
    ON oi.order_id = o.order_id

JOIN DIM_PRODUCTS p
    ON oi.product_id = p.product_id

WHERE o.status = 'COMPLETED'

GROUP BY
    p.product_id,
    p.product_name

ORDER BY
    total_quantity_sold DESC

LIMIT 10;


-- ============================================================
-- QUERY 10: COMPLETED ORDERS BY CUSTOMER
-- ============================================================
--
-- Business question:
--
--     "How many completed orders has each customer placed?"
--
-- We use COUNT(DISTINCT order_id) because an order can contain
-- multiple order-item rows.
-- ============================================================

SELECT
    c.customer_id,
    c.customer_name,

    COUNT(DISTINCT o.order_id) AS completed_orders

FROM DIM_CUSTOMERS c

JOIN FACT_ORDERS o
    ON c.customer_id = o.customer_id

WHERE o.status = 'COMPLETED'

GROUP BY
    c.customer_id,
    c.customer_name

ORDER BY
    completed_orders DESC;


-- ============================================================
-- BUSINESS ANALYTICS COMPLETE
-- ============================================================
--
-- We now have queries answering:
--
--     1. Total revenue
--     2. Monthly revenue
--     3. Top products by revenue
--     4. Top customers by spending
--     5. Revenue by category
--     6. Average order value
--     7. Orders by status
--     8. Revenue by city
--     9. Top products by quantity
--    10. Completed orders by customer
--
-- These queries demonstrate how the transformed Snowflake
-- warehouse can support business analytics.
--
-- ============================================================