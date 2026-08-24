-- ============================================================
-- E-COMMERCE SNOWFLAKE ETL PIPELINE
-- File: 04_data_quality.sql
--
-- Purpose:
-- This script performs data quality checks on the RAW layer.
--
-- The RAW layer contains data loaded directly from the source
-- CSV files.
--
-- Before creating the ANALYTICS layer, we need to verify that
-- the RAW data is valid, complete, and consistent.
--
-- ============================================================
--
-- RAW TABLES:
--
--     RAW_CUSTOMERS
--     RAW_PRODUCTS
--     RAW_ORDERS
--     RAW_ORDER_ITEMS
--
-- ============================================================
--
-- DATA QUALITY CHECKS:
--
--     1. Row counts
--     2. NULL checks
--     3. Duplicate primary keys
--     4. Referential integrity
--     5. Numeric value validation
--     6. Order status validation
--     7. Invalid order dates
--     8. Order item price consistency
--     9. Email format validation
--
-- ============================================================
--
-- IMPORTANT:
--
-- This script only performs SELECT queries.
--
-- It does NOT modify or delete any data from the RAW layer.
--
-- ============================================================


-- ============================================================
-- STEP 1: SELECT DATABASE
-- ============================================================

USE DATABASE ECOMMERCE_DB;


-- ============================================================
-- STEP 2: SELECT SCHEMA
-- ============================================================

USE SCHEMA RAW;


-- ============================================================
-- STEP 3: SELECT WAREHOUSE
-- ============================================================

USE WAREHOUSE ECOMMERCE_WH;


-- ============================================================
-- CHECK 1: ROW COUNTS
-- ============================================================
--
-- Purpose:
-- Verify that records exist in all RAW tables.
--
-- Current expected dataset size:
--
--     RAW_CUSTOMERS       → 200
--     RAW_PRODUCTS        → 100
--     RAW_ORDERS          → 1000
--     RAW_ORDER_ITEMS     → 3004
--
-- ============================================================

SELECT
    'RAW_CUSTOMERS' AS table_name,
    COUNT(*) AS row_count
FROM ECOMMERCE_DB.RAW.RAW_CUSTOMERS

UNION ALL

SELECT
    'RAW_PRODUCTS' AS table_name,
    COUNT(*) AS row_count
FROM ECOMMERCE_DB.RAW.RAW_PRODUCTS

UNION ALL

SELECT
    'RAW_ORDERS' AS table_name,
    COUNT(*) AS row_count
FROM ECOMMERCE_DB.RAW.RAW_ORDERS

UNION ALL

SELECT
    'RAW_ORDER_ITEMS' AS table_name,
    COUNT(*) AS row_count
FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS;


-- ============================================================
-- CHECK 2: NULL VALUES IN CUSTOMERS
-- ============================================================
--
-- Purpose:
-- Identify missing values in important customer columns.
--
-- CUSTOMER_ID should always exist because it identifies the
-- customer.
--
-- ============================================================

SELECT
    'RAW_CUSTOMERS' AS table_name,

    COUNT_IF(CUSTOMER_ID IS NULL) AS null_customer_id,

    COUNT_IF(CUSTOMER_NAME IS NULL) AS null_customer_name,

    COUNT_IF(EMAIL IS NULL) AS null_email,

    COUNT_IF(CITY IS NULL) AS null_city,

    COUNT_IF(COUNTRY IS NULL) AS null_country

FROM ECOMMERCE_DB.RAW.RAW_CUSTOMERS;


-- ============================================================
-- CHECK 3: NULL VALUES IN PRODUCTS
-- ============================================================
--
-- Purpose:
-- Identify missing values in product records.
--
-- ============================================================

SELECT
    'RAW_PRODUCTS' AS table_name,

    COUNT_IF(PRODUCT_ID IS NULL) AS null_product_id,

    COUNT_IF(PRODUCT_NAME IS NULL) AS null_product_name,

    COUNT_IF(CATEGORY IS NULL) AS null_category,

    COUNT_IF(UNIT_PRICE IS NULL) AS null_unit_price

FROM ECOMMERCE_DB.RAW.RAW_PRODUCTS;


-- ============================================================
-- CHECK 4: NULL VALUES IN ORDERS
-- ============================================================
--
-- Purpose:
-- Identify missing values in order records.
--
-- ============================================================

SELECT
    'RAW_ORDERS' AS table_name,

    COUNT_IF(ORDER_ID IS NULL) AS null_order_id,

    COUNT_IF(CUSTOMER_ID IS NULL) AS null_customer_id,

    COUNT_IF(ORDER_DATE IS NULL) AS null_order_date,

    COUNT_IF(STATUS IS NULL) AS null_status

FROM ECOMMERCE_DB.RAW.RAW_ORDERS;


-- ============================================================
-- CHECK 5: NULL VALUES IN ORDER ITEMS
-- ============================================================
--
-- Purpose:
-- Identify missing values in order item records.
--
-- Every order item should contain:
--
--     ORDER_ID
--     PRODUCT_ID
--     QUANTITY
--     UNIT_PRICE
--
-- ============================================================

SELECT
    'RAW_ORDER_ITEMS' AS table_name,

    COUNT_IF(ORDER_ID IS NULL) AS null_order_id,

    COUNT_IF(PRODUCT_ID IS NULL) AS null_product_id,

    COUNT_IF(QUANTITY IS NULL) AS null_quantity,

    COUNT_IF(UNIT_PRICE IS NULL) AS null_unit_price

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS;


-- ============================================================
-- CHECK 6: DUPLICATE CUSTOMER IDs
-- ============================================================
--
-- CUSTOMER_ID should uniquely identify a customer.
--
-- Expected result:
--
--     No rows
--
-- ============================================================

SELECT
    CUSTOMER_ID,
    COUNT(*) AS duplicate_count

FROM ECOMMERCE_DB.RAW.RAW_CUSTOMERS

GROUP BY CUSTOMER_ID

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;


-- ============================================================
-- CHECK 7: DUPLICATE PRODUCT IDs
-- ============================================================
--
-- PRODUCT_ID should uniquely identify a product.
--
-- Expected result:
--
--     No rows
--
-- ============================================================

SELECT
    PRODUCT_ID,
    COUNT(*) AS duplicate_count

FROM ECOMMERCE_DB.RAW.RAW_PRODUCTS

GROUP BY PRODUCT_ID

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;


-- ============================================================
-- CHECK 8: DUPLICATE ORDER IDs
-- ============================================================
--
-- ORDER_ID should uniquely identify an order.
--
-- Expected result:
--
--     No rows
--
-- ============================================================

SELECT
    ORDER_ID,
    COUNT(*) AS duplicate_count

FROM ECOMMERCE_DB.RAW.RAW_ORDERS

GROUP BY ORDER_ID

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;


-- ============================================================
-- CHECK 9: ORDERS WITH NON-EXISTENT CUSTOMERS
-- ============================================================
--
-- This checks referential integrity between:
--
--     RAW_ORDERS
--          |
--          | CUSTOMER_ID
--          v
--     RAW_CUSTOMERS
--
-- Every order should belong to an existing customer.
--
-- Expected result:
--
--     No rows
--
-- ============================================================

SELECT
    O.ORDER_ID,
    O.CUSTOMER_ID

FROM ECOMMERCE_DB.RAW.RAW_ORDERS AS O

LEFT JOIN ECOMMERCE_DB.RAW.RAW_CUSTOMERS AS C
    ON O.CUSTOMER_ID = C.CUSTOMER_ID

WHERE C.CUSTOMER_ID IS NULL;


-- ============================================================
-- CHECK 10: ORDER ITEMS WITH NON-EXISTENT ORDERS
-- ============================================================
--
-- Every order item should belong to an existing order.
--
-- Relationship:
--
--     RAW_ORDER_ITEMS.ORDER_ID
--                |
--                v
--          RAW_ORDERS.ORDER_ID
--
-- Expected result:
--
--     No rows
--
-- ============================================================

SELECT
    OI.ORDER_ID,
    OI.PRODUCT_ID

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS AS OI

LEFT JOIN ECOMMERCE_DB.RAW.RAW_ORDERS AS O
    ON OI.ORDER_ID = O.ORDER_ID

WHERE O.ORDER_ID IS NULL;


-- ============================================================
-- CHECK 11: ORDER ITEMS WITH NON-EXISTENT PRODUCTS
-- ============================================================
--
-- Every order item should reference an existing product.
--
-- Relationship:
--
--     RAW_ORDER_ITEMS.PRODUCT_ID
--                |
--                v
--          RAW_PRODUCTS.PRODUCT_ID
--
-- Expected result:
--
--     No rows
--
-- ============================================================

SELECT
    OI.ORDER_ID,
    OI.PRODUCT_ID

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS AS OI

LEFT JOIN ECOMMERCE_DB.RAW.RAW_PRODUCTS AS P
    ON OI.PRODUCT_ID = P.PRODUCT_ID

WHERE P.PRODUCT_ID IS NULL;


-- ============================================================
-- CHECK 12: INVALID PRODUCT PRICES
-- ============================================================
--
-- Product prices should not be negative.
--
-- A price of zero is allowed by this check.
--
-- Expected result:
--
--     No rows
--
-- ============================================================

SELECT
    PRODUCT_ID,
    PRODUCT_NAME,
    UNIT_PRICE

FROM ECOMMERCE_DB.RAW.RAW_PRODUCTS

WHERE UNIT_PRICE < 0;


-- ============================================================
-- CHECK 13: INVALID ORDER ITEM PRICES
-- ============================================================
--
-- Order item prices should not be negative.
--
-- Expected result:
--
--     No rows
--
-- ============================================================

SELECT
    ORDER_ID,
    PRODUCT_ID,
    UNIT_PRICE

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS

WHERE UNIT_PRICE < 0;


-- ============================================================
-- CHECK 14: INVALID ORDER ITEM QUANTITIES
-- ============================================================
--
-- Quantity represents how many units of a product were
-- purchased.
--
-- Quantity should be greater than zero.
--
-- Therefore we check:
--
--     QUANTITY <= 0
--
-- Expected result:
--
--     No rows
--
-- ============================================================

SELECT
    ORDER_ID,
    PRODUCT_ID,
    QUANTITY

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS

WHERE QUANTITY <= 0;


-- ============================================================
-- CHECK 15: INVALID ORDER STATUSES
-- ============================================================
--
-- Our generated e-commerce dataset uses:
--
--     COMPLETED
--     PENDING
--     CANCELLED
--
-- This query identifies unexpected status values.
--
-- Expected result:
--
--     No rows
--
-- ============================================================

SELECT
    ORDER_ID,
    STATUS

FROM ECOMMERCE_DB.RAW.RAW_ORDERS

WHERE UPPER(TRIM(STATUS)) NOT IN (
    'COMPLETED',
    'PENDING',
    'CANCELLED'
);


-- ============================================================
-- CHECK 16: FUTURE ORDER DATES
-- ============================================================
--
-- An order should not have a date in the future.
--
-- Expected result:
--
--     No rows
--
-- ============================================================

SELECT
    ORDER_ID,
    ORDER_DATE

FROM ECOMMERCE_DB.RAW.RAW_ORDERS

WHERE ORDER_DATE > CURRENT_DATE();


-- ============================================================
-- CHECK 17: ORDER ITEM PRICE CONSISTENCY
-- ============================================================
--
-- This is an INFORMATIONAL check.
--
-- The order item stores the price paid at the time of the
-- transaction.
--
-- The product table stores the current product price.
--
-- These values can legitimately be different if a product's
-- price changed after an order was placed.
--
-- Therefore, different prices do NOT automatically mean that
-- the data is invalid.
--
-- ============================================================

SELECT
    OI.ORDER_ID,
    OI.PRODUCT_ID,

    OI.UNIT_PRICE AS ORDER_ITEM_PRICE,

    P.UNIT_PRICE AS CURRENT_PRODUCT_PRICE

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS AS OI

INNER JOIN ECOMMERCE_DB.RAW.RAW_PRODUCTS AS P
    ON OI.PRODUCT_ID = P.PRODUCT_ID

WHERE OI.UNIT_PRICE <> P.UNIT_PRICE;


-- ============================================================
-- CHECK 18: EMAIL FORMAT CHECK
-- ============================================================
--
-- This is a basic email validation.
--
-- We check whether the email contains:
--
--     @
--     .
--
-- This is intentionally a simple validation rather than a
-- complete email parser.
--
-- Expected result:
--
--     No rows
--
-- ============================================================

SELECT
    CUSTOMER_ID,
    EMAIL

FROM ECOMMERCE_DB.RAW.RAW_CUSTOMERS

WHERE EMAIL IS NOT NULL

AND (
    EMAIL NOT LIKE '%@%'
    OR EMAIL NOT LIKE '%.%'
);


-- ============================================================
-- CHECK 19: DATA QUALITY SUMMARY
-- ============================================================
--
-- This is the main summary used by the pipeline.
--
-- Each check returns:
--
--     CHECK_NAME
--     ISSUE_COUNT
--     STATUS
--
-- PASS means:
--
--     issue_count = 0
--
-- FAIL means:
--
--     one or more problematic records were found.
--
-- ============================================================


-- ------------------------------------------------------------
-- NULL CUSTOMER IDs
-- ------------------------------------------------------------

SELECT
    'NULL CUSTOMER IDs' AS check_name,

    COUNT_IF(CUSTOMER_ID IS NULL) AS issue_count,

    CASE
        WHEN COUNT_IF(CUSTOMER_ID IS NULL) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM ECOMMERCE_DB.RAW.RAW_CUSTOMERS


UNION ALL


-- ------------------------------------------------------------
-- NULL PRODUCT IDs
-- ------------------------------------------------------------

SELECT
    'NULL PRODUCT IDs' AS check_name,

    COUNT_IF(PRODUCT_ID IS NULL) AS issue_count,

    CASE
        WHEN COUNT_IF(PRODUCT_ID IS NULL) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM ECOMMERCE_DB.RAW.RAW_PRODUCTS


UNION ALL


-- ------------------------------------------------------------
-- NULL ORDER IDs
-- ------------------------------------------------------------

SELECT
    'NULL ORDER IDs' AS check_name,

    COUNT_IF(ORDER_ID IS NULL) AS issue_count,

    CASE
        WHEN COUNT_IF(ORDER_ID IS NULL) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM ECOMMERCE_DB.RAW.RAW_ORDERS


UNION ALL


-- ------------------------------------------------------------
-- NULL ORDER ITEM IDs
-- ------------------------------------------------------------

SELECT
    'NULL ORDER ITEM IDs' AS check_name,

    COUNT_IF(ORDER_ID IS NULL) AS issue_count,

    CASE
        WHEN COUNT_IF(ORDER_ID IS NULL) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS


UNION ALL


-- ------------------------------------------------------------
-- DUPLICATE CUSTOMER IDs
-- ------------------------------------------------------------

SELECT
    'DUPLICATE CUSTOMER IDs' AS check_name,

    COUNT(*) AS issue_count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM (
    SELECT
        CUSTOMER_ID

    FROM ECOMMERCE_DB.RAW.RAW_CUSTOMERS

    GROUP BY CUSTOMER_ID

    HAVING COUNT(*) > 1
)


UNION ALL


-- ------------------------------------------------------------
-- DUPLICATE PRODUCT IDs
-- ------------------------------------------------------------

SELECT
    'DUPLICATE PRODUCT IDs' AS check_name,

    COUNT(*) AS issue_count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM (
    SELECT
        PRODUCT_ID

    FROM ECOMMERCE_DB.RAW.RAW_PRODUCTS

    GROUP BY PRODUCT_ID

    HAVING COUNT(*) > 1
)


UNION ALL


-- ------------------------------------------------------------
-- DUPLICATE ORDER IDs
-- ------------------------------------------------------------

SELECT
    'DUPLICATE ORDER IDs' AS check_name,

    COUNT(*) AS issue_count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM (
    SELECT
        ORDER_ID

    FROM ECOMMERCE_DB.RAW.RAW_ORDERS

    GROUP BY ORDER_ID

    HAVING COUNT(*) > 1
)


UNION ALL


-- ------------------------------------------------------------
-- ORDERS WITH INVALID CUSTOMERS
-- ------------------------------------------------------------

SELECT
    'ORDERS WITH INVALID CUSTOMERS' AS check_name,

    COUNT(*) AS issue_count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM ECOMMERCE_DB.RAW.RAW_ORDERS AS O

LEFT JOIN ECOMMERCE_DB.RAW.RAW_CUSTOMERS AS C
    ON O.CUSTOMER_ID = C.CUSTOMER_ID

WHERE C.CUSTOMER_ID IS NULL


UNION ALL


-- ------------------------------------------------------------
-- ORDER ITEMS WITH INVALID ORDERS
-- ------------------------------------------------------------

SELECT
    'ORDER ITEMS WITH INVALID ORDERS' AS check_name,

    COUNT(*) AS issue_count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS AS OI

LEFT JOIN ECOMMERCE_DB.RAW.RAW_ORDERS AS O
    ON OI.ORDER_ID = O.ORDER_ID

WHERE O.ORDER_ID IS NULL


UNION ALL


-- ------------------------------------------------------------
-- ORDER ITEMS WITH INVALID PRODUCTS
-- ------------------------------------------------------------

SELECT
    'ORDER ITEMS WITH INVALID PRODUCTS' AS check_name,

    COUNT(*) AS issue_count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS AS OI

LEFT JOIN ECOMMERCE_DB.RAW.RAW_PRODUCTS AS P
    ON OI.PRODUCT_ID = P.PRODUCT_ID

WHERE P.PRODUCT_ID IS NULL


UNION ALL


-- ------------------------------------------------------------
-- NEGATIVE PRODUCT PRICES
-- ------------------------------------------------------------

SELECT
    'NEGATIVE PRODUCT PRICES' AS check_name,

    COUNT(*) AS issue_count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM ECOMMERCE_DB.RAW.RAW_PRODUCTS

WHERE UNIT_PRICE < 0


UNION ALL


-- ------------------------------------------------------------
-- NEGATIVE ORDER ITEM PRICES
-- ------------------------------------------------------------

SELECT
    'NEGATIVE ORDER ITEM PRICES' AS check_name,

    COUNT(*) AS issue_count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS

WHERE UNIT_PRICE < 0


UNION ALL


-- ------------------------------------------------------------
-- INVALID ORDER ITEM QUANTITIES
-- ------------------------------------------------------------

SELECT
    'INVALID ORDER ITEM QUANTITIES' AS check_name,

    COUNT(*) AS issue_count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS

WHERE QUANTITY <= 0


UNION ALL


-- ------------------------------------------------------------
-- INVALID ORDER STATUSES
-- ------------------------------------------------------------

SELECT
    'INVALID ORDER STATUSES' AS check_name,

    COUNT(*) AS issue_count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM ECOMMERCE_DB.RAW.RAW_ORDERS

WHERE UPPER(TRIM(STATUS)) NOT IN (
    'COMPLETED',
    'PENDING',
    'CANCELLED'
)


UNION ALL


-- ------------------------------------------------------------
-- FUTURE ORDER DATES
-- ------------------------------------------------------------
--
-- IMPORTANT:
--
-- We use COUNT_IF() here instead of referring directly to
-- ORDER_DATE inside the CASE expression.
--
-- This avoids the Snowflake error:
--
--     "[RAW_ORDERS.ORDER_DATE] is not a valid group by
--      expression"
--
-- ============================================================

SELECT
    'FUTURE ORDER DATES' AS check_name,

    COUNT_IF(ORDER_DATE > CURRENT_DATE()) AS issue_count,

    CASE
        WHEN COUNT_IF(ORDER_DATE > CURRENT_DATE()) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status

FROM ECOMMERCE_DB.RAW.RAW_ORDERS;


-- ============================================================
-- END OF 04_DATA_QUALITY.SQL
-- ============================================================
--
-- If all important checks return:
--
--     issue_count = 0
--     status      = PASS
--
-- then the RAW layer has passed our basic data quality
-- validation.
--
-- The next stage is:
--
--     05_analytics_tables.sql
--
-- This will create:
--
--     ANALYTICS
--     ├── DIM_CUSTOMERS
--     ├── DIM_PRODUCTS
--     ├── FACT_ORDERS
--     └── FACT_ORDER_ITEMS
--
-- ============================================================