USE ROLE accountadmin; 

CREATE ROLE IF NOT EXISTS {{ omop_role }};

-- 2. Create warehouse
CREATE WAREHOUSE IF NOT EXISTS {{ omop_wh }}
  WITH WAREHOUSE_SIZE = 'Small'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- 3. Create users

CREATE USER IF NOT EXISTS {{ omop_user }}
  PASSWORD = 'StrongTempPass#123'  -- Replace with a real secret
  DEFAULT_ROLE = {{ omop_role }}
  DEFAULT_WAREHOUSE = {{ omop_wh }}
  MUST_CHANGE_PASSWORD = TRUE;

GRANT ROLE {{ omop_role }} TO USER {{ omop_user }};

-- 4. Grant usage on warehouse to role
GRANT USAGE ON WAREHOUSE {{ omop_wh }} TO ROLE {{ omop_role }};
GRANT ROLE {{ omop_role }} TO USER {{ omop_user }};

