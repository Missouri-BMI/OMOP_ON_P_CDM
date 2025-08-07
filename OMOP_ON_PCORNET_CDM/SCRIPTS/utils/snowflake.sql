USE ROLE accountadmin; 

CREATE ROLE IF NOT EXISTS {{ omop_role }};

//TODO: implement key-pair authentication
CREATE USER IF NOT EXISTS {{ omop_user }}
  PASSWORD = {{ omop_user_password }}  
  DEFAULT_ROLE = {{ omop_role }}
  DEFAULT_WAREHOUSE = {{ omop_wh }}
  ;

GRANT ROLE {{ omop_role }} TO USER {{ omop_user }};

-- 1. Create warehouse
CREATE WAREHOUSE IF NOT EXISTS {{ omop_wh }}
  WITH WAREHOUSE_SIZE = 'Small'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;


-- 4. Grant usage on warehouse to role
GRANT USAGE ON WAREHOUSE {{ omop_wh }} TO ROLE {{ omop_role }};
