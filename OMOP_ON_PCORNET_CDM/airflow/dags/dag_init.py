import logging
import os
from dataclasses import dataclass
from typing import Dict, List, Optional

import pendulum
from airflow.models.dag import DAG
from airflow.utils.task_group import TaskGroup
from airflow.utils.trigger_rule import TriggerRule
from airflow.providers.snowflake.operators.snowflake import SnowflakeSqlApiOperator
from dotenv import dotenv_values

from common import read_sql_from_file, get_task_id, resolve_site, extract_table_mapping_from_file

logger = logging.getLogger(__name__)

# --------- constants ---------
BASE_ENV_DIR = os.getenv("OMOP_ENV_BASE_DIR", "/opt/airflow/env")

BASE_PATH = "/opt/airflow/scripts"
INIT_PATH = os.path.join(BASE_PATH, "init")
MAPPING_PATH = os.path.join(BASE_PATH, "omop_cdm", "table_mapping.json")

DEFAULT_SCHEDULE = os.getenv("OMOP_INSTALL_SCHEDULE", None)  # optional; often manual
DEFAULT_START_DATE = pendulum.datetime(2025, 1, 1, tz="UTC")

# Optional filters to reduce DAG explosion in certain deployments
FILTER_ACCOUNTS = set(x.strip() for x in os.getenv("OMOP_FILTER_ACCOUNTS", "").split(",") if x.strip())
FILTER_ENVS = set(x.strip() for x in os.getenv("OMOP_FILTER_ENVS", "").split(",") if x.strip())
FILTER_SITES = set(x.strip() for x in os.getenv("OMOP_FILTER_SITES", "").split(",") if x.strip())

# .env no longer requires PROJECT/ENVIRONMENT; those are derived from folder+filename
REQUIRED_KEYS = [
    "CONNECTION_ID",
    "CDM_DB", "CDM_SCHEMA",
    "PCORNET_DB", "PCORNET_SCHEMA",
    "CROSSWALK_SCHEMA", "VOCABULARY_SCHEMA",
    "OMOP_ROLE", "OMOP_ETL_ROLE", "OMOP_WH", "OMOP_USER",
]


@dataclass(frozen=True)
class RunConfig:
    account: str          # identified|deidentified (derived from folder)
    environment: str      # sandbox|dev|prod (derived from folder)
    site: str             # base site key from filename (e.g., mu, gpc)
    env_path: str
    values: Dict[str, str]


def _should_include(account: str, environment: str, site: str) -> bool:
    if FILTER_ACCOUNTS and account not in FILTER_ACCOUNTS:
        return False
    if FILTER_ENVS and environment not in FILTER_ENVS:
        return False
    if FILTER_SITES and site not in FILTER_SITES:
        return False
    return True


def discover_configs(base_env_dir: str) -> List[RunConfig]:
    """
    Discover env files in:
      {base_env_dir}/{account}/{environment}/{site}.env
    """
    configs: List[RunConfig] = []

    for account in ("identified", "deidentified"):
        account_dir = os.path.join(base_env_dir, account)
        if not os.path.isdir(account_dir):
            continue

        for environment in ("sandbox", "dev", "prod"):
            env_dir = os.path.join(account_dir, environment)
            if not os.path.isdir(env_dir):
                continue

            for fname in sorted(os.listdir(env_dir)):
                if not fname.endswith(".env"):
                    continue

                site = fname[:-4]
                if not _should_include(account, environment, site):
                    continue

                env_path = os.path.join(env_dir, fname)
                raw = dotenv_values(env_path)
                values = {k: str(v) for k, v in raw.items() if v is not None}

                missing = [k for k in REQUIRED_KEYS if not values.get(k)]
                if missing:
                    logger.error("Skipping config %s (missing keys: %s)", env_path, missing)
                    continue

                configs.append(RunConfig(account, environment, site, env_path, values))

    return configs


def _build_kwargs(cfg: RunConfig) -> Dict[str, str]:
    v = cfg.values
    effective_site = resolve_site(cfg.account, cfg.site)

    kwargs = {
        "cdm_db": v["CDM_DB"],
        "cdm_schema": v["CDM_SCHEMA"],
        "pcornet_db": v["PCORNET_DB"],
        "pcornet_schema": v["PCORNET_SCHEMA"],
        "crosswalk": v["CROSSWALK_SCHEMA"],
        "vocabulary": v["VOCABULARY_SCHEMA"],
        "omop_role": v["OMOP_ROLE"],
        "omop_etl_role": v["OMOP_ETL_ROLE"],
        "omop_wh": v["OMOP_WH"],
        "omop_user": v["OMOP_USER"],
        "site": effective_site, 
    }

    # If your init SQL depends on mapping values, keep this.
    # If not required for install, you can remove mapping entirely.
    mapping = extract_table_mapping_from_file(MAPPING_PATH, effective_site)
    if mapping:
        kwargs.update(mapping)

    return kwargs


def build_dag(cfg: RunConfig) -> Optional[DAG]:
    """
    Build one DAG per config for OMOP data installation.
    """
    try:
        v = cfg.values
        effective_site = resolve_site(cfg.account, cfg.site)

        dag_id = f"omop_data_install__{cfg.account}__{cfg.environment}__{effective_site}"
        snowflake_conn_id = v["CONNECTION_ID"]

        schedule = v.get("SCHEDULE", DEFAULT_SCHEDULE)
        start_date = DEFAULT_START_DATE

        dag = DAG(
            dag_id=dag_id,
            description=f"OMOP database installation ({cfg.account}/{cfg.environment}/{effective_site})",
            schedule=schedule,
            start_date=start_date,
            catchup=False,
            max_active_runs=1,
            tags=["omop_data_install", cfg.account, cfg.environment, effective_site],
            default_args={
                "depends_on_past": False,
                "email_on_failure": False,
                "email_on_retry": False,
                "retries": 0,
            },
        )

        kwargs = _build_kwargs(cfg)

        with dag:
            # Example: create database + schema + grants
            omop_cdm_sql = read_sql_from_file(
                os.path.join(INIT_PATH, "grants", "database.sql"),
                **kwargs,
            )

            grants_task = SnowflakeSqlApiOperator(
                task_id="create_database_and_schema_task",
                snowflake_conn_id=snowflake_conn_id,
                sql=omop_cdm_sql,
                trigger_rule=TriggerRule.ALL_SUCCESS,
                autocommit=True,
                retries=0,
            )

            # TODO: extend the install pipeline (kept as your notes)
            # grants_task >> db_task >> ddl_tasks >> load_vocab >> load_crosswalk >> load_mapping >> load_utils_results
            #
            # - set role
            # - clean up database
            # - create database and schema
            # - DATA_INSTALL.R (install_R_ENV.R if not already installed)

        return dag

    except Exception:
        logger.exception("Failed to build install DAG for config: %s", cfg.env_path)
        return None


# --------- register DAGs ---------
_configs = discover_configs(BASE_ENV_DIR)
if not _configs:
    logger.warning("No OMOP env configs found under %s", BASE_ENV_DIR)

for _cfg in _configs:
    _dag = build_dag(_cfg)
    if _dag:
        globals()[_dag.dag_id] = _dag
