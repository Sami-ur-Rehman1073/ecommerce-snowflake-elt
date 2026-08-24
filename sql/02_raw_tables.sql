-- ============================================================
-- E-COMMERCE SNOWFLAKE ETL PIPELINE
-- File: 02_raw_tables.sql
--
-- Purpose:
-- This script creates the tables in the RAW layer.
--
-- The RAW layer stores the data received from our source
-- CSV files with minimal transformation.
--
-- Tables created:
--
--   1. RAW_CUSTOMERS
--   2. RAW_PRODUCTS
--   3. RAW_ORDERS
--   4. RAW_ORDER_ITEMS
--
-- Execution order:
-- This file must be executed AFTER:
--
--     01_database_setup.sql
--
-- and BEFORE:
--
--     03_load_data.sql
-- ============================================================


-- ============================================================
-- STEP 1: SELECT DATABASE, SCHEMA AND WAREHOUSE
-- ============================================================
--
-- We explicitly select these objects so the script behaves
-- consistently when it is later executed automatically by
-- Python.
-- ============================================================

USE DATABASE ECOMMERCE_DB;

USE SCHEMA RAW;

USE WAREHOUSE ECOMMERCE_WH;


-- ============================================================
-- STEP 2: CREATE RAW_CUSTOMERS
-- ============================================================
--
-- This table stores customer information from customers.csv.
--
-- Source file:
--
--     data/customers.csv
--
-- Example source data:
--
-- customer_id,customer_name,email,city,country
-- 1,Ali Khan,ali@example.com,Lahore,Pakistan
--
-- Grain:
--
--     One row = one customer
--
-- Primary identifier:
--
--     customer_id
--
-- We are not declaring a PRIMARY KEY here because Snowflake
-- does not enforce standard primary-key constraints in the
-- same way as a traditional OLTP database.
--
-- Data validation will be handled separately in:
--
--     04_data_quality.sql
-- ============================================================

CREATE TABLE IF NOT EXISTS RAW_CUSTOMERS (
    customer_id INTEGER,
    customer_name VARCHAR,
    email VARCHAR,
    city VARCHAR,
    country VARCHAR
);


-- ============================================================
-- STEP 3: CREATE RAW_PRODUCTS
-- ============================================================
--
-- This table stores product information from products.csv.
--
-- Source file:
--
--     data/products.csv
--
-- Grain:
--
--     One row = one product
--
-- product_id uniquely identifies a product logically.
--
-- unit_price is stored as NUMBER(10,2):
--
--     NUMBER(10,2)
--
-- means:
--
--     Maximum 10 digits in total
--     2 digits after the decimal point
--
-- Example:
--
--     1299.99
-- ============================================================

CREATE TABLE IF NOT EXISTS RAW_PRODUCTS (
    product_id INTEGER,
    product_name VARCHAR,
    category VARCHAR,
    unit_price NUMBER(10, 2)
);


-- ============================================================
-- STEP 4: CREATE RAW_ORDERS
-- ============================================================
--
-- This table stores order-level information from orders.csv.
--
-- Source file:
--
--     data/orders.csv
--
-- Grain:
--
--     One row = one order
--
-- customer_id connects the order to a customer.
--
-- order_date stores the date on which the order was created.
--
-- status stores the current order status.
--
-- Example statuses:
--
--     COMPLETED
--     PENDING
--     CANCELLED
-- ============================================================

CREATE TABLE IF NOT EXISTS RAW_ORDERS (
    order_id INTEGER,
    customer_id INTEGER,
    order_date DATE,
    status VARCHAR
);


-- ============================================================
-- STEP 5: CREATE RAW_ORDER_ITEMS
-- ============================================================
--
-- This table stores individual products contained within
-- each order.
--
-- Source file:
--
--     data/order_items.csv
--
-- Grain:
--
--     One row = one product line inside an order
--
-- Example:
--
-- order_id | product_id | quantity | unit_price
-- ------------------------------------------------
-- 1001     | 5          | 2        | 500.00
-- 1001     | 8          | 1        | 200.00
--
-- Order 1001 therefore contains two different product lines.
--
-- We will later calculate:
--
--     item_total = quantity * unit_price
--
-- in the ANALYTICS layer.
--
-- We intentionally do NOT calculate item_total here because
-- RAW should remain close to the source data.
-- ============================================================

CREATE TABLE IF NOT EXISTS RAW_ORDER_ITEMS (
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    unit_price NUMBER(10, 2)
);


-- ============================================================
-- STEP 6: VERIFY THE RAW TABLES
-- ============================================================
--
-- These commands are useful during development.
--
-- When Python eventually runs this file automatically,
-- these commands are not required for the pipeline logic,
-- but they are useful if you execute the script manually.
-- ============================================================

SHOW TABLES;


-- ============================================================
-- RAW TABLE STRUCTURE
-- ============================================================
--
-- After this script finishes, our RAW layer should look like:
--
-- ECOMMERCE_DB
--     |
--     └── RAW
--         |
--         ├── RAW_CUSTOMERS
--         ├── RAW_PRODUCTS
--         ├── RAW_ORDERS
--         └── RAW_ORDER_ITEMS
--
-- The tables are currently empty.
--
-- The actual CSV data will be loaded by:
--
--     03_load_data.sql
--
-- ============================================================