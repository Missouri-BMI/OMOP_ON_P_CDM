from datetime import datetime, timedelta
from airflow.models.dag import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup
from airflow.operators.empty import EmptyOperator
from airflow.operators.bash import BashOperator
from airflow.utils.trigger_rule import TriggerRule
from dotenv import dotenv_values
from common import *
import json

def extract_table_mapping_from_file(filename, project_key):
    with open(filename, 'r') as f:
        data = json.load(f)
    
    return {
        table: values.get(project_key)
        for table, values in data.get("tables", {}).items()
        if project_key in values
    }

with DAG(
    "omop_data_refresh",
    # These args will get passed on to each operator
    # You can override them on a per-task basis during operator initialization
    default_args={
        "depends_on_past": False,
        "email": ["mhmcb@missouri.edu"],
        "email_on_failure": False,
        "email_on_retry": False,
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
    },
    description="ohdsi atlas data refresh",
    schedule=None,
    start_date=datetime(2021, 1, 1),
    catchup=False,
    tags=["omop_data_refresh"],
) as dag:
    
    snowflake_conn_id = 'mu-sandbox'
    args = dotenv_values("/opt/airflow/env/sandbox/mu/.env")
    
    cdm_db = args['CDM_DB']
    cdm_schema = args['CDM_SCHEMA']
    pcornet_db = args['PCORNET_DB']
    pcornet_schema = args['PCORNET_SCHEMA']
    crosswalk = args['CROSSWALK_SCHEMA']
    vocabulary = args['VOCABULARY_SCHEMA']
    project = args['PROJECT']
    environment = args['ENVIRONMENT']
    
    BASE_PATH = '/opt/airflow/SCRIPTS'
    SQL_PATH = os.path.join(BASE_PATH, 'omop_cdm')
    ACHILLES_PATH = os.path.join(BASE_PATH, 'analysis', 'Achilles','perform_achilles_analysis.R')
    CACHE_ACHILLES_PATH = os.path.join(BASE_PATH, 'analysis', 'Achilles','achilles_cache.sql')
   
    kwargs = {
        'cdm_db': cdm_db,
        'cdm_schema': cdm_schema,
        'pcornet_db': pcornet_db,
        'pcornet_schema': pcornet_schema,
        'crosswalk': crosswalk,
        'vocabulary': vocabulary,
    }

    file_path = os.path.join(SQL_PATH, 'table_mapping.json')
    table_mapping = extract_table_mapping_from_file(file_path, project)
    kwargs.update(table_mapping)

    create_conn_task = PythonOperator(
        task_id='connect',
        python_callable=create_snowflake_connection,
        op_args=[snowflake_conn_id, args]
    )

    with TaskGroup('omop_views') as omop_views:
        execute_sql_directory(
            snowflake_conn_id, 
            SQL_PATH, 
            False, 
            **kwargs
        )
  
    create_conn_task >> omop_views
