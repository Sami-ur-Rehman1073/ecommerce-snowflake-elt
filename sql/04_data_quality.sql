-- ============================================================
-- E-COMMERCE SNOWFLAKE ETL PIPELINE
-- File: 04_data_quality.sql
--
-- Purpose:
-- This script validates the data loaded into the RAW layer
-- before the data is transformed into the ANALYTICS layer.
--
-- The checks cover:
--
--   1. NULL identifiers
--   2. Duplicate identifiers
--   3. Invalid product prices
--   4. Invalid order statuses
--   5. Invalid quantities
--   6. Invalid order-item prices
--   7. Referential integrity
--
-- Results are stored in:
--
--     RAW.DATA_QUALITY_RESULTS
--
-- Python will later read this table and decide whether the
-- pipeline should continue.
--
-- Execution order:
--
--     01_database_setup.sql
--             ↓
--     02_raw_tables.sql
--             ↓
--     03_load_data.sql
--             ↓
--     04_data_quality.sql
--             ↓
--     05_analytics_tables.sql
--
-- ============================================================


-- ============================================================
-- STEP 1: SELECT DATABASE, SCHEMA AND WAREHOUSE
-- ============================================================

USE DATABASE ECOMMERCE_DB;

USE SCHEMA RAW;

USE WAREHOUSE ECOMMERCE_WH;


-- ============================================================
-- STEP 2: CREATE DATA QUALITY RESULTS TABLE
-- ============================================================
--
-- This table stores the result of every validation check.
--
-- Example:
--
-- check_name                 failed_count    status
-- -------------------------------------------------
-- CUSTOMERS_NULL_ID          0              PASS
-- PRODUCTS_INVALID_PRICE     0              PASS
-- ORDERS_DUPLICATE_ID        0              PASS
--
-- failed_count:
--
--     Number of records that violated the rule.
--
-- status:
--
--     PASS → No invalid records
--     FAIL → One or more invalid records
--
-- Python will use this table later to determine whether the
-- pipeline can continue.
-- ============================================================

CREATE TABLE IF NOT EXISTS DATA_QUALITY_RESULTS (
    run_time TIMESTAMP_NTZ,
    check_name VARCHAR,
    failed_count INTEGER,
    status VARCHAR
);


-- ============================================================
-- STEP 3: CLEAR RESULTS FROM PREVIOUS RUN
-- ============================================================
--
-- We want DATA_QUALITY_RESULTS to represent the CURRENT
-- pipeline execution.
--
-- Therefore, before running the checks, remove results from
-- the previous execution.
--
-- This allows Python to query the table after this script and
-- receive only the results for the current run.
-- ============================================================

TRUNCATE TABLE DATA_QUALITY_RESULTS;


-- ============================================================
-- CUSTOMER DATA QUALITY CHECKS
-- ============================================================


-- ============================================================
-- CHECK 1: NULL CUSTOMER IDs
-- ============================================================
--
-- Every customer should have a customer_id.
--
-- A NULL customer_id means we cannot reliably identify the
-- customer.
--
-- Expected result:
--
--     failed_count = 0
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'CUSTOMERS_NULL_ID',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM RAW_CUSTOMERS
WHERE customer_id IS NULL;


-- ============================================================
-- CHECK 2: DUPLICATE CUSTOMER IDs
-- ============================================================
--
-- customer_id should logically identify one customer.
--
-- We group by customer_id and look for IDs appearing more
-- than once.
--
-- Expected result:
--
--     failed_count = 0
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'CUSTOMERS_DUPLICATE_ID',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM (
    SELECT customer_id
    FROM RAW_CUSTOMERS
    GROUP BY customer_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- PRODUCT DATA QUALITY CHECKS
-- ============================================================


-- ============================================================
-- CHECK 3: NULL PRODUCT IDs
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'PRODUCTS_NULL_ID',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM RAW_PRODUCTS
WHERE product_id IS NULL;


-- ============================================================
-- CHECK 4: INVALID PRODUCT PRICES
-- ============================================================
--
-- A product price should be greater than zero.
--
-- Invalid examples:
--
--     NULL
--     0
--     -100
--
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'PRODUCTS_INVALID_PRICE',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM RAW_PRODUCTS
WHERE unit_price IS NULL
   OR unit_price <= 0;


-- ============================================================
-- CHECK 5: DUPLICATE PRODUCT IDs
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'PRODUCTS_DUPLICATE_ID',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM (
    SELECT product_id
    FROM RAW_PRODUCTS
    GROUP BY product_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- ORDER DATA QUALITY CHECKS
-- ============================================================


-- ============================================================
-- CHECK 6: NULL ORDER IDs
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'ORDERS_NULL_ID',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM RAW_ORDERS
WHERE order_id IS NULL;


-- ============================================================
-- CHECK 7: DUPLICATE ORDER IDs
-- ============================================================
--
-- Each order should appear only once in RAW_ORDERS.
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'ORDERS_DUPLICATE_ID',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM (
    SELECT order_id
    FROM RAW_ORDERS
    GROUP BY order_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- CHECK 8: INVALID ORDER STATUS
-- ============================================================
--
-- Our dataset uses these statuses:
--
--     COMPLETED
--     PENDING
--     CANCELLED
--
-- Anything outside this list is considered invalid.
--
-- TRIM removes unnecessary spaces.
-- UPPER makes the comparison case-insensitive.
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'ORDERS_INVALID_STATUS',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM RAW_ORDERS
WHERE status IS NULL
   OR UPPER(TRIM(status))
      NOT IN ('COMPLETED', 'PENDING', 'CANCELLED');


-- ============================================================
-- CHECK 9: ORPHAN ORDERS
-- ============================================================
--
-- Referential integrity rule:
--
-- Every customer_id in RAW_ORDERS should exist in
-- RAW_CUSTOMERS.
--
-- Example of a bad record:
--
-- RAW_ORDERS:
--
-- order_id = 5001
-- customer_id = 9999
--
-- but customer 9999 does not exist.
--
-- Such an order is called an ORPHAN record.
--
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'ORDERS_ORPHAN_CUSTOMER',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM RAW_ORDERS o
LEFT JOIN RAW_CUSTOMERS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- ============================================================
-- ORDER ITEM DATA QUALITY CHECKS
-- ============================================================


-- ============================================================
-- CHECK 10: INVALID ORDER ITEM QUANTITY
-- ============================================================
--
-- Quantity should always be greater than zero.
--
-- Invalid:
--
--     NULL
--     0
--     negative value
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'ORDER_ITEMS_INVALID_QUANTITY',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM RAW_ORDER_ITEMS
WHERE quantity IS NULL
   OR quantity <= 0;


-- ============================================================
-- CHECK 11: INVALID ORDER ITEM PRICE
-- ============================================================
--
-- Each order item should have a valid positive unit price.
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'ORDER_ITEMS_INVALID_PRICE',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM RAW_ORDER_ITEMS
WHERE unit_price IS NULL
   OR unit_price <= 0;


-- ============================================================
-- CHECK 12: ORPHAN ORDER ITEMS -> PRODUCTS
-- ============================================================
--
-- Every product_id in RAW_ORDER_ITEMS should exist in
-- RAW_PRODUCTS.
--
-- Otherwise the order item references a product that does not
-- exist.
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'ORDER_ITEMS_ORPHAN_PRODUCT',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM RAW_ORDER_ITEMS oi
LEFT JOIN RAW_PRODUCTS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- ============================================================
-- CHECK 13: ORPHAN ORDER ITEMS -> ORDERS
-- ============================================================
--
-- Every order_id in RAW_ORDER_ITEMS should exist in
-- RAW_ORDERS.
--
-- Otherwise an order item belongs to an order that does not
-- exist.
-- ============================================================

INSERT INTO DATA_QUALITY_RESULTS
SELECT
    CURRENT_TIMESTAMP(),
    'ORDER_ITEMS_ORPHAN_ORDER',
    COUNT(*),
    IFF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM RAW_ORDER_ITEMS oi
LEFT JOIN RAW_ORDERS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- STEP 14: RETURN ALL DATA QUALITY RESULTS
-- ============================================================
--
-- This is the final result of the script.
--
-- Python will eventually execute this SQL script and retrieve
-- this result set.
--
-- If every row has:
--
--     status = PASS
--
-- then the pipeline can continue.
--
-- If ANY row has:
--
--     status = FAIL
--
-- Python will stop the pipeline and report the problem.
-- ============================================================

SELECT
    check_name,
    failed_count,
    status
FROM DATA_QUALITY_RESULTS
ORDER BY check_name;


-- ============================================================
-- STEP 15: OVERALL PIPELINE QUALITY STATUS
-- ============================================================
--
-- This query gives us one simple answer:
--
--     PASS → all checks passed
--     FAIL → at least one check failed
--
-- Python will eventually use this query to decide whether
-- to continue to the ANALYTICS layer.
-- ============================================================

SELECT
    IFF(
        COUNT_IF(status = 'FAIL') = 0,
        'PASS',
        'FAIL'
    ) AS overall_quality_status
FROM DATA_QUALITY_RESULTS;


-- ============================================================
-- DATA QUALITY CHECKS COMPLETE
-- ============================================================
--
-- Pipeline flow so far:
--
--     CSV files
--         ↓
--     Snowflake Stage
--         ↓
--     RAW tables
--         ↓
--     Data Quality Checks
--         ↓
--     DATA_QUALITY_RESULTS
--
-- If everything passes, we can safely proceed to:
--
--     05_analytics_tables.sql
--
-- ============================================================