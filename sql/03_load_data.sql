-- ============================================================
-- E-COMMERCE SNOWFLAKE ETL PIPELINE
-- File: 03_load_data.sql
--
-- Purpose:
-- This script loads CSV files from the Snowflake internal
-- stage into the RAW tables.
--
-- IMPORTANT:
-- Python will upload the CSV files to the stage BEFORE this
-- script is executed.
--
-- Expected files in the stage:
--
--     @ECOMMERCE_STAGE/customers.csv
--     @ECOMMERCE_STAGE/products.csv
--     @ECOMMERCE_STAGE/orders.csv
--     @ECOMMERCE_STAGE/order_items.csv
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
--
-- ============================================================


-- ============================================================
-- STEP 1: SELECT DATABASE, SCHEMA AND WAREHOUSE
-- ============================================================
--
-- Explicitly selecting these objects makes the script
-- predictable when it is executed from Python.
-- ============================================================

USE DATABASE ECOMMERCE_DB;

USE SCHEMA RAW;

USE WAREHOUSE ECOMMERCE_WH;


-- ============================================================
-- STEP 2: CHECK THE STAGE
-- ============================================================
--
-- LIST shows the files currently available in the stage.
--
-- During development, you can use this to verify that Python
-- successfully uploaded the CSV files.
--
-- Expected files:
--
--     customers.csv
--     products.csv
--     orders.csv
--     order_items.csv
--
-- ============================================================

LIST @ECOMMERCE_STAGE;


-- ============================================================
-- STEP 3: LOAD CUSTOMERS
-- ============================================================
--
-- COPY INTO reads customers.csv from the Snowflake stage
-- and inserts the records into RAW_CUSTOMERS.
--
-- The CSV format was created in:
--
--     01_database_setup.sql
--
-- CSV_FORMAT already knows:
--
--     - The first row is a header
--     - Values are comma-separated
--     - Optional double quotes are allowed
--     - Extra spaces should be trimmed
--
-- ON_ERROR = 'ABORT_STATEMENT'
--
-- means:
--
-- If Snowflake encounters a loading error, stop the COPY
-- operation instead of silently loading bad data.
--
-- This is useful for our pipeline because we don't want
-- Python to continue as if the load succeeded when the
-- source data contains a loading problem.
-- ============================================================

COPY INTO RAW_CUSTOMERS
FROM @ECOMMERCE_STAGE/customers.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
ON_ERROR = 'ABORT_STATEMENT';


-- ============================================================
-- STEP 4: LOAD PRODUCTS
-- ============================================================
--
-- Source:
--
--     @ECOMMERCE_STAGE/products.csv
--
-- Destination:
--
--     RAW_PRODUCTS
-- ============================================================

COPY INTO RAW_PRODUCTS
FROM @ECOMMERCE_STAGE/products.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
ON_ERROR = 'ABORT_STATEMENT';


-- ============================================================
-- STEP 5: LOAD ORDERS
-- ============================================================
--
-- Source:
--
--     @ECOMMERCE_STAGE/orders.csv
--
-- Destination:
--
--     RAW_ORDERS
-- ============================================================

COPY INTO RAW_ORDERS
FROM @ECOMMERCE_STAGE/orders.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
ON_ERROR = 'ABORT_STATEMENT';


-- ============================================================
-- STEP 6: LOAD ORDER ITEMS
-- ============================================================
--
-- Source:
--
--     @ECOMMERCE_STAGE/order_items.csv
--
-- Destination:
--
--     RAW_ORDER_ITEMS
-- ============================================================

COPY INTO RAW_ORDER_ITEMS
FROM @ECOMMERCE_STAGE/order_items.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
ON_ERROR = 'ABORT_STATEMENT';


-- ============================================================
-- STEP 7: VERIFY ROW COUNTS
-- ============================================================
--
-- These queries allow us to confirm that data exists in each
-- RAW table after the COPY operations.
--
-- Expected based on our generated dataset:
--
--     CUSTOMERS     → 100 rows
--     PRODUCTS      → 50 rows
--     ORDERS        → 500 rows
--     ORDER_ITEMS   → depends on generated data
--
-- The exact number of order items can vary because the
-- dataset generator randomly creates product lines per order.
-- ============================================================

SELECT
    'RAW_CUSTOMERS' AS table_name,
    COUNT(*) AS row_count
FROM RAW_CUSTOMERS

UNION ALL

SELECT
    'RAW_PRODUCTS' AS table_name,
    COUNT(*) AS row_count
FROM RAW_PRODUCTS

UNION ALL

SELECT
    'RAW_ORDERS' AS table_name,
    COUNT(*) AS row_count
FROM RAW_ORDERS

UNION ALL

SELECT
    'RAW_ORDER_ITEMS' AS table_name,
    COUNT(*) AS row_count
FROM RAW_ORDER_ITEMS;


-- ============================================================
-- LOAD COMPLETE
-- ============================================================
--
-- At this point:
--
--                 CSV FILES
--                     │
--                     │ Python
--                     ▼
--              SNOWFLAKE STAGE
--                     │
--                     │ COPY INTO
--                     ▼
--                  RAW
--                     │
--          ┌──────────┼──────────┐
--          ▼          ▼          ▼
--      CUSTOMERS   PRODUCTS    ORDERS
--                                  │
--                                  ▼
--                             ORDER_ITEMS
--
-- The next stage is data quality validation.
--
-- Next file:
--
--     04_data_quality.sql
--
-- ============================================================