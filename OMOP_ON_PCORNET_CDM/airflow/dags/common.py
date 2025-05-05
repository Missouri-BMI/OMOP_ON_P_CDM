from airflow.utils.session import provide_session
from airflow.models import connection
from sqlalchemy.orm import Session
from airflow.models import Connection
from pathlib import Path
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
import os
import sqlparse
from airflow.decorators import task
from airflow.utils.trigger_rule import TriggerRule
from airflow.utils.task_group import TaskGroup
from typing import List
from jinja2 import Template

@provide_session
def create_snowflake_connection(conn_id, conn_params, session: Session =None):
    # Check if the connection already exists
    existing_conn = session.query(Connection).filter(Connection.conn_id == conn_id).first()
    if existing_conn:
        print(f"Connection '{conn_id}' already exists.")
    else:
        con = connection.Connection(
            conn_id=conn_id,
            conn_type='snowflake',
            login=conn_params['USERNAME'],
            password=conn_params['PASSWORD'],
            schema=conn_params['CDM_SCHEMA'],
            extra=f"""{{
                "account": "{conn_params['ACCOUNT']}",
                "database": "{conn_params['CDM_DB']}",
                "warehouse": "{conn_params['WAREHOUSE']}",
                "role": "{conn_params['ROLE']}"
            }}"""    
        )
        session.add(con)
        session.commit()
        print(f"Connection '{conn_id}' created successfully.")

@task(retries=0)
def read_sql_from_file(file_path: str, **kwargs) -> List[str]:

    # Read SQL file from the specified directory
    sql_path = Path(file_path)
    if not sql_path.is_file():
        raise FileNotFoundError(f"SQL file not found: {file_path}")

    # Read the content of the SQL file
    with open(sql_path, 'r') as sql_file:
        sql_content = sql_file.read()

    if not sql_content.strip():
        raise ValueError(f"SQL file {file_path} is empty")

    # Apply Jinja2 templating
    template = Template(sql_content)
    rendered_sql = template.render(**kwargs)

    # Split and format the SQL statements
    sql_statements = sqlparse.split(rendered_sql)
    formatted_sql = [statement.strip() for statement in sql_statements]
    return formatted_sql

@task(retries=0)  
def add_schema_sql(schema, sql_text) -> str:
    return f"use schema {schema};\n" + sql_text
    
# Task to execute SQL using SnowflakeOperator
def execute_sql(conn_id, task_id, sql_query: str, trigger_rule=TriggerRule.ALL_SUCCESS, autocommit = True, retries = 0):
    return SnowflakeOperator(
        task_id=task_id,
        snowflake_conn_id=conn_id,
        sql=sql_query,
        trigger_rule=trigger_rule,
        autocommit=autocommit,
        retries=retries
    )

def get_task_id(file_path):
    filename = Path(file_path).stem
    return f'execute_{filename.split(".")[0]}'   

def execute_sql_directory(conn_id, sql_directory: str, sequentially: bool, **kwargs) -> str:
    tasks = []
    sql_files = [f for f in sorted(os.listdir(sql_directory)) if f.endswith('.sql')]
    
    if not sql_files:
        raise FileNotFoundError(f"No SQL files found in directory: {sql_directory}")
    
    for filename in sql_files:
        with TaskGroup(Path(filename).stem) as sub_group:
            sql_file_path = os.path.join(sql_directory, filename)
            read_sql = read_sql_from_file(sql_file_path, **kwargs)
            sql_task = execute_sql(conn_id, get_task_id(sql_file_path), read_sql)
            read_sql >> sql_task
        
        tasks.append(sub_group)

    if sequentially:
        for i in range(len(tasks) - 1):
            tasks[i] >> tasks[i + 1]

