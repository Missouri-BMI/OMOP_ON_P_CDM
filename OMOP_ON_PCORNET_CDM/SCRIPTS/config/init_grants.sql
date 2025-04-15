USE ROLE accountadmin;
USE WAREHOUSE omop_etl_wh;

CREATE DATABASE atlas_mu_prod;

GRANT OWNERSHIP ON DATABASE atlas_mu_prod TO ROLE omop_elt REVOKE CURRENT GRANTS;

USE ROLE omop_elt;

USE DATABASE atlas_mu_prod;

CREATE OR REPLACE SCHEMA cdm;
CREATE OR REPLACE SCHEMA vocabulary;
CREATE OR REPLACE SCHEMA results;
CREATE OR REPLACE SCHEMA temp;


CREATE ROLE IF NOT EXISTS omop_atlas_prod;

-- 2. Create warehouse
CREATE WAREHOUSE IF NOT EXISTS omop_atlas_prod_wh
  WITH WAREHOUSE_SIZE = medium
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- 3. Create user
CREATE USER IF NOT EXISTS SERVICE_USER_ATLAS_PROD
  PASSWORD = 'StrongTempPass#123'  -- Replace with a real secret
  DEFAULT_ROLE = omop_atlas_prod
  DEFAULT_WAREHOUSE = omop_atlas_prod_wh
  MUST_CHANGE_PASSWORD = TRUE;

CREATE USER IF NOT EXISTS ATLAS_ETL_USER
  PASSWORD = 'StrongTempPass#123'  -- Replace with a real secret
  DEFAULT_ROLE = omop_elt
  DEFAULT_WAREHOUSE = omop_etl_wh
  MUST_CHANGE_PASSWORD = TRUE;  

-- 4. Grant usage on warehouse to role
GRANT USAGE ON WAREHOUSE omop_atlas_prod_wh TO ROLE omop_atlas_prod;

GRANT ROLE omop_atlas_prod TO USER SERVICE_USER_ATLAS_PROD;
GRANT ROLE omop_elt TO USER ATLAS_ETL_USER;

USE DATABASE atlas_mu_prod;
--usage on cdm
GRANT USAGE ON SCHEMA cdm TO ROLE omop_atlas_prod;
GRANT SELECT ON ALL TABLES IN SCHEMA cdm TO ROLE omop_atlas_prod;
GRANT SELECT ON ALL VIEWS IN SCHEMA cdm TO ROLE omop_atlas_prod;
GRANT SELECT ON FUTURE TABLES IN SCHEMA cdm TO ROLE omop_atlas_prod;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA cdm TO ROLE omop_atlas_prod;

--usage on vocabulary
GRANT USAGE ON SCHEMA vocabulary TO ROLE omop_atlas_prod;
GRANT SELECT ON ALL TABLES IN SCHEMA vocabulary TO ROLE omop_atlas_prod; 
GRANT SELECT ON FUTURE TABLES IN SCHEMA vocabulary TO ROLE omop_atlas_prod;

--access on results
GRANT USAGE ON SCHEMA results TO ROLE omop_atlas_prod;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA results TO ROLE omop_atlas_prod;
GRANT SELECT, INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA results TO ROLE omop_atlas_prod;

--access on temp
GRANT USAGE ON SCHEMA temp TO ROLE omop_atlas_prod;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA temp TO ROLE omop_atlas_prod;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA temp TO ROLE omop_atlas_prod;
GRANT CREATE TABLE ON SCHEMA temp TO ROLE omop_atlas_prod;