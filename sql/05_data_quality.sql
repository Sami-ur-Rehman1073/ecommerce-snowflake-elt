USE DATABASE ECOMMERCE_DB;
USE WAREHOUSE ECOMMERCE_WH;


-- checking null customer id's

SELECT COUNT(*) AS null_customer_ids
FROM RAW.RAW_CUSTOMERS
WHERE customer_id IS NULL;


-- checking duplicate customers

SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM RAW.RAW_CUSTOMERS
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- NULL product IDs


SELECT COUNT(*) AS null_product_ids
FROM RAW.RAW_PRODUCTS
WHERE product_id IS NULL;



-- Invalid prices


SELECT COUNT(*) AS invalid_prices
FROM RAW.RAW_PRODUCTS
WHERE unit_price <= 0;



-- Duplicate products

SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM RAW.RAW_PRODUCTS
GROUP BY product_id
HAVING COUNT(*) > 1;



-- NULL order IDs



SELECT COUNT(*) AS null_order_ids
FROM RAW.RAW_ORDERS
WHERE order_id IS NULL;


-- Invalid statuses



SELECT COUNT(*) AS invalid_statuses
FROM RAW.RAW_ORDERS
WHERE UPPER(TRIM(status))
      NOT IN ('COMPLETED', 'PENDING', 'CANCELLED');



-- Duplicate orders


SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM RAW.RAW_ORDERS
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Orders without customers

SELECT COUNT(*) AS orphan_orders
FROM RAW.RAW_ORDERS o
LEFT JOIN RAW.RAW_CUSTOMERS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Order items without products


SELECT COUNT(*) AS orphan_order_items
FROM RAW.RAW_ORDER_ITEMS oi
LEFT JOIN RAW.RAW_PRODUCTS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;



-- Order items without orders


SELECT COUNT(*) AS orphan_order_items
FROM RAW.RAW_ORDER_ITEMS oi
LEFT JOIN RAW.RAW_ORDERS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

