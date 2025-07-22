# OMOP_ON_P_CDM
This repository contains Snowflake source code to convert PCORnet CDM (Common Data Model) to OMOP CDM.


## OMOP_ON_PCORNET_CDM

This repository supports the installation and management of the OMOP CDM database, including tables and schemas, on top of the PCORnet CDM in Snowflake. It enables data refreshes from PCORnet CDM into OMOP CDM.
Additionally, the repository provides integration with OHDSI tools for analysis, including Achilles, Data Quality Dashboard (DQDashboard), All-of-Us, and WebAPI.

The `Makefile` in this repository provides several commands to streamline the setup and management of the OMOP on PCORnet CDM environment. Below are the available targets:

- **Build Stack**  
    The `make build` target checks for the presence of the `docker-compose.yaml` file. If it doesn't exist, it downloads the file from the official Apache Airflow documentation.

- **Start Airflow Services**  
    The `make deploy` target starts all Airflow services using Docker Compose.



### AIRFLOW DAGs:
- INIT:
- CREATE DATABASE;
- CREATE SCHEMA CDM, RESULTS, TEMP, VOCABULARY(CDM);
- GENERATE DDL using R

### DATA REFRESH:
- CDM REFRESH
- ARES ANALYSIS and EXPORT RESULT TO S3

### Airflow sample connection

```
#!/bin/bash

# Declare Snowflake connection variables
USERNAME="ATLAS_ETL_USER"
ACCOUNT="TKNLTGA-I2B2DB.snowflakecomputing.com"
WAREHOUSE="OMOP_ETL_WH"
ROLE="OMOP_ELT"
PRIVATE_KEY_FILE="/opt/airflow/env/rsa_key.p8"
PASSWORD=""

#sandbox
SANDBOX_CDM_SCHEMA="CDM"
SANDBOX_CDM_DB="atlas_mu_sandbox"
airflow connections add 'snowflake_conn_sandbox' \
    --conn-type 'snowflake' \
    --conn-login "${USERNAME}" \
    --conn-password "${PASSWORD}" \
    --conn-schema "${SANDBOX_CDM_SCHEMA}" \
    --conn-extra "{\"account\": \"${ACCOUNT}\", \"database\": \"${SANDBOX_CDM_DB}\", \"warehouse\": \"${WAREHOUSE}\", \"role\": \"${ROLE}\", \"private_key_file\": \"${PRIVATE_KEY_FILE}\"}"

#dev
DEV_CDM_SCHEMA="CDM"
DEV_CDM_DB="atlas_mu_dev"
airflow connections add 'snowflake_conn_dev' \
    --conn-type 'snowflake' \
    --conn-login "${USERNAME}" \
    --conn-password "${PASSWORD}" \
    --conn-schema "${DEV_CDM_SCHEMA}" \
    --conn-extra "{\"account\": \"${ACCOUNT}\", \"database\": \"${DEV_CDM_DB}\", \"warehouse\": \"${WAREHOUSE}\", \"role\": \"${ROLE}\", \"private_key_file\": \"${PRIVATE_KEY_FILE}\"}"


#prod
PROD_CDM_SCHEMA="CDM"
PROD_CDM_DB="atlas_mu_prod"
airflow connections add 'snowflake_conn_prod' \
    --conn-type 'snowflake' \
    --conn-login "${USERNAME}" \
     --conn-password "${PASSWORD}" \
    --conn-schema "${PROD_CDM_SCHEMA}" \
    --conn-extra "{\"account\": \"${ACCOUNT}\", \"database\": \"${PROD_CDM_DB}\", \"warehouse\": \"${WAREHOUSE}\", \"role\": \"${ROLE}\", \"private_key_file\": \"${PRIVATE_KEY_FILE}\"}"


echo "✅ Airflow connections created!"
```


### OMOP_SERVERLESS

This repository provides Docker configurations to build and deploy key OHDSI tools—including Atlas, WebAPI, ARES etc in containerized environments. 


The `Makefile` also includes commands for managing serverless deployments and Docker images for Atlas and WebAPI. Below are the key targets:

- **AWS Login**  
    Use `make aws-login-dev` or `aws-login-prod` to log in to AWS using the appropriate profile.

- **Docker Login**  
    Use `make docker-login-dev` or `docker-login-prod` to authenticate Docker with AWS Elastic Container Registry (ECR).

- **Build Docker Images for Atlas**  
    Use `make atlas-dev` or `atlas-prod` to build Docker images for Atlas with the appropriate WebAPI URL.

- **Build Docker Images for WebAPI**  
    Use `make webapi-dev` or `webapi-prod` to build Docker images for WebAPI with the specified environment (dev or prod).

# User Flow
1. Login to aws application-web-prod
2. Launch ec2 instance 'ohds-postgresql-cli'
3. Connect to ecs2 instance using session manager
4. Connect RDS postgres 
  ```
  psql -h ohdsi-webapi.chmnhhv9fwkb.us-east-2.rds.amazonaws.com -U postgres -d ohdsi_webapi -p 5432
  ```
5. Add users
```

-- Add user to security user
insert into webapi.sec_user(login, name) values
('mhmcb@umsystem.edu', 'Md Saber Hossain'),
('jcmwfn@umsystem.edu', 'James McClay');

-- create user role
insert into webapi.sec_role(name,system_role) values
('mhmcb@umsystem.edu', false),
('jcmwfn@umsystem.edu', false);

-- assign user roles to users
with new_users as (
  select id as user_id, login from webapi.sec_user
  where login in (
    'mhmcb@umsystem.edu',
    'jcmwfn@umsystem.edu'
  )
),
user_role as (
  select su.id as user_id, sr.id as role_id from webapi.sec_user  as su
  join webapi.sec_role as sr
  on su.login = sr.name
  where login in (
    'mhmcb@umsystem.edu',
    'jcmwfn@umsystem.edu'
  )
)
insert into webapi.sec_user_role (user_id, role_id)
select user_id, 1 from new_users --public
union
select user_id, 3 from new_users
union
select user_id, 5 from new_users
union 
select user_id, 6 from new_users
union
select user_id, 10 from new_users -- ATLAS user
union
select user_id, 1004 from new_users --MU SOURCE
union 
select user_id, role_id from user_role
--union
--select user_id, 1000 from new_users --moderator
--union
--select user_id, 2 from new_users --admin
;
```

5a. Stored procedure to add users
```
CREATE OR REPLACE PROCEDURE webapi.add_sec_users_batch(
  IN logins TEXT[],
  IN names TEXT[],
  IN is_admin BOOLEAN[]
)
LANGUAGE plpgsql
AS $$
DECLARE
  i INT;
  uid INT;
  rid INT;
BEGIN
  FOR i IN 1 .. array_length(logins, 1) LOOP
    -- Insert user
    INSERT INTO webapi.sec_user(login, name)
    SELECT logins[i], names[i]
    WHERE NOT EXISTS (
      SELECT 1 FROM webapi.sec_user WHERE login = logins[i]
    );

    -- Insert matching role
    INSERT INTO webapi.sec_role(name, system_role)
    SELECT logins[i], FALSE
    WHERE NOT EXISTS (
      SELECT 1 FROM webapi.sec_role WHERE name = logins[i]
    );

    -- Retrieve IDs
    SELECT id INTO uid FROM webapi.sec_user WHERE login = logins[i];
    SELECT id INTO rid FROM webapi.sec_role WHERE name = logins[i];

    -- Assign base roles
    INSERT INTO webapi.sec_user_role(user_id, role_id)
    SELECT uid, role_id FROM (
      VALUES (1), (3), (5), (6), (10), (1004), (rid)
    ) AS r(role_id)
    WHERE NOT EXISTS (
      SELECT 1 FROM webapi.sec_user_role WHERE user_id = uid AND role_id = r.role_id
    );

    -- Assign moderator (1000) and admin (2) if admin flag is true
    IF is_admin[i] THEN
      INSERT INTO webapi.sec_user_role(user_id, role_id)
      SELECT uid, role_id FROM (
        VALUES (1000), (2)
      ) AS r(role_id)
      WHERE NOT EXISTS (
        SELECT 1 FROM webapi.sec_user_role WHERE user_id = uid AND role_id = r.role_id
      );
    END IF;
  END LOOP;
END;
$$;

```
5b. Stored procedure to remove user:
```
CREATE OR REPLACE PROCEDURE webapi.remove_sec_users_batch(
  IN logins TEXT[]
)
LANGUAGE plpgsql
AS $$
DECLARE
  i INT;
  uid INT;
  rid INT;
BEGIN
  FOR i IN 1 .. array_length(logins, 1) LOOP
    -- Get user and role IDs
    SELECT id INTO uid FROM webapi.sec_user WHERE login = logins[i];
    SELECT id INTO rid FROM webapi.sec_role WHERE name = logins[i];

    -- Remove user role mappings (if user ID is found)
    IF uid IS NOT NULL THEN
      DELETE FROM webapi.sec_user_role WHERE user_id = uid;
    END IF;

    -- Remove personal role (if role ID is found)
    IF rid IS NOT NULL THEN
      DELETE FROM webapi.sec_role WHERE id = rid;
    END IF;
  END LOOP;
END;
$$;

```
5c. Usage 
```
CALL webapi.add_sec_users_batch(
  ARRAY['mhmcb@umsystem.edu', 'jcmwfn@umsystem.edu'],
  ARRAY['Md Saber Hossain', 'James McClay'],
  ARRAY[true, false]
);

CALL webapi.remove_sec_users_batch(
  ARRAY['mhmcb@umsystem.edu', 'jcmwfn@umsystem.edu']
);

```

6. Shutdown the ec2 instance
