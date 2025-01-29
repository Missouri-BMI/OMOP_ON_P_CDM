from datetime import datetime, timedelta
from airflow.models.dag import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup
from airflow.operators.empty import EmptyOperator
from airflow.operators.bash import BashOperator
from airflow.utils.trigger_rule import TriggerRule
from dotenv import dotenv_values
from common import *

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
    
    snowflake_conn_id = 'mu-dev'
    args = dotenv_values("/opt/airflow/env/dev/mu/.env")
    
    cdm_db = args['CDM_DB']
    cdm_schema = args['CDM_SCHEMA']
    pcornet_db = args['PCORNET_DB']
    pcornet_schema = args['PCORNET_SCHEMA']
    crosswalk = args['CROSSWALK_SCHEMA']
    vocabulary = args['VOCABULARY_SCHEMA']
    project = args['PROJECT']
    environment = args['ENVIRONMENT']
    
    SQL_PATH = os.path.join('/opt/airflow/SCRIPTS/omop_cdm', project)
    # CRC_CONCEPT_PATH = f"{BASE_PATH}/i2b2-data/edu.harvard.i2b2.data/Release_1-8/NewInstall/Crcdata/act/scripts/snowflake"
    # CONCEPT_EXPORT_PATH=f"file://{CRC_CONCEPT_PATH}"
    
    # TSV_FORMAT = 'TSV_FORMAT'
    # TSV_STAGE = 'i2b2_ont_import_tsv'
    # DSV_FORMAT = 'DSV_FORMAT'
    # DSV_STAGE = 'i2b2_ont_import_dsv'

    # ENACT_PATH = f"{BASE_PATH}/ACT_V4_LOADER"
    # ENACT_DATA = f"{ENACT_PATH}/ENACT_V41_POSTGRES_I2B2_TSV"
 
    # LOCAL_STAGE=f"file://{ENACT_DATA}"
    # PUT_PARAMETERS="PARALLEL=4 AUTO_COMPRESS=TRUE SOURCE_COMPRESSION=AUTO_DETECT OVERWRITE=TRUE"
    
   
    kwargs = {
        'cdm_db': cdm_db,
        'cdm_schema': cdm_schema,
        'pcornet_db': pcornet_db,
        'pcornet_schema': pcornet_schema,
        'crosswalk': crosswalk,
        'vocabulary': vocabulary,
    }
    
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
    with TaskGroup('run_achilles') as run_achilles:
        print('run_achilles')

    with TaskGroup('run_dq_dashboard') as run_dq_dashboard:
        print('run_dq_dashboard')

    with TaskGroup('run_aoh_dq') as run_aoh_dq:
        print('run_aoh_dq')

    create_conn_task >> omop_views >> run_achilles >> run_dq_dashboard >> run_aoh_dq