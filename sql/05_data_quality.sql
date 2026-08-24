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