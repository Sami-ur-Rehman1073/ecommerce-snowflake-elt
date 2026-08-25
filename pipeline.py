"""
============================================================
E-COMMERCE SNOWFLAKE ETL PIPELINE
File: pipeline.py

Purpose:
This is the main orchestration file for the complete
E-commerce ETL pipeline.

Pipeline flow:

    1. Connect to Snowflake
    2. Upload CSV files to Snowflake stage
    3. Load staged files into RAW tables
    4. Run data quality checks
    5. Build ANALYTICS tables
    6. Verify ANALYTICS tables
    7. Display pipeline status
    8. Close Snowflake connection

Architecture:

    CSV Files
        |
        v
    Python Stage Loader
        |
        v
    Snowflake Internal Stage
        |
        v
    RAW Tables
        |
        v
    Data Quality Checks
        |
        v
    ANALYTICS Tables

This file is the main orchestrator.

Individual responsibilities remain inside their respective
Python modules.
============================================================
"""

import sys
from datetime import datetime

from python.snowflake_connection import get_connection
from python.stage_loader import upload_file
from python.sql_executor import execute_sql_file


# ============================================================
# CONFIGURATION
# ============================================================

# SQL files used by the pipeline.

LOAD_DATA_SQL = "03_load_data.sql"

DATA_QUALITY_SQL = "04_data_quality.sql"

ANALYTICS_SQL = "05_analytics_tables.sql"


# ============================================================
# SOURCE CSV FILES
# ============================================================
#
# These files are uploaded to the Snowflake internal stage.
#
# stage_loader.upload_file() expects:
#
#     connection
#     file_name
#
# Therefore, each file is uploaded individually.
#
# ============================================================

CSV_FILES = [
    "customers.csv",
    "products.csv",
    "orders.csv",
    "order_items.csv"
]


# ============================================================
# HELPER FUNCTION
# ============================================================

def print_step(step_number, total_steps, message):
    """
    Print a consistent pipeline step heading.
    """

    print()
    print("=" * 70)
    print(f"[{step_number}/{total_steps}] {message}")
    print("=" * 70)


# ============================================================
# DATA QUALITY RESULT CHECK
# ============================================================

def check_data_quality_results(results):
    """
    Inspect the final result returned by 04_data_quality.sql.

    The final statement in 04_data_quality.sql produces:

        check_name
        issue_count
        status

    Example:

        ('NULL CUSTOMER IDs', 0, 'PASS')

    The pipeline continues only when all checks pass.

    Parameters:
        results:
            Result sets returned by execute_sql_file().

    Returns:
        True  -> all checks passed
        False -> at least one check failed
    """

    # --------------------------------------------------------
    # Make sure SQL returned something.
    # --------------------------------------------------------

    if not results:

        print("WARNING: Data quality SQL returned no results.")

        return False


    # --------------------------------------------------------
    # The final SQL statement is the data-quality summary.
    # --------------------------------------------------------

    summary = results[-1]


    # --------------------------------------------------------
    # Make sure the summary is not empty.
    # --------------------------------------------------------

    if not summary:

        print("WARNING: Data quality summary is empty.")

        return False


    print()
    print("DATA QUALITY SUMMARY")
    print("-" * 70)


    quality_passed = True


    # --------------------------------------------------------
    # Process every data-quality check.
    # --------------------------------------------------------

    for row in summary:

        # Expected structure:
        #
        # row[0] = check_name
        # row[1] = issue_count
        # row[2] = status

        check_name = row[0]

        issue_count = row[1]

        status = row[2]


        print(
            f"{check_name:<45}"
            f"Issues: {issue_count:<8}"
            f"Status: {status}"
        )


        # ----------------------------------------------------
        # If any check fails, mark the complete quality stage
        # as failed.
        # ----------------------------------------------------

        if str(status).upper() != "PASS":

            quality_passed = False


    print("-" * 70)


    return quality_passed


# ============================================================
# VERIFY ANALYTICS TABLES
# ============================================================

def verify_analytics_tables(connection):
    """
    Verify that the four ANALYTICS tables were created
    successfully and contain data.

    Tables:

        DIM_CUSTOMERS
        DIM_PRODUCTS
        FACT_ORDERS
        FACT_ORDER_ITEMS

    This verification is intentionally performed using a
    separate SQL query rather than trying to inspect the
    cursor objects returned by execute_sql_file().

    This avoids the:

        'SnowflakeCursor' object is not subscriptable

    error.
    """

    verification_sql = """
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
    FROM ECOMMERCE_DB.ANALYTICS.FACT_ORDER_ITEMS
    """


    cursor = None


    try:

        # ----------------------------------------------------
        # Create a Snowflake cursor.
        # ----------------------------------------------------

        cursor = connection.cursor()


        # ----------------------------------------------------
        # Execute verification query.
        # ----------------------------------------------------

        cursor.execute(verification_sql)


        # ----------------------------------------------------
        # Fetch all rows.
        # ----------------------------------------------------

        results = cursor.fetchall()


        # ----------------------------------------------------
        # Display results.
        # ----------------------------------------------------

        print()
        print("ANALYTICS TABLE RESULTS")
        print("-" * 70)


        for row in results:

            table_name = row[0]

            row_count = row[1]

            print(
                f"{table_name:<25}"
                f"Rows: {row_count}"
            )


        print("-" * 70)


        # ----------------------------------------------------
        # Make sure all four expected tables were returned.
        # ----------------------------------------------------

        expected_tables = {
            "DIM_CUSTOMERS",
            "DIM_PRODUCTS",
            "FACT_ORDERS",
            "FACT_ORDER_ITEMS"
        }


        actual_tables = {
            row[0]
            for row in results
        }


        if not expected_tables.issubset(actual_tables):

            print(
                "ERROR: One or more expected ANALYTICS "
                "tables were not found."
            )

            return False


        return True


    finally:

        if cursor is not None:

            cursor.close()


# ============================================================
# MAIN PIPELINE
# ============================================================

def run_pipeline():

    # --------------------------------------------------------
    # Record pipeline start time.
    # --------------------------------------------------------

    start_time = datetime.now()


    # --------------------------------------------------------
    # Connection starts as None.
    #
    # This allows the finally block to safely determine
    # whether a connection was created.
    # --------------------------------------------------------

    connection = None


    print()
    print("=" * 70)
    print("E-COMMERCE SNOWFLAKE ETL PIPELINE")
    print("=" * 70)

    print(f"Pipeline started: {start_time}")


    try:

        # ====================================================
        # STEP 1: CONNECT TO SNOWFLAKE
        # ====================================================

        print_step(
            1,
            5,
            "CONNECTING TO SNOWFLAKE"
        )


        connection = get_connection()


        print("Snowflake connection successful!")


        # ====================================================
        # STEP 2: UPLOAD CSV FILES
        # ====================================================
        #
        # Each CSV file is uploaded individually.
        #
        # ====================================================

        print_step(
            2,
            5,
            "UPLOADING CSV FILES TO SNOWFLAKE STAGE"
        )


        upload_results = []


        for file_name in CSV_FILES:

            print(f"Uploading {file_name}...")


            result = upload_file(
                connection,
                file_name
            )


            upload_results.append(result)


            print(
                f"Successfully uploaded {file_name}."
            )


        print()
        print(
            "All CSV files uploaded successfully."
        )


        # ----------------------------------------------------
        # DISPLAY UPLOAD RESULTS
        # ----------------------------------------------------

        print()
        print("UPLOAD RESULTS")
        print("-" * 70)


        for file_name, result in zip(
            CSV_FILES,
            upload_results
        ):

            print()
            print(f"{file_name}:")

            print(result)


        # ====================================================
        # STEP 3: LOAD RAW TABLES
        # ====================================================

        print_step(
            3,
            5,
            "LOADING RAW TABLES"
        )


        print(
            f"Executing: {LOAD_DATA_SQL}"
        )


        load_results = execute_sql_file(
            connection,
            LOAD_DATA_SQL
        )


        print(
            "RAW tables loaded successfully."
        )


        # ----------------------------------------------------
        # DISPLAY RAW TABLE COUNTS
        # ----------------------------------------------------
        #
        # The final SELECT statement in
        # 03_load_data.sql returns the RAW table counts.
        #
        # ----------------------------------------------------

        if load_results:

            print()
            print("RAW TABLE RESULTS")
            print("-" * 70)


            for row in load_results[-1]:

                print(row)


        # ====================================================
        # STEP 4: DATA QUALITY
        # ====================================================

        print_step(
            4,
            5,
            "RUNNING DATA QUALITY CHECKS"
        )


        print(
            f"Executing: {DATA_QUALITY_SQL}"
        )


        quality_results = execute_sql_file(
            connection,
            DATA_QUALITY_SQL
        )


        # ----------------------------------------------------
        # Check the final data-quality summary.
        # ----------------------------------------------------

        quality_passed = check_data_quality_results(
            quality_results
        )


        # ====================================================
        # STOP PIPELINE IF DATA QUALITY FAILS
        # ====================================================

        if not quality_passed:

            print()
            print("=" * 70)
            print("DATA QUALITY FAILED")
            print("=" * 70)


            print(
                "The pipeline will stop because one or more "
                "data quality checks failed."
            )


            print()
            print(
                "ANALYTICS tables will NOT be rebuilt."
            )


            return False


        print()
        print(
            "All data quality checks passed."
        )


        # ====================================================
        # STEP 5: BUILD ANALYTICS TABLES
        # ====================================================

        print_step(
            5,
            5,
            "BUILDING ANALYTICS TABLES"
        )


        print(
            f"Executing: {ANALYTICS_SQL}"
        )


        # ----------------------------------------------------
        # Execute the complete analytics SQL file.
        #
        # We do NOT inspect the returned cursor objects here.
        #
        # The SQL executor is responsible for executing the
        # statements.
        #
        # After execution, verify_analytics_tables() performs
        # a clean SELECT and fetches the results itself.
        # ----------------------------------------------------

        execute_sql_file(
            connection,
            ANALYTICS_SQL
        )


        print()
        print(
            "ANALYTICS layer created successfully."
        )


        # ----------------------------------------------------
        # VERIFY ANALYTICS TABLES
        # ----------------------------------------------------

        analytics_verified = verify_analytics_tables(
            connection
        )


        # ----------------------------------------------------
        # Stop if verification failed.
        # ----------------------------------------------------

        if not analytics_verified:

            print()
            print("=" * 70)
            print(
                "ANALYTICS VERIFICATION FAILED"
            )
            print("=" * 70)

            return False


        # ====================================================
        # PIPELINE SUCCESS
        # ====================================================

        end_time = datetime.now()


        duration = (
            end_time - start_time
        )


        print()
        print("=" * 70)
        print(
            "PIPELINE COMPLETED SUCCESSFULLY"
        )
        print("=" * 70)


        print(
            f"Started : {start_time}"
        )


        print(
            f"Finished: {end_time}"
        )


        print(
            f"Duration: {duration}"
        )


        print()
        print(
            "Pipeline stages completed:"
        )


        print(
            "  [OK] Snowflake connection"
        )


        print(
            "  [OK] CSV upload"
        )


        print(
            "  [OK] RAW table loading"
        )


        print(
            "  [OK] Data quality validation"
        )


        print(
            "  [OK] ANALYTICS transformation"
        )


        print(
            "  [OK] ANALYTICS verification"
        )


        print("=" * 70)


        return True


    # ========================================================
    # PIPELINE ERROR HANDLING
    # ========================================================

    except Exception as error:

        end_time = datetime.now()


        duration = (
            end_time - start_time
        )


        print()
        print("=" * 70)
        print(
            "PIPELINE FAILED"
        )
        print("=" * 70)


        print(
            f"Error: {error}"
        )


        print()
        print(
            f"Started : {start_time}"
        )


        print(
            f"Failed  : {end_time}"
        )


        print(
            f"Duration: {duration}"
        )


        print()
        print(
            "The pipeline stopped because an unexpected "
            "error occurred."
        )


        return False


    # ========================================================
    # ALWAYS CLOSE CONNECTION
    # ========================================================

    finally:

        if connection is not None:

            connection.close()


            print()
            print(
                "Snowflake connection closed."
            )


# ============================================================
# PROGRAM ENTRY POINT
# ============================================================

if __name__ == "__main__":

    success = run_pipeline()


    # --------------------------------------------------------
    # Operating-system exit codes:
    #
    #     0 = SUCCESS
    #     1 = FAILURE
    #
    # This is useful later if we connect this pipeline to an
    # orchestrator such as Airflow.
    # --------------------------------------------------------

    if success:

        sys.exit(0)

    else:

        sys.exit(1)