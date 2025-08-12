import os
from pathlib import Path
import pandas as pd
import csv
import snowflake.connector
from dotenv import dotenv_values
from jinja2 import Template


args = dotenv_values('.env')

conn = snowflake.connector.connect(
    user=args['SNOWFLAKE_USER'],
    account=args['SNOWFLAKE_ACCOUNT'],
    warehouse=args['SNOWFLAKE_WAREHOUSE'],
    database=args['SNOWFLAKE_DATABASE'],
    schema=args['SNOWFLAKE_SCHEMA'],
    authenticator='externalbrowser'
)

CSV_DIR = args['CSV_DIR']

LOCAL_STAGE = CSV_DIR
SNOWFLAKE_STAGE = "omop_export"
FILE_FORMAT = "omop_export_format"
COPY_PARAMETERS = "SINGLE=TRUE max_file_size=2147483648 header=TRUE overwrite=TRUE"
LIMIT_PARAM = "limit 1000"

# Prepare SQL execution context
kwargs = {
    "LOCAL_STAGE": LOCAL_STAGE,
    "SNOWFLAKE_STAGE": SNOWFLAKE_STAGE,
    "FILE_FORMAT": FILE_FORMAT,
    "COPY_PARAMETERS": COPY_PARAMETERS,
    "LIMIT_PARAM": LIMIT_PARAM,
}

# Read SQL file from the specified directory
sql_path = Path('download_sample.sql')
if not sql_path.is_file():
    raise FileNotFoundError(f"SQL file not found: {sql_path}")

# Read the content of the SQL file
with open(sql_path, 'r') as sql_file:
    sql_content = sql_file.read()

if not sql_content.strip():
    raise ValueError(f"SQL file {sql_path} is empty")

# Apply Jinja2 templating
template = Template(sql_content)
rendered_sql = template.render(**kwargs)

# Execute the SQL query
cursor = conn.cursor()
try:
    cursor.execute(rendered_sql)
    print("SQL executed successfully")
except Exception as e:
    print(f"Error executing SQL: {e}")
finally:
    cursor.close()

# Iterate over all files in the directory
for filename in os.listdir(CSV_DIR):
    if filename.endswith('.csv'):
        file_path = os.path.join(CSV_DIR, filename)
        print(file_path)
        # Read the CSV file
        df = pd.read_csv(file_path)

        # Convert column names to lowercase
        df.columns = [col.lower() for col in df.columns]

        # Save the modified DataFrame back to CSV
        df.to_csv(file_path, quoting=csv.QUOTE_NONNUMERIC, index=False)
