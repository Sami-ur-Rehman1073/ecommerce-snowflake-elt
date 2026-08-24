-- ============================================================
-- E-COMMERCE SNOWFLAKE ETL PIPELINE
-- File: 03_load_data.sql
--
-- Purpose:
-- This script loads CSV files from the Snowflake internal
-- stage into the RAW tables.
--
-- IMPORTANT:
-- Python uploads the CSV files to the stage BEFORE this
-- script is executed.
--
-- Expected files in the stage:
--
--     @ECOMMERCE_DB.RAW.ECOMMERCE_STAGE/customers.csv
--     @ECOMMERCE_DB.RAW.ECOMMERCE_STAGE/products.csv
--     @ECOMMERCE_DB.RAW.ECOMMERCE_STAGE/orders.csv
--     @ECOMMERCE_DB.RAW.ECOMMERCE_STAGE/order_items.csv
--
-- Execution order:
--
--     01_database_setup.sql
--             ↓
--     02_raw_tables.sql
--             ↓
--     Python uploads CSV files
--             ↓
--     03_load_data.sql
--             ↓
--     RAW tables populated
--             ↓
--     04_data_quality.sql
--
-- ============================================================


-- ============================================================
-- STEP 1: SELECT DATABASE
-- ============================================================
--
-- We explicitly select the database.
--
-- Although the objects below are fully qualified, setting the
-- database makes the script easier to understand when running
-- it manually in Snowflake.
-- ============================================================

USE DATABASE ECOMMERCE_DB;


-- ============================================================
-- STEP 2: SELECT RAW SCHEMA
-- ============================================================
--
-- RAW is our ingestion layer.
--
-- The RAW layer contains data loaded directly from the source
-- CSV files with minimal transformation.
-- ============================================================

USE SCHEMA RAW;


-- ============================================================
-- STEP 3: SELECT WAREHOUSE
-- ============================================================
--
-- The warehouse provides the compute resources required to
-- execute the COPY commands and validation queries.
-- ============================================================

USE WAREHOUSE ECOMMERCE_WH;


-- ============================================================
-- STEP 4: CHECK THE SNOWFLAKE STAGE
-- ============================================================
--
-- LIST displays files currently available in our internal
-- Snowflake stage.
--
-- This is primarily useful during development and debugging.
--
-- Expected files:
--
--     customers.csv
--     products.csv
--     orders.csv
--     order_items.csv
--
-- IMPORTANT:
-- The stage is fully qualified to prevent Snowflake from
-- resolving it against the wrong schema.
-- ============================================================

LIST @ECOMMERCE_DB.RAW.ECOMMERCE_STAGE;


-- ============================================================
-- STEP 5: LOAD CUSTOMERS
-- ============================================================
--
-- Source:
--     customers.csv
--
-- Destination:
--     ECOMMERCE_DB.RAW.RAW_CUSTOMERS
--
-- FILE_FORMAT:
--     ECOMMERCE_DB.RAW.CSV_FORMAT
--
-- ON_ERROR = 'ABORT_STATEMENT'
--
-- If Snowflake encounters a loading error, the COPY operation
-- stops instead of silently loading incomplete/bad data.
--
-- This is important for our ETL pipeline because Python should
-- not continue to the next stage if the RAW load fails.
-- ============================================================

COPY INTO ECOMMERCE_DB.RAW.RAW_CUSTOMERS
FROM @ECOMMERCE_DB.RAW.ECOMMERCE_STAGE/customers.csv
FILE_FORMAT = (
    FORMAT_NAME = ECOMMERCE_DB.RAW.CSV_FORMAT
)
ON_ERROR = 'ABORT_STATEMENT';


-- ============================================================
-- STEP 6: LOAD PRODUCTS
-- ============================================================
--
-- Source:
--     products.csv
--
-- Destination:
--     ECOMMERCE_DB.RAW.RAW_PRODUCTS
-- ============================================================

COPY INTO ECOMMERCE_DB.RAW.RAW_PRODUCTS
FROM @ECOMMERCE_DB.RAW.ECOMMERCE_STAGE/products.csv
FILE_FORMAT = (
    FORMAT_NAME = ECOMMERCE_DB.RAW.CSV_FORMAT
)
ON_ERROR = 'ABORT_STATEMENT';


-- ============================================================
-- STEP 7: LOAD ORDERS
-- ============================================================
--
-- Source:
--     orders.csv
--
-- Destination:
--     ECOMMERCE_DB.RAW.RAW_ORDERS
-- ============================================================

COPY INTO ECOMMERCE_DB.RAW.RAW_ORDERS
FROM @ECOMMERCE_DB.RAW.ECOMMERCE_STAGE/orders.csv
FILE_FORMAT = (
    FORMAT_NAME = ECOMMERCE_DB.RAW.CSV_FORMAT
)
ON_ERROR = 'ABORT_STATEMENT';


-- ============================================================
-- STEP 8: LOAD ORDER ITEMS
-- ============================================================
--
-- Source:
--     order_items.csv
--
-- Destination:
--     ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS
-- ============================================================

COPY INTO ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS
FROM @ECOMMERCE_DB.RAW.ECOMMERCE_STAGE/order_items.csv
FILE_FORMAT = (
    FORMAT_NAME = ECOMMERCE_DB.RAW.CSV_FORMAT
)
ON_ERROR = 'ABORT_STATEMENT';


-- ============================================================
-- STEP 9: VERIFY RAW TABLE ROW COUNTS
-- ============================================================
--
-- These queries verify that records exist in all four RAW
-- tables after the COPY operations.
--
-- Based on the dataset we generated:
--
--     CUSTOMERS     → 100 rows
--     PRODUCTS      → 50 rows
--     ORDERS        → 500 rows
--     ORDER_ITEMS   → depends on generated data
--
-- The exact ORDER_ITEMS count depends on how many product
-- lines were randomly generated for each order.
--
-- IMPORTANT:
-- These are validation queries only. They do not modify data.
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
-- STEP 10: LOAD VERIFICATION
-- ============================================================
--
-- At this point the pipeline should have successfully moved
-- data through the following stages:
--
--
--                  LOCAL CSV FILES
--                         │
--                         │
--                         │ Python PUT
--                         ▼
--              ┌──────────────────────┐
--              │  SNOWFLAKE STAGE     │
--              │                      │
--              │ ECOMMERCE_DB         │
--              │   └── RAW            │
--              │       └── STAGE      │
--              └──────────┬───────────┘
--                         │
--                         │ COPY INTO
--                         ▼
--              ┌──────────────────────┐
--              │      RAW TABLES      │
--              │                      │
--              │ RAW_CUSTOMERS        │
--              │ RAW_PRODUCTS         │
--              │ RAW_ORDERS           │
--              │ RAW_ORDER_ITEMS      │
--              └──────────┬───────────┘
--                         │
--                         ▼
--                 DATA QUALITY CHECK
--
--
-- The next stage of the pipeline is:
--
--     04_data_quality.sql
--
-- ============================================================


-- ============================================================
-- END OF 03_LOAD_DATA.SQL
-- ============================================================