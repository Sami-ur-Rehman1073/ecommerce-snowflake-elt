"""
Snowflake connection module.

This module creates and manages connections between our
Python ETL application and Snowflake.

The actual credentials are NOT stored in this file.

They are loaded from .env through config.py.
"""

import snowflake.connector

from python.config import (
    SNOWFLAKE_ACCOUNT,
    SNOWFLAKE_USER,
    SNOWFLAKE_PASSWORD,
    SNOWFLAKE_WAREHOUSE,
    SNOWFLAKE_DATABASE,
    SNOWFLAKE_SCHEMA,
    SNOWFLAKE_ROLE,
)


# ============================================================
# CREATE SNOWFLAKE CONNECTION
# ============================================================
#
# This function establishes a connection to Snowflake.
#
# Other Python modules can simply call:
#
#     connection = get_connection()
#
# instead of repeating all the connection configuration.
# ============================================================

def get_connection():
    """
    Create and return a Snowflake database connection.

    Returns
    -------
    snowflake.connector.SnowflakeConnection
        Active connection to Snowflake.
    """

    connection_parameters = {
        "account": SNOWFLAKE_ACCOUNT,
        "user": SNOWFLAKE_USER,
        "password": SNOWFLAKE_PASSWORD,
        "warehouse": SNOWFLAKE_WAREHOUSE,
        "database": SNOWFLAKE_DATABASE,
        "schema": SNOWFLAKE_SCHEMA,
    }

    # --------------------------------------------------------
    # Add role only when it is provided in .env.
    #
    # This prevents problems if SNOWFLAKE_ROLE is left empty.
    # --------------------------------------------------------

    if SNOWFLAKE_ROLE:
        connection_parameters["role"] = SNOWFLAKE_ROLE

    # --------------------------------------------------------
    # Establish the actual Snowflake connection.
    # --------------------------------------------------------

    connection = snowflake.connector.connect(
        **connection_parameters
    )

    return connection