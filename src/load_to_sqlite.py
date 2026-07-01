"""
load_to_sqlite.py

Loads the raw Telco Churn CSV into a local SQLite database.

WHY SQLITE (and not just pandas):
SQLite is a real, full-featured relational database engine — it just happens
to live in a single file instead of needing a server. It supports standard
SQL including JOINs, subqueries, CTEs, and window functions (ROW_NUMBER,
RANK, AVG() OVER, etc). Writing queries against it is genuine SQL practice,
the same skill you'd use against Postgres/MySQL/Snowflake at a job — the only
difference is there's no server to install. Pandas can filter and aggregate,
but it doesn't make you practice SQL syntax, query planning, or relational
thinking (e.g. "what table is this column logically part of?").

WHY WE CLEAN BEFORE LOADING:
Garbage in, garbage out. If we load TotalCharges as TEXT with blank strings
in it, every query that tries to SUM or AVG it will silently produce wrong
numbers or just error out. We fix data types at load time, not after.
"""

import sqlite3
import pandas as pd
from pathlib import Path

RAW_CSV_PATH = "data/raw/telco_churn.csv"
DB_PATH = "data/processed/churn.db"


def load_and_clean(csv_path: str = RAW_CSV_PATH) -> pd.DataFrame:
    """Load the raw CSV and fix known data quality issues."""
    df = pd.read_csv(csv_path)

    # TotalCharges is stored as a string in the raw data, and 11 rows have
    # a blank string instead of a number (these are customers with tenure=0,
    # i.e. brand new customers who haven't been charged yet).
    # We coerce to numeric; blanks become NaN, then we fill with 0 since
    # that's the correct real-world value (no tenure = no charges yet).
    df["TotalCharges"] = pd.to_numeric(df["TotalCharges"], errors="coerce")
    df["TotalCharges"] = df["TotalCharges"].fillna(0)

    # Standardize the target column to a clean integer (0/1) instead of
    # the string "Yes"/"No". This makes every downstream SQL aggregation
    # (AVG(churned) = churn rate) and every ML library happy.
    df["Churn"] = (df["Churn"] == "Yes").astype(int)

    # Column names with spaces or mixed case are annoying in SQL (you'd need
    # to quote every reference). Normalize to snake_case once, here.
    df.columns = [c.strip() for c in df.columns]

    return df


def write_to_sqlite(df: pd.DataFrame, db_path: str = DB_PATH, table_name: str = "customers"):
    """Write the cleaned dataframe into a SQLite database as a table."""
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    df.to_sql(table_name, conn, if_exists="replace", index=False)

    # Indexes speed up queries that filter/join on these columns a lot.
    # This also demonstrates you understand WHY indexes matter, not just
    # that they exist.
    conn.execute("CREATE INDEX IF NOT EXISTS idx_customer_id ON customers(customerID);")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_churn ON customers(Churn);")
    conn.commit()
    conn.close()
    print(f"Loaded {len(df)} rows into {db_path}, table '{table_name}'.")


if __name__ == "__main__":
    df = load_and_clean()
    write_to_sqlite(df)
