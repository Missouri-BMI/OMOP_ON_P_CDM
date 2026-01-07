from pathlib import Path
from datetime import datetime, timedelta
import json
from jinja2 import Template
from typing import List
import sqlparse 

def get_task_id(file_path):
    filename = Path(file_path).stem
    return f'execute_{filename.split(".")[0]}'   

def read_sql_from_file(file_path: str, **kwargs) -> str:
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
    return rendered_sql

def resolve_site(account: str, site: str) -> str:
    """
    Resolve the effective site identifier used everywhere (SQL context + table_mapping.json key).

    Rules:
      - deidentified -> mu, gpc (no suffix)
      - identified   -> mu-id (suffix)
    """
    if account == "identified" and site == "mu":
        return f"{site}-id"
    return site


def extract_table_mapping_from_file(filename, project_key):
    with open(filename, 'r') as f:
        data = json.load(f)
    
    return {
        table: values.get(project_key)
        for table, values in data.get("tables", {}).items()
        if project_key in values
    }