-- ============================================================
-- E-COMMERCE SNOWFLAKE ETL PIPELINE
-- File: 05_analytics_tables.sql
--
-- Purpose:
-- This script transforms validated RAW data into the
-- ANALYTICS layer.
--
-- Our analytics model contains:
--
--     DIM_CUSTOMERS
--     DIM_PRODUCTS
--     FACT_ORDERS
--     FACT_ORDER_ITEMS
--
-- This is a simple star-schema style design.
--
--
-- Data flow:
--
--     RAW_CUSTOMERS
--          ↓
--     DIM_CUSTOMERS
--
--     RAW_PRODUCTS
--          ↓
--     DIM_PRODUCTS
--
--     RAW_ORDERS
--          ↓
--     FACT_ORDERS
--
--     RAW_ORDER_ITEMS
--          ↓
--     FACT_ORDER_ITEMS
--
--
-- IMPORTANT:
-- This script is executed ONLY after the data quality checks
-- have passed.
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
--
-- We explicitly select the required Snowflake objects so
-- the script behaves predictably when executed through Python.
-- ============================================================

USE DATABASE ECOMMERCE_DB;

USE SCHEMA ANALYTICS;

USE WAREHOUSE ECOMMERCE_WH;


-- ============================================================
-- IMPORTANT DESIGN DECISION: FULL REFRESH
-- ============================================================
--
-- For this project we are using a FULL REFRESH strategy.
--
-- That means every successful pipeline run rebuilds the
-- analytics tables from the current RAW data.
--
-- Example:
--
--     RAW_CUSTOMERS
--          ↓
--     CREATE OR REPLACE TABLE
--          ↓
--     DIM_CUSTOMERS
--
-- Why are we using full refresh?
--
-- Our dataset is small and this keeps the pipeline simple
-- and easy to understand.
--
-- In a large production system, we could use:
--
--     - MERGE
--     - Incremental loading
--     - Streams
--     - Tasks
--     - CDC
--
-- But those are unnecessary for this project.
--
-- ============================================================


-- ============================================================
-- STEP 2: CREATE DIM_CUSTOMERS
-- ============================================================
--
-- DIM_CUSTOMERS is a DIMENSION table.
--
-- Grain:
--
--     One row = one customer
--
-- Source:
--
--     RAW.RAW_CUSTOMERS
--
-- We perform small transformations here:
--
--     TRIM(customer_name)
--     LOWER(email)
--     TRIM(city)
--     TRIM(country)
--
-- We also remove records with NULL customer IDs.
--
-- Why?
--
-- customer_id is the logical identifier for a customer.
-- ============================================================

CREATE OR REPLACE TABLE DIM_CUSTOMERS AS

SELECT
    customer_id,

    -- Remove unnecessary spaces from the customer name.
    TRIM(customer_name) AS customer_name,

    -- Standardize email addresses to lowercase.
    LOWER(TRIM(email)) AS email,

    -- Remove unnecessary spaces from city.
    TRIM(city) AS city,

    -- Remove unnecessary spaces from country.
    TRIM(country) AS country

FROM ECOMMERCE_DB.RAW.RAW_CUSTOMERS

WHERE customer_id IS NOT NULL;


-- ============================================================
-- DIM_CUSTOMERS CREATED
-- ============================================================
--
-- Result:
--
-- DIM_CUSTOMERS
-- ---------------------------------------------
-- customer_id
-- customer_name
-- email
-- city
-- country
--
-- Grain:
--
--     One row per customer
--
-- ============================================================


-- ============================================================
-- STEP 3: CREATE DIM_PRODUCTS
-- ============================================================
--
-- DIM_PRODUCTS is another DIMENSION table.
--
-- Grain:
--
--     One row = one product
--
-- Source:
--
--     RAW.RAW_PRODUCTS
--
-- Transformations:
--
--     TRIM(product_name)
--     TRIM(category)
--
-- We only keep products with:
--
--     product_id IS NOT NULL
--     unit_price > 0
--
-- Data quality checks should already have caught invalid
-- records, but these conditions provide an additional safety
-- layer.
-- ============================================================

CREATE OR REPLACE TABLE DIM_PRODUCTS AS

SELECT
    product_id,

    -- Remove unnecessary spaces from product name.
    TRIM(product_name) AS product_name,

    -- Standardize category formatting.
    TRIM(category) AS category,

    -- Keep the validated product price.
    unit_price

FROM ECOMMERCE_DB.RAW.RAW_PRODUCTS

WHERE product_id IS NOT NULL
  AND unit_price > 0;


-- ============================================================
-- DIM_PRODUCTS CREATED
-- ============================================================
--
-- Result:
--
-- DIM_PRODUCTS
-- ---------------------------------------------
-- product_id
-- product_name
-- category
-- unit_price
--
-- Grain:
--
--     One row per product
--
-- ============================================================


-- ============================================================
-- STEP 4: CREATE FACT_ORDERS
-- ============================================================
--
-- FACT_ORDERS is a FACT table.
--
-- Grain:
--
--     One row = one order
--
-- Source:
--
--     RAW.RAW_ORDERS
--
-- Transformations:
--
--     UPPER(status)
--     TRIM(status)
--
-- We keep:
--
--     order_id
--     customer_id
--     order_date
--     status
--
-- Notice that we do NOT join products here.
--
-- Why?
--
-- FACT_ORDERS represents the ORDER level.
--
-- Product information belongs at the ORDER ITEM level,
-- which is handled by FACT_ORDER_ITEMS.
--
-- This preserves the correct grain.
-- ============================================================

CREATE OR REPLACE TABLE FACT_ORDERS AS

SELECT
    order_id,

    -- Customer associated with the order.
    customer_id,

    -- Date on which the order was placed.
    order_date,

    -- Standardize status values.
    UPPER(TRIM(status)) AS status

FROM ECOMMERCE_DB.RAW.RAW_ORDERS

WHERE order_id IS NOT NULL
  AND customer_id IS NOT NULL;


-- ============================================================
-- FACT_ORDERS CREATED
-- ============================================================
--
-- Result:
--
-- FACT_ORDERS
-- ---------------------------------------------
-- order_id
-- customer_id
-- order_date
-- status
--
-- Grain:
--
--     One row per order
--
-- ============================================================


-- ============================================================
-- STEP 5: CREATE FACT_ORDER_ITEMS
-- ============================================================
--
-- FACT_ORDER_ITEMS is our second FACT table.
--
-- Grain:
--
--     One row = one product line inside an order
--
-- Source:
--
--     RAW.RAW_ORDER_ITEMS
--
-- We keep:
--
--     order_id
--     product_id
--     quantity
--     unit_price
--
-- And we create:
--
--     item_total
--
-- Formula:
--
--     item_total = quantity × unit_price
--
-- Example:
--
-- quantity   = 3
-- unit_price = 500
--
-- item_total = 3 × 500
--            = 1500
--
-- This calculated metric is useful for revenue analysis.
-- ============================================================

CREATE OR REPLACE TABLE FACT_ORDER_ITEMS AS

SELECT
    order_id,

    -- Product associated with this order item.
    product_id,

    -- Number of units purchased.
    quantity,

    -- Price of one unit at the time of the order.
    unit_price,

    -- Total value of this individual order line.
    quantity * unit_price AS item_total

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS

WHERE order_id IS NOT NULL
  AND product_id IS NOT NULL
  AND quantity > 0
  AND unit_price > 0;


-- ============================================================
-- FACT_ORDER_ITEMS CREATED
-- ============================================================
--
-- Result:
--
-- FACT_ORDER_ITEMS
-- ---------------------------------------------
-- order_id
-- product_id
-- quantity
-- unit_price
-- item_total
--
-- Grain:
--
--     One row per product line within an order
--
-- ============================================================


-- ============================================================
-- STEP 6: VERIFY ANALYTICS TABLES
-- ============================================================
--
-- These queries allow us to confirm that the transformation
-- successfully produced records in all four analytics tables.
--
-- Python can later execute these queries or perform equivalent
-- checks after the transformation.
-- ============================================================

SELECT
    'DIM_CUSTOMERS' AS table_name,
    COUNT(*) AS row_count
FROM DIM_CUSTOMERS

UNION ALL

SELECT
    'DIM_PRODUCTS' AS table_name,
    COUNT(*) AS row_count
FROM DIM_PRODUCTS

UNION ALL

SELECT
    'FACT_ORDERS' AS table_name,
    COUNT(*) AS row_count
FROM FACT_ORDERS

UNION ALL

SELECT
    'FACT_ORDER_ITEMS' AS table_name,
    COUNT(*) AS row_count
FROM FACT_ORDER_ITEMS;


-- ============================================================
-- STEP 7: FINAL ANALYTICS MODEL
-- ============================================================
--
-- After this script executes successfully, our Snowflake
-- architecture looks like:
--
--
--                 DIM_CUSTOMERS
--                       |
--                       | customer_id
--                       |
--                       v
--                  FACT_ORDERS
--                       |
--                       | order_id
--                       |
--                       v
--                FACT_ORDER_ITEMS
--                       ^
--                       |
--                       | product_id
--                       |
--                 DIM_PRODUCTS
--
--
-- DIMENSIONS:
--
--     DIM_CUSTOMERS
--     DIM_PRODUCTS
--
-- FACTS:
--
--     FACT_ORDERS
--     FACT_ORDER_ITEMS
--
-- ============================================================


-- ============================================================
-- TRANSFORMATION COMPLETE
-- ============================================================
--
-- The pipeline has now completed:
--
--     SOURCE CSV
--          ↓
--     SNOWFLAKE STAGE
--          ↓
--     RAW TABLES
--          ↓
--     DATA QUALITY
--          ↓
--     ANALYTICS TABLES
--
-- The next file contains business analytics queries:
--
--     06_business_queries.sql
--
-- ============================================================