"""
SQL Executor
============

Purpose:
    This module reads SQL files from the project's sql/
    directory and executes their SQL statements in Snowflake.

Responsibilities:

    SQL files:
        - Database setup
        - Table creation
        - Data loading
        - Data quality checks
        - Analytics
        - Pipeline audit

    Python:
        - Read SQL files
        - Execute SQL statements
        - Handle errors
        - Control pipeline execution
"""


# ============================================================
# IMPORTS
# ============================================================

import re

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

    Returns
    -------
    str
        Complete SQL content.
    """

    # --------------------------------------------------------
    # Build the SQL file path.
    # --------------------------------------------------------

    sql_file = SQL_DIR / file_name


    # --------------------------------------------------------
    # Make sure the SQL file exists.
    # --------------------------------------------------------

    if not sql_file.exists():

        raise FileNotFoundError(
            f"SQL file not found: {sql_file}"
        )


    # --------------------------------------------------------
    # Make sure the path points to a file.
    # --------------------------------------------------------

    if not sql_file.is_file():

        raise FileNotFoundError(
            f"SQL path is not a file: {sql_file}"
        )


    # --------------------------------------------------------
    # Read the file.
    # --------------------------------------------------------

    return sql_file.read_text(
        encoding="utf-8"
    )


# ============================================================
# REMOVE SQL COMMENTS
# ============================================================

def remove_sql_comments(sql: str) -> str:
    """
    Remove single-line SQL comments.

    Our project SQL files use comments in this format:

        -- This is a comment

    Removing these comments before splitting the SQL script
    prevents comment-only sections from being interpreted as
    empty SQL statements.
    """

    # --------------------------------------------------------
    # Remove everything from -- to the end of each line.
    # --------------------------------------------------------

    sql_without_comments = re.sub(
        r"--[^\n]*",
        "",
        sql
    )


    return sql_without_comments


# ============================================================
# SPLIT SQL SCRIPT INTO STATEMENTS
# ============================================================

def split_sql_statements(sql: str) -> list[str]:
    """
    Split a SQL script into individual SQL statements.

    Example:

        USE DATABASE ECOMMERCE_DB;

        USE SCHEMA RAW;

    becomes:

        [
            "USE DATABASE ECOMMERCE_DB",
            "USE SCHEMA RAW"
        ]

    Empty statements are removed.
    """

    # --------------------------------------------------------
    # Remove comments first.
    # --------------------------------------------------------

    sql = remove_sql_comments(sql)


    # --------------------------------------------------------
    # Split statements using semicolon.
    #
    # Our project SQL files use semicolons to separate
    # statements.
    # --------------------------------------------------------

    raw_statements = sql.split(";")


    # --------------------------------------------------------
    # Remove whitespace-only statements.
    # --------------------------------------------------------

    statements = []

    for statement in raw_statements:

        statement = statement.strip()


        if statement:

            statements.append(statement)


    return statements


# ============================================================
# EXECUTE SINGLE SQL STATEMENT
# ============================================================

def execute_sql(connection, sql: str):
    """
    Execute one SQL statement in Snowflake.

    Parameters
    ----------
    connection
        Active Snowflake connection.

    sql : str
        SQL statement to execute.

    Returns
    -------
    cursor
        Snowflake cursor.
    """

    # --------------------------------------------------------
    # Create a cursor.
    # --------------------------------------------------------

    cursor = connection.cursor()


    try:

        # ----------------------------------------------------
        # Execute the SQL statement.
        # ----------------------------------------------------

        cursor.execute(sql)


        # ----------------------------------------------------
        # Return the cursor.
        # ----------------------------------------------------

        return cursor


    except Exception:

        # ----------------------------------------------------
        # Close cursor if execution fails.
        # ----------------------------------------------------

        cursor.close()

        raise


# ============================================================
# EXECUTE COMPLETE SQL FILE
# ============================================================

def execute_sql_file(connection, file_name: str):
    """
    Execute all SQL statements contained in a SQL file.

    Parameters
    ----------
    connection
        Active Snowflake connection.

    file_name : str
        Name of the SQL file.

    Returns
    -------
    list
        List of cursors generated by the SQL statements.

    Notes
    -----
    Instead of passing the complete file directly to
    execute_stream(), we split the file into valid SQL
    statements first.

    This prevents empty statements from being sent to
    Snowflake.
    """

    # --------------------------------------------------------
    # Read SQL file.
    # --------------------------------------------------------

    sql_content = read_sql_file(
        file_name
    )


    # --------------------------------------------------------
    # Make sure the file isn't empty.
    # --------------------------------------------------------

    if not sql_content.strip():

        raise ValueError(
            f"SQL file is empty: {file_name}"
        )


    # --------------------------------------------------------
    # Split the SQL file into individual statements.
    # --------------------------------------------------------

    statements = split_sql_statements(
        sql_content
    )


    # --------------------------------------------------------
    # Make sure we actually found SQL statements.
    # --------------------------------------------------------

    if not statements:

        raise ValueError(
            f"No executable SQL statements found in: "
            f"{file_name}"
        )


    # --------------------------------------------------------
    # Store execution results.
    # --------------------------------------------------------

    cursors = []


    try:

        # ----------------------------------------------------
        # Execute each statement separately.
        # ----------------------------------------------------

        for statement in statements:

            cursor = execute_sql(
                connection,
                statement
            )

            cursors.append(cursor)


        return cursors


    except Exception:

        # ----------------------------------------------------
        # If one statement fails, close all cursors that have
        # already been created.
        # ----------------------------------------------------

        for cursor in cursors:

            try:

                cursor.close()

            except Exception:

                pass


        raise