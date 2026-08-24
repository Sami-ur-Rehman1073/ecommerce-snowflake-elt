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