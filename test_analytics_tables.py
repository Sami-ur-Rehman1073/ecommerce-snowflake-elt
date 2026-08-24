"""
============================================================
E-COMMERCE SNOWFLAKE ETL PIPELINE
File: test_analytics_tables.py

Purpose:
Test the execution of 05_analytics_tables.sql through Python.

This script:

    1. Connects to Snowflake
    2. Reads 05_analytics_tables.sql
    3. Executes the SQL statements
    4. Displays the results
    5. Closes the Snowflake connection

This is a TEST script.

The final production pipeline will later call the same
functionality automatically.
============================================================
"""

from python.sql_executor import execute_sql_file
from python.snowflake_connection import get_connection


# ============================================================
# CONFIGURATION
# ============================================================

SQL_FILE = "05_analytics_tables.sql"


# ============================================================
# MAIN FUNCTION
# ============================================================

def main():

    print("=" * 60)
    print("CONNECTING TO SNOWFLAKE")
    print("=" * 60)

    connection = None

    try:

        # ----------------------------------------------------
        # STEP 1: CREATE SNOWFLAKE CONNECTION
        # ----------------------------------------------------

        connection = get_connection()

        print("Snowflake connection successful!")

        print()
        print("=" * 60)
        print("EXECUTING 05_ANALYTICS_TABLES.SQL")
        print("=" * 60)

        # ----------------------------------------------------
        # STEP 2: EXECUTE SQL FILE
        # ----------------------------------------------------

        results = execute_sql_file(
            connection,
            SQL_FILE
        )

        print()
        print("=" * 60)
        print("SQL EXECUTION SUCCESSFUL")
        print("=" * 60)

        # ----------------------------------------------------
        # STEP 3: DISPLAY RESULTS
        # ----------------------------------------------------

        print()
        print("=" * 60)
        print("SQL RESULTS")
        print("=" * 60)

        for index, result in enumerate(results, start=1):

            print()
            print(f"Statement {index}:")

            # Display every returned row
            for row in result:
                print(row)

    except Exception as error:

        print()
        print("=" * 60)
        print("SQL EXECUTION FAILED")
        print("=" * 60)

        print(f"Error: {error}")

    finally:

        # ----------------------------------------------------
        # STEP 4: CLOSE CONNECTION
        # ----------------------------------------------------

        if connection is not None:

            connection.close()

            print()
            print("Snowflake connection closed.")


# ============================================================
# PROGRAM ENTRY POINT
# ============================================================

if __name__ == "__main__":
    main()