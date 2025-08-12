import os
import logging
from pathlib import Path
import pandas as pd
import csv
import snowflake.connector
from dotenv import dotenv_values
from jinja2 import Template

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('stage_snowflake.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def main():
    try:
        # Load environment variables
        args = dotenv_values('.env')
        if not args:
            raise ValueError("Failed to load environment variables from .env file")
        
        logger.info("Environment variables loaded successfully")
        
        # Validate required environment variables
        required_vars = ['SNOWFLAKE_USER', 'SNOWFLAKE_ACCOUNT', 'SNOWFLAKE_WAREHOUSE', 
                        'SNOWFLAKE_DATABASE', 'SNOWFLAKE_SCHEMA', 'CSV_DIR']
        missing_vars = [var for var in required_vars if not args.get(var)]
        if missing_vars:
            raise ValueError(f"Missing required environment variables: {missing_vars}")

        # Connect to Snowflake
        try:
            conn = snowflake.connector.connect(
                user=args['SNOWFLAKE_USER'],
                account=args['SNOWFLAKE_ACCOUNT'],
                warehouse=args['SNOWFLAKE_WAREHOUSE'],
                database=args['SNOWFLAKE_DATABASE'],
                role=args['SNOWFLAKE_ROLE'],
                schema=args['SNOWFLAKE_SCHEMA'],
                authenticator='externalbrowser'
            )
            logger.info("Connected to Snowflake successfully")
        except Exception as e:
            logger.error(f"Failed to connect to Snowflake: {e}")
            raise

        CSV_DIR = args['CSV_DIR']
        
        # Validate CSV directory exists
        if not os.path.exists(CSV_DIR):
            raise FileNotFoundError(f"CSV directory not found: {CSV_DIR}")

        LOCAL_STAGE = f"file://{CSV_DIR}"
        SNOWFLAKE_STAGE = "AOU_STAGE"
        FILE_FORMAT = "AOU_STAGE_FORMAT"
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

        # Read SQL file
        sql_path = Path('download_sample.sql')
        if not sql_path.is_file():
            raise FileNotFoundError(f"SQL file not found: {sql_path}")

        try:
            with open(sql_path, 'r') as sql_file:
                sql_content = sql_file.read()
            logger.info(f"SQL file {sql_path} loaded successfully")
        except Exception as e:
            logger.error(f"Failed to read SQL file {sql_path}: {e}")
            raise

        if not sql_content.strip():
            raise ValueError(f"SQL file {sql_path} is empty")

        # Apply Jinja2 templating
        try:
            template = Template(sql_content)
            rendered_sql = template.render(**kwargs)
            logger.info(f"SQL template rendered successfully")
        except Exception as e:
            logger.error(f"Failed to render SQL template: {e}")
            raise

        # Execute the SQL query
        cursor = conn.cursor()
        try:
            # Split the SQL into individual statements
            sql_statements = [stmt.strip() for stmt in rendered_sql.split(';') if stmt.strip()]
            
            for i, statement in enumerate(sql_statements, 1):
                logger.info(f"Executing statement {i}/{len(sql_statements)}")
                cursor.execute(statement)
                
            logger.info("All SQL statements executed successfully")
        except Exception as e:
            logger.error(f"Error executing SQL: {e} for statement:\n\n {statement}")
            raise
        finally:
            cursor.close()

        # Process CSV files
        csv_files = [f for f in os.listdir(CSV_DIR) if f.endswith('.csv')]
        if not csv_files:
            logger.warning(f"No CSV files found in directory: {CSV_DIR}")
            return

        logger.info(f"Found {len(csv_files)} CSV files to process")

        for filename in csv_files:
            file_path = os.path.join(CSV_DIR, filename)
            try:
                logger.info(f"Processing file: {file_path}")
                
                # Read the CSV file
                df = pd.read_csv(file_path)
                
                # Convert column names to lowercase
                original_columns = df.columns.tolist()
                df.columns = [col.lower() for col in df.columns]
                
                # Save the modified DataFrame back to CSV
                df.to_csv(file_path, quoting=csv.QUOTE_NONNUMERIC, index=False)
                
                logger.info(f"Successfully processed {filename}: {len(df)} rows, columns: {original_columns} -> {df.columns.tolist()}")
                
            except Exception as e:
                logger.error(f"Failed to process file {filename}: {e}")
                continue

        logger.info("CSV processing completed")

    except Exception as e:
        logger.error(f"Script failed with error: {e}")
        raise
    finally:
        # Close Snowflake connection if it exists
        try:
            if 'conn' in locals():
                conn.close()
                logger.info("Snowflake connection closed")
        except Exception as e:
            logger.error(f"Error closing Snowflake connection: {e}")

if __name__ == "__main__":
    main()
