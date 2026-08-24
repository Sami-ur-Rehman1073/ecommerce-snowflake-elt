-- ============================================================
-- E-COMMERCE SNOWFLAKE ETL PIPELINE
-- File: 05_analytics_tables.sql
--
-- Purpose:
-- Transform validated RAW data into the ANALYTICS layer.
--
-- RAW layer:
--
--     RAW_CUSTOMERS
--     RAW_PRODUCTS
--     RAW_ORDERS
--     RAW_ORDER_ITEMS
--
-- ANALYTICS layer:
--
--     DIM_CUSTOMERS
--     DIM_PRODUCTS
--     FACT_ORDERS
--     FACT_ORDER_ITEMS
--
-- ============================================================
--
-- DATA FLOW:
--
--                 RAW
--                  │
--                  │
--                  ▼
--          DATA QUALITY CHECKS
--                  │
--                  ▼
--              ANALYTICS
--                  │
--       ┌──────────┴──────────┐
--       │                     │
--       ▼                     ▼
-- DIM_CUSTOMERS        DIM_PRODUCTS
--       │                     │
--       └──────────┬──────────┘
--                  │
--                  ▼
--             FACT_ORDERS
--                  │
--                  ▼
--          FACT_ORDER_ITEMS
--
-- ============================================================
--
-- IMPORTANT:
--
-- This script recreates the ANALYTICS tables from the current
-- RAW data.
--
-- This approach is appropriate for our small demonstration
-- project and keeps the pipeline simple.
--
-- In a production environment, incremental loading, MERGE,
-- slowly changing dimensions, and orchestration would normally
-- be considered.
--
-- ============================================================


-- ============================================================
-- STEP 1: SELECT DATABASE
-- ============================================================

USE DATABASE ECOMMERCE_DB;


-- ============================================================
-- STEP 2: SELECT ANALYTICS SCHEMA
-- ============================================================

USE SCHEMA ANALYTICS;


-- ============================================================
-- STEP 3: SELECT WAREHOUSE
-- ============================================================

USE WAREHOUSE ECOMMERCE_WH;


-- ============================================================
-- STEP 4: CREATE ANALYTICS SCHEMA IF REQUIRED
-- ============================================================
--
-- This statement ensures that the ANALYTICS schema exists.
--
-- ============================================================

CREATE SCHEMA IF NOT EXISTS ANALYTICS;


-- ============================================================
-- STEP 5: REMOVE OLD ANALYTICS TABLES
-- ============================================================
--
-- We use CREATE OR REPLACE TABLE below, so explicit DROP
-- statements are not required.
--
-- CREATE OR REPLACE TABLE allows us to rebuild the analytics
-- layer from the latest RAW data.
--
-- ============================================================


-- ============================================================
-- STEP 6: CREATE DIM_CUSTOMERS
-- ============================================================
--
-- Purpose:
-- Store customer information in the analytics layer.
--
-- Source:
--
--     RAW.RAW_CUSTOMERS
--
-- Grain:
--
--     One row = one customer
--
-- Primary key:
--
--     CUSTOMER_ID
--
-- ============================================================

CREATE OR REPLACE TABLE ECOMMERCE_DB.ANALYTICS.DIM_CUSTOMERS
(
    CUSTOMER_ID      NUMBER,
    CUSTOMER_NAME    VARCHAR,
    EMAIL            VARCHAR,
    CITY             VARCHAR,
    COUNTRY          VARCHAR
);


-- ============================================================
-- LOAD DIM_CUSTOMERS
-- ============================================================
--
-- We select the validated customer records from the RAW layer.
--
-- ============================================================

INSERT INTO ECOMMERCE_DB.ANALYTICS.DIM_CUSTOMERS
(
    CUSTOMER_ID,
    CUSTOMER_NAME,
    EMAIL,
    CITY,
    COUNTRY
)

SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    EMAIL,
    CITY,
    COUNTRY

FROM ECOMMERCE_DB.RAW.RAW_CUSTOMERS;


-- ============================================================
-- STEP 7: CREATE DIM_PRODUCTS
-- ============================================================
--
-- Purpose:
-- Store product information in the analytics layer.
--
-- Source:
--
--     RAW.RAW_PRODUCTS
--
-- Grain:
--
--     One row = one product
--
-- Primary key:
--
--     PRODUCT_ID
--
-- ============================================================

CREATE OR REPLACE TABLE ECOMMERCE_DB.ANALYTICS.DIM_PRODUCTS
(
    PRODUCT_ID       NUMBER,
    PRODUCT_NAME     VARCHAR,
    CATEGORY         VARCHAR,
    UNIT_PRICE       NUMBER(10,2)
);


-- ============================================================
-- LOAD DIM_PRODUCTS
-- ============================================================

INSERT INTO ECOMMERCE_DB.ANALYTICS.DIM_PRODUCTS
(
    PRODUCT_ID,
    PRODUCT_NAME,
    CATEGORY,
    UNIT_PRICE
)

SELECT
    PRODUCT_ID,
    PRODUCT_NAME,
    CATEGORY,
    UNIT_PRICE

FROM ECOMMERCE_DB.RAW.RAW_PRODUCTS;


-- ============================================================
-- STEP 8: CREATE FACT_ORDERS
-- ============================================================
--
-- Purpose:
-- Store order-level transactional information.
--
-- Source:
--
--     RAW.RAW_ORDERS
--
-- Grain:
--
--     One row = one order
--
-- Important relationships:
--
--     CUSTOMER_ID → DIM_CUSTOMERS.CUSTOMER_ID
--
-- ============================================================

CREATE OR REPLACE TABLE ECOMMERCE_DB.ANALYTICS.FACT_ORDERS
(
    ORDER_ID       NUMBER,
    CUSTOMER_ID    NUMBER,
    ORDER_DATE     DATE,
    STATUS         VARCHAR
);


-- ============================================================
-- LOAD FACT_ORDERS
-- ============================================================
--
-- Only validated orders are loaded.
--
-- Because the data quality step already verified referential
-- integrity, CUSTOMER_ID should exist in DIM_CUSTOMERS.
--
-- ============================================================

INSERT INTO ECOMMERCE_DB.ANALYTICS.FACT_ORDERS
(
    ORDER_ID,
    CUSTOMER_ID,
    ORDER_DATE,
    STATUS
)

SELECT
    ORDER_ID,
    CUSTOMER_ID,
    ORDER_DATE,
    STATUS

FROM ECOMMERCE_DB.RAW.RAW_ORDERS;


-- ============================================================
-- STEP 9: CREATE FACT_ORDER_ITEMS
-- ============================================================
--
-- Purpose:
-- Store individual products purchased within each order.
--
-- Source:
--
--     RAW.RAW_ORDER_ITEMS
--
-- Grain:
--
--     One row = one product line within an order
--
-- Relationships:
--
--     ORDER_ID
--         ↓
--     FACT_ORDERS.ORDER_ID
--
--     PRODUCT_ID
--         ↓
--     DIM_PRODUCTS.PRODUCT_ID
--
-- ============================================================

CREATE OR REPLACE TABLE ECOMMERCE_DB.ANALYTICS.FACT_ORDER_ITEMS
(
    ORDER_ID       NUMBER,
    PRODUCT_ID     NUMBER,
    QUANTITY       NUMBER,
    UNIT_PRICE     NUMBER(10,2)
);


-- ============================================================
-- LOAD FACT_ORDER_ITEMS
-- ============================================================
--
-- The order item records are copied from the validated RAW
-- table.
--
-- ============================================================

INSERT INTO ECOMMERCE_DB.ANALYTICS.FACT_ORDER_ITEMS
(
    ORDER_ID,
    PRODUCT_ID,
    QUANTITY,
    UNIT_PRICE
)

SELECT
    ORDER_ID,
    PRODUCT_ID,
    QUANTITY,
    UNIT_PRICE

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS;


-- ============================================================
-- STEP 10: VERIFY ANALYTICS ROW COUNTS
-- ============================================================
--
-- This verifies that the transformation from RAW to ANALYTICS
-- produced the expected number of records.
--
-- ============================================================

SELECT
    'DIM_CUSTOMERS' AS table_name,
    COUNT(*) AS row_count

FROM ECOMMERCE_DB.ANALYTICS.DIM_CUSTOMERS

UNION ALL

SELECT
    'DIM_PRODUCTS' AS table_name,
    COUNT(*) AS row_count

FROM ECOMMERCE_DB.ANALYTICS.DIM_PRODUCTS

UNION ALL

SELECT
    'FACT_ORDERS' AS table_name,
    COUNT(*) AS row_count

FROM ECOMMERCE_DB.ANALYTICS.FACT_ORDERS

UNION ALL

SELECT
    'FACT_ORDER_ITEMS' AS table_name,
    COUNT(*) AS row_count

FROM ECOMMERCE_DB.ANALYTICS.FACT_ORDER_ITEMS;


-- ============================================================
-- STEP 11: VERIFY CUSTOMER DATA
-- ============================================================
--
-- Display a few customer records from the analytics layer.
--
-- ============================================================

SELECT
    *

FROM ECOMMERCE_DB.ANALYTICS.DIM_CUSTOMERS

LIMIT 10;


-- ============================================================
-- STEP 12: VERIFY PRODUCT DATA
-- ============================================================

SELECT
    *

FROM ECOMMERCE_DB.ANALYTICS.DIM_PRODUCTS

LIMIT 10;


-- ============================================================
-- STEP 13: VERIFY ORDER DATA
-- ============================================================

SELECT
    *

FROM ECOMMERCE_DB.ANALYTICS.FACT_ORDERS

LIMIT 10;


-- ============================================================
-- STEP 14: VERIFY ORDER ITEM DATA
-- ============================================================

SELECT
    *

FROM ECOMMERCE_DB.ANALYTICS.FACT_ORDER_ITEMS

LIMIT 10;


-- ============================================================
-- STEP 15: VERIFY ANALYTICS RELATIONSHIPS
-- ============================================================
--
-- This query checks that every order has a customer in the
-- dimension table.
--
-- Expected result:
--
--     0
--
-- ============================================================

SELECT
    COUNT(*) AS invalid_order_customer_relationships

FROM ECOMMERCE_DB.ANALYTICS.FACT_ORDERS AS O

LEFT JOIN ECOMMERCE_DB.ANALYTICS.DIM_CUSTOMERS AS C
    ON O.CUSTOMER_ID = C.CUSTOMER_ID

WHERE C.CUSTOMER_ID IS NULL;


-- ============================================================
-- STEP 16: VERIFY ORDER ITEM → ORDER RELATIONSHIP
-- ============================================================
--
-- Every order item should belong to an existing order.
--
-- Expected result:
--
--     0
--
-- ============================================================

SELECT
    COUNT(*) AS invalid_order_item_order_relationships

FROM ECOMMERCE_DB.ANALYTICS.FACT_ORDER_ITEMS AS OI

LEFT JOIN ECOMMERCE_DB.ANALYTICS.FACT_ORDERS AS O
    ON OI.ORDER_ID = O.ORDER_ID

WHERE O.ORDER_ID IS NULL;


-- ============================================================
-- STEP 17: VERIFY ORDER ITEM → PRODUCT RELATIONSHIP
-- ============================================================
--
-- Every order item should reference an existing product.
--
-- Expected result:
--
--     0
--
-- ============================================================

SELECT
    COUNT(*) AS invalid_order_item_product_relationships

FROM ECOMMERCE_DB.ANALYTICS.FACT_ORDER_ITEMS AS OI

LEFT JOIN ECOMMERCE_DB.ANALYTICS.DIM_PRODUCTS AS P
    ON OI.PRODUCT_ID = P.PRODUCT_ID

WHERE P.PRODUCT_ID IS NULL;


-- ============================================================
-- STEP 18: SAMPLE ANALYTICS QUERY
-- ============================================================
--
-- This demonstrates how the analytics layer can be used.
--
-- Calculate total spending for each customer.
--
-- Formula:
--
--     QUANTITY × UNIT_PRICE
--
-- ============================================================

SELECT
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,

    SUM(
        OI.QUANTITY * OI.UNIT_PRICE
    ) AS TOTAL_SPENDING

FROM ECOMMERCE_DB.ANALYTICS.DIM_CUSTOMERS AS C

INNER JOIN ECOMMERCE_DB.ANALYTICS.FACT_ORDERS AS O
    ON C.CUSTOMER_ID = O.CUSTOMER_ID

INNER JOIN ECOMMERCE_DB.ANALYTICS.FACT_ORDER_ITEMS AS OI
    ON O.ORDER_ID = OI.ORDER_ID

GROUP BY
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME

ORDER BY TOTAL_SPENDING DESC

LIMIT 10;


-- ============================================================
-- PIPELINE STAGE COMPLETE
-- ============================================================
--
-- At this point our architecture is:
--
--
--                    CSV FILES
--                        │
--                        ▼
--                PYTHON STAGE LOADER
--                        │
--                        ▼
--               SNOWFLAKE INTERNAL STAGE
--                        │
--                        ▼
--                  RAW TABLES
--                        │
--                        ▼
--              DATA QUALITY CHECKS
--                        │
--                        ▼
--                 ANALYTICS LAYER
--                        │
--            ┌───────────┼───────────┐
--            │           │           │
--            ▼           ▼           ▼
--       DIM_CUSTOMERS DIM_PRODUCTS FACT_ORDERS
--                                      │
--                                      ▼
--                               FACT_ORDER_ITEMS
--
-- ============================================================
--
-- NEXT STEP:
--
-- Create the Python automation for this analytics SQL file.
--
-- The Python pipeline will eventually execute:
--
--     1. Stage Loader
--     2. 03_load_data.sql
--     3. 04_data_quality.sql
--     4. 05_analytics_tables.sql
--     5. Pipeline audit / logging
--
-- ============================================================