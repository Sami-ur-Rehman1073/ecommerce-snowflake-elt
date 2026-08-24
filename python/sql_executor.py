"""
SQL Executor
============

Purpose:
    This module is responsible for reading SQL files from the
    project's sql/ directory and executing them in Snowflake.

Architecture:

    SQL files
        |
        v
    sql_executor.py
        |
        v
    Snowflake

Why keep SQL and Python separate?

    SQL is responsible for:
        - Creating tables
        - Loading data
        - Data quality checks
        - Transformations
        - Analytics queries

    Python is responsible for:
        - Connecting to Snowflake
        - Reading SQL files
        - Executing SQL
        - Controlling pipeline execution
        - Handling errors

This separation makes the project easier to maintain and
understand.
"""


# ============================================================
# IMPORTS
# ============================================================

from pathlib import Path

from python.config import SQL_DIR


# ============================================================
# READ SQL FILE
# ============================================================

def read_sql_file(file_name: str) -> str:
    """
    Read a SQL file from the project's sql directory.

    Parameters
    ----------
    file_name : str
        Name of the SQL file.

        Example:
            "03_load_data.sql"

    Returns
    -------
    str
        Complete SQL content of the file.

    Raises
    ------
    FileNotFoundError
        If the requested SQL file does not exist.
    """

    # --------------------------------------------------------
    # Build the complete path to the SQL file.
    #
    # SQL_DIR comes from config.py.
    #
    # Example:
    #
    # D:/ecommerce-snowflake-etl/sql
    #
    # + 03_load_data.sql
    #
    # becomes:
    #
    # D:/ecommerce-snowflake-etl/sql/03_load_data.sql
    # --------------------------------------------------------

    sql_file = SQL_DIR / file_name


    # --------------------------------------------------------
    # Check whether the file exists.
    # --------------------------------------------------------

    if not sql_file.exists():

        raise FileNotFoundError(
            f"SQL file not found: {sql_file}"
        )


    # --------------------------------------------------------
    # Make sure the path points to a file rather than a folder.
    # --------------------------------------------------------

    if not sql_file.is_file():

        raise FileNotFoundError(
            f"SQL path is not a file: {sql_file}"
        )


    # --------------------------------------------------------
    # Read the SQL file using UTF-8 encoding.
    # --------------------------------------------------------

    sql_content = sql_file.read_text(
        encoding="utf-8"
    )


    # --------------------------------------------------------
    # Return the SQL code.
    # --------------------------------------------------------

    return sql_content


# ============================================================
# EXECUTE SINGLE SQL STATEMENT
# ============================================================

def execute_sql(connection, sql: str):
    """
    Execute a single SQL statement in Snowflake.

    Parameters
    ----------
    connection
        Active Snowflake connection.

    sql : str
        SQL statement to execute.

    Returns
    -------
    cursor
        Snowflake cursor containing the execution result.

    Notes
    -----
    This function is useful when we need to execute one SQL
    statement directly from Python.
    """

    # --------------------------------------------------------
    # Create a Snowflake cursor.
    # --------------------------------------------------------

    cursor = connection.cursor()


    try:

        # ----------------------------------------------------
        # Execute the SQL statement.
        # ----------------------------------------------------

        cursor.execute(sql)


        # ----------------------------------------------------
        # Return the cursor so the caller can inspect the
        # result if required.
        # ----------------------------------------------------

        return cursor


    except Exception:

        # ----------------------------------------------------
        # If execution fails, close the cursor before raising
        # the error to the caller.
        # ----------------------------------------------------

        cursor.close()

        raise


# ============================================================
# EXECUTE COMPLETE SQL FILE
# ============================================================

def execute_sql_file(connection, file_name: str):
    """
    Read and execute a complete SQL file.

    Parameters
    ----------
    connection
        Active Snowflake connection.

    file_name : str
        Name of the SQL file inside the sql/ directory.

    Returns
    -------
    list
        List of cursors returned by Snowflake.

    Example
    -------
    execute_sql_file(
        connection,
        "03_load_data.sql"
    )

    The SQL file can contain multiple statements such as:

        USE DATABASE ...
        USE SCHEMA ...
        COPY INTO ...
        COPY INTO ...
        SELECT ...

    Snowflake's execute_stream() is used to execute the
    statements in the SQL script.
    """

    # --------------------------------------------------------
    # Read the SQL file.
    # --------------------------------------------------------

    sql_content = read_sql_file(
        file_name
    )


    # --------------------------------------------------------
    # Prevent accidentally executing an empty SQL file.
    # --------------------------------------------------------

    if not sql_content.strip():

        raise ValueError(
            f"SQL file is empty: {file_name}"
        )


    # --------------------------------------------------------
    # Store the cursors returned by Snowflake.
    # --------------------------------------------------------

    cursors = []


    try:

        # ----------------------------------------------------
        # execute_stream() executes the SQL script and returns
        # a cursor for each executed statement.
        # ----------------------------------------------------

        for cursor in connection.execute_stream(
            sql_content
        ):

            cursors.append(cursor)


        # ----------------------------------------------------
        # Return all cursors to the caller.
        # ----------------------------------------------------

        return cursors


    except Exception:

        # ----------------------------------------------------
        # If any SQL statement fails, close any cursors that
        # have already been created.
        # ----------------------------------------------------

        for cursor in cursors:

            try:

                cursor.close()

            except Exception:

                pass


        # ----------------------------------------------------
        # Re-raise the original exception.
        # ----------------------------------------------------

        raise