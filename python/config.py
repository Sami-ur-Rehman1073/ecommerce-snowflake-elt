"""
Configuration for the E-Commerce Snowflake ETL Pipeline.

This module loads configuration values from the .env file
and provides them to the rest of the Python application.
"""

import os
from pathlib import Path

from dotenv import load_dotenv


# ============================================================
# PROJECT PATH
# ============================================================
#
# __file__ points to:
#
#     python/config.py
#
# .resolve().parent.parent moves:
#
#     config.py
#        ↓
#     python/
#        ↓
#     ecommerce-snowflake-etl/
#
# Therefore BASE_DIR represents the root of our project.
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent


# ============================================================
# LOAD ENVIRONMENT VARIABLES
# ============================================================
#
# This loads variables from:
#
#     ecommerce-snowflake-etl/.env
#
# We never hard-code passwords or other secrets directly
# into Python source code.
# ============================================================

load_dotenv(BASE_DIR / ".env")


# ============================================================
# SNOWFLAKE CONFIGURATION
# ============================================================

SNOWFLAKE_ACCOUNT = os.getenv("SNOWFLAKE_ACCOUNT")
SNOWFLAKE_USER = os.getenv("SNOWFLAKE_USER")
SNOWFLAKE_PASSWORD = os.getenv("SNOWFLAKE_PASSWORD")

SNOWFLAKE_WAREHOUSE = os.getenv(
    "SNOWFLAKE_WAREHOUSE",
    "ECOMMERCE_WH"
)

SNOWFLAKE_DATABASE = os.getenv(
    "SNOWFLAKE_DATABASE",
    "ECOMMERCE_DB"
)

SNOWFLAKE_SCHEMA = os.getenv(
    "SNOWFLAKE_SCHEMA",
    "RAW"
)

SNOWFLAKE_ROLE = os.getenv("SNOWFLAKE_ROLE")


# ============================================================
# PROJECT DIRECTORIES
# ============================================================

DATA_DIR = BASE_DIR / "data"

SQL_DIR = BASE_DIR / "sql"


# ============================================================
# SNOWFLAKE STAGE
# ============================================================
#
# This is the internal Snowflake stage created by:
#
#     01_database_setup.sql
#
# Python will upload our CSV files here.
# ============================================================

SNOWFLAKE_STAGE = "@ECOMMERCE_STAGE"


# ============================================================
# REQUIRED ENVIRONMENT VARIABLES
# ============================================================
#
# Fail early if an important credential is missing.
#
# This is much better than allowing the pipeline to run for
# several steps and then fail later with an unclear error.
# ============================================================

required_variables = {
    "SNOWFLAKE_ACCOUNT": SNOWFLAKE_ACCOUNT,
    "SNOWFLAKE_USER": SNOWFLAKE_USER,
    "SNOWFLAKE_PASSWORD": SNOWFLAKE_PASSWORD,
}


missing_variables = [
    name
    for name, value in required_variables.items()
    if not value
]


if missing_variables:
    raise ValueError(
        "Missing required environment variables: "
        + ", ".join(missing_variables)
    )