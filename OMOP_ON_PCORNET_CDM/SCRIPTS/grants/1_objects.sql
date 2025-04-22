USE ROLE accountadmin; 
USE WAREHOUSE omop_etl_wh;

CREATE ROLE IF NOT EXISTS omop_atlas_sandbox;

-- 2. Create warehouse
CREATE WAREHOUSE IF NOT EXISTS omop_atlas_sandbox_wh
  WITH WAREHOUSE_SIZE = 'Small'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- 3. Create users

CREATE USER IF NOT EXISTS ATLAS_ELT_USER
  PASSWORD = 'XGU$4<uf}H#8}3N'  -- Replace with a real secret
  DEFAULT_ROLE = omop_elt
  DEFAULT_WAREHOUSE = omop_etl_wh
  MUST_CHANGE_PASSWORD = TRUE;

GRANT ROLE omop_elt TO USER ATLAS_ELT_USER;

CREATE USER IF NOT EXISTS SERVICE_USER_ATLAS_SANDBOX
  PASSWORD = 'StrongTempPass#123'  -- Replace with a real secret
  DEFAULT_ROLE = omop_atlas_sandbox
  DEFAULT_WAREHOUSE = omop_atlas_sandbox_wh
  MUST_CHANGE_PASSWORD = TRUE;


-- 4. Grant usage on warehouse to role
GRANT USAGE ON WAREHOUSE omop_atlas_sandbox_wh TO ROLE omop_atlas_sandbox;
GRANT ROLE omop_atlas_sandbox TO USER SERVICE_USER_ATLAS_SANDBOX;

