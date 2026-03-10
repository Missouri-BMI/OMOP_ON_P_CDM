# OMOP_ON_P_CDM

This repository offers tools and resources for converting PCORnet CDM data to OMOP CDM within Snowflake and AWS. It supports ETL processes and integrates with OHDSI analytical tools. Included are setup instructions for Airflow-based pipelines, environment configuration, and Dockerized deployments of OHDSI applications such as Atlas, WebAPI, ARES, Achilles, and more.

## OMOP_ON_PCORNET_CDM

OMOP CDM is implemented from the PCORnet CDM, enabling OMOP tables and schemas to be defined as views or tables on top of PCORnet data in Snowflake. This repository offers OMOP data install, refreshes and integration with OHDSI tools like Atlas, Achilles, Data Quality Dashboard (DQDashboard), and ARES.

### Project Configuration

#### Add Airflow Connections

To configure Airflow for Snowflake environments, create a `connections.sh` script in the `env/` directory:
Structure for managing environment variables in local directory:
The `env/` directory is structured to manage environment-specific configuration files and secrets for both deidentified and identified data environments. Example structure:

```
env/
  [deidentified, identified]/
    [dev, prod, sandbox]/
        mu.env,gpc.env,mu-id.env              # Environment variables for deidentified dev
    connections.sh        # Airflow connection script 
    rsa_key.p8            # Private key for Snowflake authentication
```

- Place your environment variable files (e.g., `.env`) in the appropriate subdirectory (`dev` for development, `prod` for production).
- connection scripts run on make build and store in the db using api
- Store your Snowflake private key as `rsa_key.p8` in the corresponding directory.

Sample connection.sh
```bash
#!/bin/bash
set -euo pipefail

# -----------------------------
# Global Snowflake parameters
# -----------------------------
USERNAME="${SNOWFLAKE_USERNAME:-ATLAS_ETL_USER}"
ACCOUNT="TKNLTGA-I2B2DB"
WAREHOUSE="OMOP_ETL_WH"
ROLE="OMOP_ELT"
PRIVATE_KEY_FILE="/opt/airflow/env/deidentified/rsa_key.p8"


PASSWORD="${SNOWFLAKE_PASSWORD:-your_pass}"

CDM_SCHEMA="CDM"

# -----------------------------
# Helper function
# -----------------------------
create_snowflake_conn () {
  local conn_id="$1"
  local database="$2"

  echo "🔧 Creating Airflow connection: ${conn_id}"

  airflow connections add "${conn_id}" \
    --conn-type "snowflake" \
    --conn-login "${USERNAME}" \
    --conn-password "${PASSWORD}" \
    --conn-schema "${CDM_SCHEMA}" \
    --conn-extra "{
      \"account\": \"${ACCOUNT}\",
      \"database\": \"${database}\",
      \"warehouse\": \"${WAREHOUSE}\",
      \"role\": \"${ROLE}\",
      \"private_key_file\": \"${PRIVATE_KEY_FILE}\"
    }"
}

# -----------------------------
# Sandbox
# -----------------------------
create_snowflake_conn \
  "snowflake_conn_deidentified_sandbox_mu" \
  "atlas_mu_sandbox"

# -----------------------------
# Dev
# -----------------------------
create_snowflake_conn \
  "snowflake_conn_deidentified_dev_mu" \
  "atlas_mu_dev"

create_snowflake_conn \
  "snowflake_conn_deidentified_dev_gpc" \
  "atlas_gpc_dev"

# -----------------------------
# Prod
# -----------------------------
create_snowflake_conn \
  "snowflake_conn_deidentified_prod_mu" \
  "atlas_mu_prod"

create_snowflake_conn \
  "snowflake_conn_deidentified_prod_gpc" \
  "atlas_gpc_prod"

echo "✅ All Airflow Snowflake connections created successfully!"

```

#### Set Environment Variables

Example `.env` file:

```env
CONNECTION_ID=snowflake_conn_deidentified_dev_mu

# source
PCORNET_DB=DEIDENTIFIED_PCORNET_CDM
PCORNET_SCHEMA=CDM

# target
CDM_DB=atlas_mu_dev
CDM_SCHEMA=CDM
VOCABULARY_SCHEMA=CDM
CROSSWALK_SCHEMA=CROSSWALK

# objects
OMOP_ETL_ROLE=OMOP_ELT
OMOP_ROLE=OMOP_ATLAS_DEV
OMOP_WH=omop_atlas_dev_wh
OMOP_USER=SERVICE_USER_ATLAS
```

### Pipeline

The `Makefile` provides commands to streamline setup and management of the OMOP on PCORnet CDM environment:

- **Build Stack**:  
  `airflow-omop-build` checks for `docker-compose.yaml` and downloads it from the official Apache Airflow documentation if missing.

- **Start Airflow Services**:  
  `airflow-omop-deploy` starts all Airflow services using Docker Compose.

- **Create Airflow Connections**:  
  `airflow-omop-connections` create all Airflow database connections.


## OMOP_SERVERLESS

This repository also provides Docker configurations to build and deploy key OHDSI tools—including Atlas, WebAPI, and ARES—in containerized environments.

### Build and Deployment

The `Makefile` includes commands for managing serverless deployments and Docker images for Atlas and WebAPI:

- **AWS Login**:  
  Use `make aws-login-dev` or `make aws-login-prod` to log in to AWS with the appropriate profile.

- **Docker Login**:  
  Use `make docker-login-dev` or `make docker-login-prod` to authenticate Docker with AWS ECR.

- **Build Docker Images for Atlas**:  
  Use `make atlas-dev` or `make atlas-prod` to build Atlas Docker images with the correct WebAPI URL.

- **Build Docker Images for WebAPI**:  
  Use `make webapi-dev` or `make webapi-prod` to build WebAPI Docker images for the specified environment.

### User Flow

1. Log in to the AWS application-web-prod account.
2. Launch the EC2 instance `ohds-postgresql-cli`.
3. Connect to the EC2 instance using Session Manager.
4. Connect to the RDS Postgres database:
  ```bash
  psql -h <db-hostname> -U <username> -d ohdsi_webapi -p 5432
  ```
5. Add users:
  - Use the following stored procedure to add users:
  ```sql
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
  - To remove users, use:
  ```sql
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
  - Example usage:
  ```sql
  CALL webapi.add_sec_users_batch(
    ARRAY['alice@example.com', 'bob@example.com'],
    ARRAY['Alice Smith', 'Bob Johnson'],
    ARRAY[true, false]
  );
  ```
6. Shut down the EC2 instance when finished.

