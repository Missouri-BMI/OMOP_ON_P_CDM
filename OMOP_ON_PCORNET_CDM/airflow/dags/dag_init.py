import logging
import os
from airflow.models.dag import DAG
from airflow.utils.task_group import TaskGroup
from airflow.providers.snowflake.operators.snowflake import SnowflakeSqlApiOperator
from airflow.utils.trigger_rule import TriggerRule
from common import read_sql_from_file, get_task_id, extract_table_mapping_from_file
from dotenv import dotenv_values

# Initialize logger
logger = logging.getLogger(__name__)

# Define the DAG for OMOP data installation
with DAG(
    "omop_data_install",
    default_args={
        "depends_on_past": False,
        "email_on_failure": False,
        "email_on_retry": False,
        "retries": 0,
        "retry_delay": None,
    },
    description="omop database installation",
    start_date=None,
    catchup=False,
    tags=["omop_data_install"],
) as dag:
    
    # Load environment variables and set ENVIRONMENT as enum: 'sandbox', 'dev', or 'prod'
    ENVIRONMENT = 'dev' # ['sandbox', 'dev', 'prod']
    ACCOUNT = 'deidentified' # ['deidentified', 'identified']
    env_path = f"/opt/airflow/env/{ACCOUNT}/{ENVIRONMENT}/.env"

    # Extract variables from args
    args = dotenv_values(env_path)
    environment = args['ENVIRONMENT']
    assert ENVIRONMENT == environment, f"ENVIRONMENT ({ENVIRONMENT}) does not match environment ({environment}) from .env file"

    project = args['PROJECT']
    snowflake_conn_id = args['CONNECTION_ID']

    cdm_db = args['CDM_DB']
    cdm_schema = args['CDM_SCHEMA']
    crosswalk = args['CROSSWALK_SCHEMA']
    vocabulary = args['VOCABULARY_SCHEMA']
    
    pcornet_db = args['PCORNET_DB']
    pcornet_schema = args['PCORNET_SCHEMA']
    
    omop_role = args['OMOP_ROLE']
    omop_etl_role = args['OMOP_ETL_ROLE']
    omop_wh = args['OMOP_WH']
    omop_user = args['OMOP_USER']

    # Prepare SQL execution context
    kwargs = {
        'cdm_db': cdm_db,
        'cdm_schema': cdm_schema,
        'pcornet_db': pcornet_db,
        'pcornet_schema': pcornet_schema,
        'crosswalk': crosswalk,
        'vocabulary': vocabulary,
        'omop_role': omop_role,
        'omop_etl_role': omop_etl_role,
        'omop_wh': omop_wh,
        'omop_user': omop_user,
    }
    
    # Define paths
    BASE_PATH = '/opt/airflow/scripts'
    INIT_PATH = os.path.join(BASE_PATH, 'init')
    
    omop_cdm_sql = read_sql_from_file(os.path.join(INIT_PATH, 'grants','database.sql'), **kwargs)
    grants_task = SnowflakeSqlApiOperator(
        task_id='create_database_and_schema_task',
        snowflake_conn_id=snowflake_conn_id,
        sql=omop_cdm_sql,
        trigger_rule=TriggerRule.ALL_SUCCESS,
        autocommit=True,
        retries=0
    )
    
    # grants_task >> db_task >> R DDL >>  LOAD VOCABULARY >> LOAD CROSSWALK >> LOAD MAPPING >> LOAD UTIL/RESULTS
    
    ## set role, 
    ## clean up database,
    ## create database and schema,
    ## DATA_INSTALL.R (install_R_ENV.R if not already installed),