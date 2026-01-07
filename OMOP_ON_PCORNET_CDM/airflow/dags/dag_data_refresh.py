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
SQL_PATH = os.path.join(BASE_PATH, "omop_cdm")
UTILS_PATH = os.path.join(BASE_PATH, "utils")
MAPPING_PATH = os.path.join(SQL_PATH, "table_mapping.json")

DEFAULT_SCHEDULE = os.getenv("OMOP_REFRESH_SCHEDULE", None)  # e.g. "0 2 * * *" or None for manual
DEFAULT_START_DATE = pendulum.datetime(2025, 1, 1, tz="UTC")  # fixed start date (best practice)

# Optional filters to reduce DAG explosion in certain deployments
FILTER_ACCOUNTS = set(x.strip() for x in os.getenv("OMOP_FILTER_ACCOUNTS", "").split(",") if x.strip())
FILTER_ENVS = set(x.strip() for x in os.getenv("OMOP_FILTER_ENVS", "").split(",") if x.strip())
FILTER_SITES = set(x.strip() for x in os.getenv("OMOP_FILTER_SITES", "").split(",") if x.strip())

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

    Reads only small non-secret config at parse time.
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

                site = fname[:-4]  # filename without .env
                if not _should_include(account, environment, site):
                    continue

                env_path = os.path.join(env_dir, fname)
                raw = dotenv_values(env_path)
                values = {k: str(v) for k, v in raw.items() if v is not None}

                missing = [k for k in REQUIRED_KEYS if not values.get(k)]
                if missing:
                    # Do not raise here; allow other DAGs to register
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

    mapping = extract_table_mapping_from_file(MAPPING_PATH, effective_site)
    if not mapping:
        raise ValueError(
            f"No table mapping found for site '{effective_site}' "
            f"(account={cfg.account}, original_site={cfg.site})"
        )

    kwargs.update(mapping)
    return kwargs


def _list_sql_files(sql_dir: str) -> List[str]:
    if not os.path.isdir(sql_dir):
        raise FileNotFoundError(f"SQL directory does not exist: {sql_dir}")

    files = [f for f in sorted(os.listdir(sql_dir)) if f.endswith(".sql")]
    if not files:
        raise FileNotFoundError(f"No .sql files found in directory: {sql_dir}")
    return files


def build_dag(cfg: RunConfig) -> Optional[DAG]:
    """
    Build a single DAG. If something is invalid for this cfg,
    return None so other DAGs still load.
    """
    try:
        v = cfg.values
        effective_site = resolve_site(cfg.account, cfg.site)

        dag_id = f"omop_data_refresh__{cfg.account}__{cfg.environment}__{effective_site}"
        snowflake_conn_id = v["CONNECTION_ID"]

        schedule = v.get("SCHEDULE", DEFAULT_SCHEDULE)  # allow per-config override
        start_date = DEFAULT_START_DATE

        dag = DAG(
            dag_id=dag_id,
            description=f"OMOP refresh ({cfg.account}/{cfg.environment}/{effective_site})",
            schedule=schedule,
            start_date=start_date,
            catchup=False,
            max_active_runs=1,  # avoids overlapping refreshes per site
            tags=["omop_data_refresh", cfg.account, cfg.environment, effective_site],
            default_args={
                "depends_on_past": False,
                "email_on_failure": False,
                "email_on_retry": False,
                "retries": 0,
            },
        )

        kwargs = _build_kwargs(cfg)
        sql_files = _list_sql_files(SQL_PATH)

        with dag:
            # ---- CDM CLEANUP ----
            with TaskGroup(group_id="cdm_cleanup") as cdm_cleanup:
                clean_sql = read_sql_from_file(os.path.join(UTILS_PATH, "cdm_cleanup.sql"), **kwargs)
                SnowflakeSqlApiOperator(
                    task_id="cdm_cleanup_task",
                    snowflake_conn_id=snowflake_conn_id,
                    sql=clean_sql,
                    trigger_rule=TriggerRule.ALL_SUCCESS,
                    autocommit=True,
                )

            # ---- OMOP TABLES ----
            with TaskGroup(group_id="omop_tables") as omop_tables:
                prev = None
                for filename in sql_files:
                    path = os.path.join(SQL_PATH, filename)
                    rendered = read_sql_from_file(path, **kwargs)

                    task = SnowflakeSqlApiOperator(
                        task_id=get_task_id(path),
                        snowflake_conn_id=snowflake_conn_id,
                        sql=rendered,
                        trigger_rule=TriggerRule.ALL_SUCCESS,
                        autocommit=True,
                    )

                    if prev:
                        prev >> task
                    prev = task

            cdm_cleanup >> omop_tables

            # TODO:
            # cdm_cleanup >> omop_tables >> run_ares >> export_s3 >> achilles_count >> clear_webapi_cache
            # webapi.achilles_cache;
            # webapi.cdm_cache;
            # results_schema.cohort_cache;

        return dag

    except Exception:
        logger.exception("Failed to build DAG for config: %s", cfg.env_path)
        return None


# --------- register DAGs ---------
_configs = discover_configs(BASE_ENV_DIR)
if not _configs:
    logger.warning("No OMOP env configs found under %s", BASE_ENV_DIR)

for _cfg in _configs:
    _dag = build_dag(_cfg)
    if _dag:
        globals()[_dag.dag_id] = _dag
