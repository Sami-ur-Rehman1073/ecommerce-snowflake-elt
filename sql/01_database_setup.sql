-- ============================================================
-- E-COMMERCE SNOWFLAKE ETL PIPELINE
-- File: 01_database_setup.sql
--
-- Purpose:
-- This script creates the basic Snowflake infrastructure
-- required for our e-commerce ETL pipeline.
--
-- It creates:
--   1. Compute warehouse
--   2. Database
--   3. RAW schema
--   4. ANALYTICS schema
--   5. CSV file format
--   6. Internal Snowflake stage
--
-- Execution order:
-- This file must be executed FIRST.
-- ============================================================


-- ============================================================
-- STEP 1: CREATE THE SNOWFLAKE WAREHOUSE
-- ============================================================
--
-- A warehouse provides the COMPUTE resources used by
-- Snowflake to execute SQL queries and data-loading operations.
--
-- XSMALL is enough for our small e-commerce dataset.
--
-- AUTO_SUSPEND = 60:
--   Suspend the warehouse after 60 seconds of inactivity.
--
-- AUTO_RESUME = TRUE:
--   Automatically start the warehouse when a query needs it.
--
-- IF NOT EXISTS:
--   Don't create another warehouse if it already exists.
-- ============================================================

CREATE WAREHOUSE IF NOT EXISTS ECOMMERCE_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;


-- ============================================================
-- STEP 2: SELECT THE WAREHOUSE
-- ============================================================
--
-- All SQL operations that require compute will use this
-- warehouse.
-- ============================================================

USE WAREHOUSE ECOMMERCE_WH;


-- ============================================================
-- STEP 3: CREATE THE DATABASE
-- ============================================================
--
-- The database is the top-level container for our project.
--
-- Final structure:
--
-- ECOMMERCE_DB
--     |
--     +-- RAW
--     |
--     +-- ANALYTICS
--
-- IF NOT EXISTS means that running this script again will
-- not create a duplicate database.
-- ============================================================

CREATE DATABASE IF NOT EXISTS ECOMMERCE_DB;


-- ============================================================
-- STEP 4: SELECT THE DATABASE
-- ============================================================

USE DATABASE ECOMMERCE_DB;


-- ============================================================
-- STEP 5: CREATE THE RAW SCHEMA
-- ============================================================
--
-- RAW contains data as it arrives from the source.
--
-- We do not perform major transformations here.
--
-- RAW tables:
--
-- RAW_CUSTOMERS
-- RAW_PRODUCTS
-- RAW_ORDERS
-- RAW_ORDER_ITEMS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS RAW;


-- ============================================================
-- STEP 6: CREATE THE ANALYTICS SCHEMA
-- ============================================================
--
-- ANALYTICS contains cleaned and transformed data that is
-- ready for business analysis.
--
-- Our final analytics model will contain:
--
-- DIM_CUSTOMERS
-- DIM_PRODUCTS
-- FACT_ORDERS
-- FACT_ORDER_ITEMS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS ANALYTICS;


-- ============================================================
-- STEP 7: SELECT THE RAW SCHEMA
-- ============================================================
--
-- The following file will use the RAW schema for creating
-- tables and the Snowflake stage.
-- ============================================================

USE SCHEMA RAW;


-- ============================================================
-- STEP 8: CREATE THE CSV FILE FORMAT
-- ============================================================
--
-- Snowflake needs to know how our CSV files are structured.
--
-- Our CSV files have:
--
--   - A header row
--   - Comma-separated columns
--   - Optional double quotes around values
--
-- Example:
--
-- customer_id,customer_name,email,city,country
-- 1,John Smith,john@example.com,Lahore,Pakistan
--
-- SKIP_HEADER = 1
--   Ignore the first row of the CSV file.
--
-- FIELD_OPTIONALLY_ENCLOSED_BY = '"'
--   Allow values to be surrounded by double quotes.
--
-- TRIM_SPACE = TRUE
--   Remove unnecessary spaces around values.
--
-- NULL_IF
--   Treat these values as NULL.
-- ============================================================

CREATE FILE FORMAT IF NOT EXISTS CSV_FORMAT
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    NULL_IF = ('NULL', 'null', '');


-- ============================================================
-- STEP 9: CREATE THE INTERNAL SNOWFLAKE STAGE
-- ============================================================
--
-- A stage is a storage location used to temporarily hold files
-- before loading them into Snowflake tables.
--
-- Our pipeline will eventually work like this:
--
-- Local CSV files
--       |
--       | Python uploads
--       v
-- @ECOMMERCE_STAGE
--       |
--       | COPY INTO
--       v
-- RAW tables
--
-- The Python automation that we build later will upload our
-- CSV files to this stage.
-- ============================================================

CREATE STAGE IF NOT EXISTS ECOMMERCE_STAGE
    FILE_FORMAT = CSV_FORMAT;


-- ============================================================
-- SETUP COMPLETE
-- ============================================================
--
-- At this point Snowflake contains:
--
-- ECOMMERCE_DB
--     |
--     +-- RAW
--     |
--     +-- ANALYTICS
--
-- And inside RAW we have:
--
-- ECOMMERCE_STAGE
--
-- The actual RAW tables will be created by:
--
--     02_raw_tables.sql
--
-- ============================================================