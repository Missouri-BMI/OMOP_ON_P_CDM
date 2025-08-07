USE ROLE {{ omop_etl_role }};
CREATE DATABASE {{ cdm_db }};

GRANT OWNERSHIP ON DATABASE {{ cdm_db }} TO ROLE {{ omop_etl_role }} REVOKE CURRENT GRANTS;

USE DATABASE {{ cdm_db }};

CREATE SCHEMA {{ cdm_db }}.{{ cdm_schema }};
CREATE SCHEMA {{ cdm_db }}.results;
CREATE SCHEMA {{ cdm_db }}.temp;


GRANT USAGE ON DATABASE {{ cdm_db }} TO ROLE {{ omop_role }};
--usage on cdm
GRANT USAGE ON SCHEMA {{ cdm_db }}.{{ cdm_schema }} TO ROLE {{ omop_role }};
GRANT SELECT ON ALL TABLES IN SCHEMA {{ cdm_db }}.{{ cdm_schema }} TO ROLE {{ omop_role }};
GRANT SELECT ON ALL VIEWS IN SCHEMA {{ cdm_db }}.{{ cdm_schema }} TO ROLE {{ omop_role }};
GRANT SELECT ON FUTURE TABLES IN SCHEMA {{ cdm_db }}.{{ cdm_schema }} TO ROLE {{ omop_role }};
GRANT SELECT ON FUTURE VIEWS IN SCHEMA {{ cdm_db }}.{{ cdm_schema }} TO ROLE {{ omop_role }};

--usage on vocabulary
GRANT USAGE ON SCHEMA {{ cdm_db }}.vocabulary TO ROLE {{ omop_role }};
GRANT SELECT ON ALL TABLES IN SCHEMA {{ cdm_db }}.vocabulary TO ROLE {{ omop_role }};
GRANT SELECT ON FUTURE TABLES IN SCHEMA {{ cdm_db }}.vocabulary TO ROLE {{ omop_role }};

--access on results
GRANT USAGE ON SCHEMA {{ cdm_db }}.results TO ROLE {{ omop_role }};
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA {{ cdm_db }}.results TO ROLE {{ omop_role }};
GRANT SELECT, INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA {{ cdm_db }}.results TO ROLE {{ omop_role }};

--access on temp
GRANT USAGE ON SCHEMA {{ cdm_db }}.temp TO ROLE {{ omop_role }};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA {{ cdm_db }}.temp TO ROLE {{ omop_role }};
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA {{ cdm_db }}.temp TO ROLE {{ omop_role }};
GRANT CREATE TABLE ON SCHEMA {{ cdm_db }}.temp TO ROLE {{ omop_role }};

