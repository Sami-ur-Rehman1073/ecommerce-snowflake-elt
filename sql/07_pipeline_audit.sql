-- ============================================================
-- E-COMMERCE SNOWFLAKE ETL PIPELINE
-- File: 07_pipeline_audit.sql
--
-- Purpose:
-- This script creates and maintains a simple audit table
-- for monitoring our ETL pipeline.
--
-- The audit table records:
--
--     - Pipeline run time
--     - Pipeline name
--     - Table name
--     - Row count
--     - Pipeline status
--
-- This allows us to answer questions such as:
--
--     How many records were loaded?
--     When did the pipeline run?
--     Did the pipeline succeed?
--     How many rows are in each table?
--
-- IMPORTANT:
-- The Python pipeline will eventually execute the INSERT
-- statements in this file after the relevant pipeline steps
-- have completed.
--
-- ============================================================


-- ============================================================
-- STEP 1: SELECT DATABASE AND SCHEMA
-- ============================================================

USE DATABASE ECOMMERCE_DB;

USE SCHEMA RAW;

USE WAREHOUSE ECOMMERCE_WH;


-- ============================================================
-- STEP 2: CREATE PIPELINE_AUDIT TABLE
-- ============================================================
--
-- This table stores one record for each audited table during
-- a pipeline execution.
--
-- Example:
--
-- pipeline_name       table_name          row_count    status
-- ----------------------------------------------------------------
-- ecommerce_etl      RAW_CUSTOMERS       100          SUCCESS
-- ecommerce_etl      RAW_PRODUCTS        50           SUCCESS
-- ecommerce_etl      RAW_ORDERS          500          SUCCESS
-- ecommerce_etl      FACT_ORDERS         500          SUCCESS
--
-- run_id:
--
-- A unique identifier for a particular pipeline execution.
--
-- run_time:
--
-- The time at which the audit record was created.
--
-- pipeline_name:
--
-- Identifies which pipeline produced the record.
--
-- table_name:
--
-- Identifies which table is being audited.
--
-- row_count:
--
-- Number of records present in the table.
--
-- status:
--
-- Indicates whether the corresponding pipeline step
-- succeeded.
-- ============================================================

CREATE TABLE IF NOT EXISTS PIPELINE_AUDIT (
    run_id VARCHAR,
    run_time TIMESTAMP_NTZ,
    pipeline_name VARCHAR,
    table_name VARCHAR,
    row_count INTEGER,
    status VARCHAR
);


-- ============================================================
-- STEP 3: CREATE AN AUDIT RUN ID
-- ============================================================
--
-- UUID_STRING() generates a unique identifier.
--
-- Example:
--
--     8f5d8e2b-7b7d-4c1a-9c4e-123456789abc
--
-- In the final Python implementation, Python will generate
-- ONE run_id for the entire pipeline execution.
--
-- For now, this SQL demonstrates how Snowflake can generate
-- a unique run identifier.
-- ============================================================

SET PIPELINE_RUN_ID = UUID_STRING();


-- ============================================================
-- STEP 4: AUDIT RAW TABLES
-- ============================================================
--
-- These records tell us how many rows exist in each RAW table.
--
-- The same run_id is used for all records so we can identify
-- which records belong to the same pipeline execution.
-- ============================================================


-- ------------------------------------------------------------
-- RAW_CUSTOMERS
-- ------------------------------------------------------------

INSERT INTO PIPELINE_AUDIT
SELECT
    $PIPELINE_RUN_ID,
    CURRENT_TIMESTAMP(),
    'ECOMMERCE_ETL',
    'RAW_CUSTOMERS',
    COUNT(*),
    'SUCCESS'
FROM RAW_CUSTOMERS;


-- ------------------------------------------------------------
-- RAW_PRODUCTS
-- ------------------------------------------------------------

INSERT INTO PIPELINE_AUDIT
SELECT
    $PIPELINE_RUN_ID,
    CURRENT_TIMESTAMP(),
    'ECOMMERCE_ETL',
    'RAW_PRODUCTS',
    COUNT(*),
    'SUCCESS'
FROM RAW_PRODUCTS;


-- ------------------------------------------------------------
-- RAW_ORDERS
-- ------------------------------------------------------------

INSERT INTO PIPELINE_AUDIT
SELECT
    $PIPELINE_RUN_ID,
    CURRENT_TIMESTAMP(),
    'ECOMMERCE_ETL',
    'RAW_ORDERS',
    COUNT(*),
    'SUCCESS'
FROM RAW_ORDERS;


-- ------------------------------------------------------------
-- RAW_ORDER_ITEMS
-- ------------------------------------------------------------

INSERT INTO PIPELINE_AUDIT
SELECT
    $PIPELINE_RUN_ID,
    CURRENT_TIMESTAMP(),
    'ECOMMERCE_ETL',
    'RAW_ORDER_ITEMS',
    COUNT(*),
    'SUCCESS'
FROM RAW_ORDER_ITEMS;


-- ============================================================
-- STEP 5: AUDIT ANALYTICS TABLES
-- ============================================================
--
-- The ANALYTICS tables are in a different schema.
--
-- We therefore use fully qualified table names:
--
--     ECOMMERCE_DB.ANALYTICS.DIM_CUSTOMERS
--     ECOMMERCE_DB.ANALYTICS.DIM_PRODUCTS
--     ECOMMERCE_DB.ANALYTICS.FACT_ORDERS
--     ECOMMERCE_DB.ANALYTICS.FACT_ORDER_ITEMS
--
-- ============================================================


-- ------------------------------------------------------------
-- DIM_CUSTOMERS
-- ------------------------------------------------------------

INSERT INTO PIPELINE_AUDIT
SELECT
    $PIPELINE_RUN_ID,
    CURRENT_TIMESTAMP(),
    'ECOMMERCE_ETL',
    'DIM_CUSTOMERS',
    COUNT(*),
    'SUCCESS'
FROM ECOMMERCE_DB.ANALYTICS.DIM_CUSTOMERS;


-- ------------------------------------------------------------
-- DIM_PRODUCTS
-- ------------------------------------------------------------

INSERT INTO PIPELINE_AUDIT
SELECT
    $PIPELINE_RUN_ID,
    CURRENT_TIMESTAMP(),
    'ECOMMERCE_ETL',
    'DIM_PRODUCTS',
    COUNT(*),
    'SUCCESS'
FROM ECOMMERCE_DB.ANALYTICS.DIM_PRODUCTS;


-- ------------------------------------------------------------
-- FACT_ORDERS
-- ------------------------------------------------------------

INSERT INTO PIPELINE_AUDIT
SELECT
    $PIPELINE_RUN_ID,
    CURRENT_TIMESTAMP(),
    'ECOMMERCE_ETL',
    'FACT_ORDERS',
    COUNT(*),
    'SUCCESS'
FROM ECOMMERCE_DB.ANALYTICS.FACT_ORDERS;


-- ------------------------------------------------------------
-- FACT_ORDER_ITEMS
-- ------------------------------------------------------------

INSERT INTO PIPELINE_AUDIT
SELECT
    $PIPELINE_RUN_ID,
    CURRENT_TIMESTAMP(),
    'ECOMMERCE_ETL',
    'FACT_ORDER_ITEMS',
    COUNT(*),
    'SUCCESS'
FROM ECOMMERCE_DB.ANALYTICS.FACT_ORDER_ITEMS;


-- ============================================================
-- STEP 6: VIEW THE CURRENT PIPELINE RUN
-- ============================================================
--
-- This shows all audit records generated by this execution.
--
-- Because we use the same run_id for every record, we can
-- easily identify all tables belonging to one pipeline run.
-- ============================================================

SELECT
    run_id,
    run_time,
    pipeline_name,
    table_name,
    row_count,
    status
FROM PIPELINE_AUDIT
WHERE run_id = $PIPELINE_RUN_ID
ORDER BY table_name;


-- ============================================================
-- STEP 7: VIEW PIPELINE HISTORY
-- ============================================================
--
-- This query displays the audit history of the pipeline.
--
-- New pipeline runs will add new records rather than replacing
-- old records.
--
-- This gives us a simple historical record of pipeline runs.
-- ============================================================

SELECT
    run_id,
    run_time,
    pipeline_name,
    table_name,
    row_count,
    status
FROM PIPELINE_AUDIT
ORDER BY run_time DESC, table_name;


-- ============================================================
-- PIPELINE AUDIT COMPLETE
-- ============================================================
--
-- Our complete project architecture is now:
--
--
--                    CSV FILES
--                        |
--                        | Python
--                        v
--                  SNOWFLAKE STAGE
--                        |
--                        v
--                  RAW TABLES
--                        |
--                        v
--                 DATA QUALITY
--                        |
--                        v
--                ANALYTICS TABLES
--                        |
--                        v
--                 BUSINESS QUERIES
--                        |
--                        v
--                  PIPELINE AUDIT
--
--
-- The audit table allows us to monitor the pipeline instead
-- of simply assuming that everything worked.
--
-- ============================================================