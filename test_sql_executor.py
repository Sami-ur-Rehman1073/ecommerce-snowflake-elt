"""
Test SQL Executor
=================

This is a temporary test script.

Purpose:
    Verify that Python can:

    1. Connect to Snowflake.
    2. Read 03_load_data.sql.
    3. Execute the SQL file through sql_executor.py.
    4. Display the results returned by Snowflake.

This file is only for testing.

It will NOT be part of the final pipeline.
"""


from python.snowflake_connection import get_connection

from python.sql_executor import execute_sql_file


def main():

    connection = None

    try:

        # ====================================================
        # STEP 1: CONNECT TO SNOWFLAKE
        # ====================================================

        print("=" * 60)
        print("CONNECTING TO SNOWFLAKE")
        print("=" * 60)

        connection = get_connection()

        print("Snowflake connection successful!")


        # ====================================================
        # STEP 2: EXECUTE SQL FILE
        # ====================================================

        print("\n" + "=" * 60)
        print("EXECUTING 03_LOAD_DATA.SQL")
        print("=" * 60)

        cursors = execute_sql_file(
            connection,
            "03_load_data.sql"
        )

        print("\nSQL file executed successfully!")


        # ====================================================
        # STEP 3: DISPLAY RESULTS
        # ====================================================

        print("\n" + "=" * 60)
        print("SQL RESULTS")
        print("=" * 60)


        for index, cursor in enumerate(
            cursors,
            start=1
        ):

            print(f"\nStatement {index}:")


            try:

                # ------------------------------------------------
                # Some SQL statements return rows.
                #
                # Example:
                #
                # SELECT ...
                #
                # Other statements such as USE or COPY may have
                # different result structures.
                # ------------------------------------------------

                if cursor.description:

                    rows = cursor.fetchall()


                    for row in rows:

                        print(row)

                else:

                    print("No result set returned.")


            except Exception as error:

                print(
                    f"Could not read result: {error}"
                )


            finally:

                # ------------------------------------------------
                # Close this cursor after processing its result.
                # ------------------------------------------------

                cursor.close()


    except Exception as error:

        # ====================================================
        # SQL EXECUTION FAILED
        # ====================================================

        print("\n" + "=" * 60)
        print("SQL EXECUTION FAILED")
        print("=" * 60)

        print(f"Error: {error}")


    finally:

        # ====================================================
        # CLOSE SNOWFLAKE CONNECTION
        # ====================================================

        if connection:

            connection.close()

            print("\nSnowflake connection closed.")


# ============================================================
# PROGRAM ENTRY POINT
# ============================================================

if __name__ == "__main__":

    main()