"""
Snowflake Stage Loader
======================

This module is responsible for uploading the local CSV files
from our project's data/ directory into the Snowflake internal
stage.

ETL flow:

    Local CSV files
          |
          | Python PUT command
          v
    @ECOMMERCE_STAGE
          |
          v
    Snowflake RAW loading
"""


from pathlib import Path

from python.config import (
    DATA_DIR,
    SNOWFLAKE_STAGE,
)


# ============================================================
# SOURCE FILES
# ============================================================
#
# These are the four CSV files that make up our e-commerce
# dataset.
#
# They should exist inside:
#
#     D:\ecommerce-snowflake-etl\data\
#
# ============================================================

SOURCE_FILES = [
    "customers.csv",
    "products.csv",
    "orders.csv",
    "order_items.csv",
]


# ============================================================
# UPLOAD ONE FILE
# ============================================================

def upload_file(connection, file_name: str):
    """
    Upload one CSV file to the Snowflake internal stage.

    Parameters
    ----------
    connection:
        An active Snowflake connection.

    file_name : str
        Name of the CSV file inside the data directory.

    Returns
    -------
    list
        Result returned by Snowflake's PUT command.

    Example
    -------
    upload_file(connection, "customers.csv")
    """

    # --------------------------------------------------------
    # Build the complete local file path.
    #
    # Example:
    #
    # D:/ecommerce-snowflake-etl/data/customers.csv
    # --------------------------------------------------------

    local_file = DATA_DIR / file_name


    # --------------------------------------------------------
    # Verify that the file actually exists.
    #
    # We don't want to send a PUT command for a file that
    # doesn't exist.
    # --------------------------------------------------------

    if not local_file.exists():

        raise FileNotFoundError(
            f"Source file not found: {local_file}"
        )


    # --------------------------------------------------------
    # Convert the Windows path into a format that Snowflake
    # can understand.
    #
    # Windows:
    #
    # D:\ecommerce-snowflake-etl\data\customers.csv
    #
    # becomes:
    #
    # D:/ecommerce-snowflake-etl/data/customers.csv
    # --------------------------------------------------------

    file_uri = local_file.as_posix()


    # --------------------------------------------------------
    # Build the Snowflake PUT command.
    #
    # PUT uploads a local file into a Snowflake internal stage.
    #
    # AUTO_COMPRESS = FALSE
    #
    # We keep the CSV files uncompressed because our project
    # is small and this makes the process easier to understand.
    #
    # OVERWRITE = TRUE
    #
    # If the file already exists in the stage, replace it with
    # the current local version.
    # --------------------------------------------------------

    put_command = f"""
        PUT 'file://{file_uri}'
        {SNOWFLAKE_STAGE}
        AUTO_COMPRESS = FALSE
        OVERWRITE = TRUE
    """


    # --------------------------------------------------------
    # Create a Snowflake cursor.
    #
    # A cursor is used to execute SQL commands.
    # --------------------------------------------------------

    cursor = connection.cursor()


    try:

        # ----------------------------------------------------
        # Execute the PUT command.
        # ----------------------------------------------------

        cursor.execute(put_command)


        # ----------------------------------------------------
        # Fetch the result returned by Snowflake.
        #
        # Snowflake returns information such as:
        #
        # source file
        # target file
        # source size
        # target size
        # status
        # ----------------------------------------------------

        result = cursor.fetchall()

        return result


    finally:

        # ----------------------------------------------------
        # Always close the cursor after the operation.
        # ----------------------------------------------------

        cursor.close()


# ============================================================
# UPLOAD ALL FILES
# ============================================================

def upload_all_files(connection):
    """
    Upload all source CSV files to the Snowflake stage.

    Parameters
    ----------
    connection:
        Active Snowflake connection.

    Returns
    -------
    dict
        Dictionary containing the upload result for each file.

    Example
    -------
    {
        "customers.csv": [...],
        "products.csv": [...],
        "orders.csv": [...],
        "order_items.csv": [...]
    }
    """

    upload_results = {}


    # --------------------------------------------------------
    # Process each source file one by one.
    # --------------------------------------------------------

    for file_name in SOURCE_FILES:

        print(f"Uploading {file_name}...")


        # ----------------------------------------------------
        # Upload the current file.
        # ----------------------------------------------------

        result = upload_file(
            connection,
            file_name
        )


        # ----------------------------------------------------
        # Store the result.
        # ----------------------------------------------------

        upload_results[file_name] = result


        print(f"Successfully uploaded {file_name}.")


    return upload_results