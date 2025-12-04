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

# Define the DAG for OMOP data refresh
with DAG(
    "omop_data_refresh",
    default_args={
        "depends_on_past": False,
        "email_on_failure": False,
        "email_on_retry": False,
        "retries": 0,
        "retry_delay": None,
    },
    description="ohdsi atlas data refresh",
    start_date=None,
    catchup=False,
    tags=["omop_data_refresh"],
) as dag:
    # Load environment variables and set ENVIRONMENT as enum: 'sandbox', 'dev', or 'prod'
    ENVIRONMENT = 'gpc' # ['sandbox', 'dev', 'prod']
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
        'site': project
    }
    
    # Define paths
    BASE_PATH = '/opt/airflow/scripts'
    SQL_PATH = os.path.join(BASE_PATH, 'omop_cdm')
    UTILS_PATH = os.path.join(BASE_PATH, 'utils')
    
    file_path = os.path.join(SQL_PATH, 'table_mapping.json')
    table_mapping = extract_table_mapping_from_file(file_path, project)
    kwargs.update(table_mapping)

    ## CDM CLEANUP
    with TaskGroup('cdm_cleanup') as cdm_cleanup:
        clean_cdm_sql = read_sql_from_file(os.path.join(UTILS_PATH, 'cdm_cleanup.sql'), **kwargs)
        task = SnowflakeSqlApiOperator(
            task_id='cdm_cleanup_task',
            snowflake_conn_id=snowflake_conn_id,
            sql=clean_cdm_sql,
            trigger_rule=TriggerRule.ALL_SUCCESS,
            autocommit=True,
            retries=0
        )

    ## OMOP DATA REFRESH (TABLES)
    with TaskGroup('omop_tables') as omop_tables:
        sql_files = [f for f in sorted(os.listdir(SQL_PATH)) if f.endswith('.sql')]
        if not sql_files:
            raise FileNotFoundError(f"No SQL files found in directory: {SQL_PATH}")
        previous_task = None
        for filename in sql_files:
            sql_file_path = os.path.join(SQL_PATH, filename)
            read_sql = read_sql_from_file(sql_file_path, **kwargs)
            task = SnowflakeSqlApiOperator(
                    task_id=f"{get_task_id(sql_file_path)}",
                    snowflake_conn_id=snowflake_conn_id,
                    sql=read_sql,
                    trigger_rule=TriggerRule.ALL_SUCCESS,
                    autocommit=True,
                    retries=0
            )
            if previous_task:
                previous_task >> task 
            previous_task = task    
    ##TODO: run achilles and dqdashboard and upload results to s3 where webclient can access them as CDN
    ## UPDATE utils/ACHILLES_COUNT AND CLEAR WEBAPI DB CACHE
    ## cdm_cleanup >> omop_tables >> run_ares >> export_s3 >> achilles_count >> clear_webapi_cache
    cdm_cleanup >> omop_tables