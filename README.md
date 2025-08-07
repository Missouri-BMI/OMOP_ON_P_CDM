# OMOP_ON_P_CDM

This repository offers tools and resources for converting PCORnet CDM data to OMOP CDM within Snowflake and AWS. It supports ETL processes and integrates with OHDSI analytical tools. Included are setup instructions for Airflow-based pipelines, environment configuration, and Dockerized deployments of OHDSI applications such as Atlas, WebAPI, ARES, Achilles, and more.

## OMOP_ON_PCORNET_CDM

OMOP CDM is implemented as a wrapper over the PCORnet CDM, enabling OMOP tables and schemas to be defined as views or tables on top of PCORnet data in Snowflake. This approach allows seamless data refreshes and integration with OHDSI tools like Atlas, Achilles, Data Quality Dashboard (DQDashboard), and ARES.

### Project Configuration

#### Add Airflow Connections

To configure Airflow for Snowflake environments, create a `connections.sh` script in the `env/` directory:
Structure for managing environment variables in local directory:
The `env/` directory is structured to manage environment-specific configuration files and secrets for both deidentified and identified data environments. Example structure:

```
env/
  deidentified/
    dev/
      .env                # Environment variables for deidentified dev
    connections.sh        # Airflow connection script for deidentified
    rsa_key.p8            # Private key for Snowflake authentication
  identified/
    prod/
      .env                # Environment variables for identified prod
    connections.sh        # Airflow connection script for identified
    rsa_key.p8            # Private key for Snowflake authentication
```

- Place your environment variable files (e.g., `.env`) in the appropriate subdirectory (`dev` for development, `prod` for production).
- connection scripts run on make build and store in the db using api
- Store your Snowflake private key as `rsa_key.p8` in the corresponding directory.

```bash
#!/bin/bash

# Example for sandbox environment
SANDBOX_CDM_SCHEMA="CDM"
SANDBOX_CDM_DB="atlas_mu_sandbox"
airflow connections add 'snowflake_conn_sandbox' \
  --conn-type 'snowflake' \
  --conn-login "${USERNAME}" \
  --conn-password "${PRIVATE_KEY_PASSWORD}" \
  --conn-schema "${SANDBOX_CDM_SCHEMA}" \
  --conn-extra "{\"account\": \"${ACCOUNT}\", \"database\": \"${SANDBOX_CDM_DB}\", \"warehouse\": \"${WAREHOUSE}\", \"role\": \"${ROLE}\", \"private_key_file\": \"${PRIVATE_KEY_FILE}\"}"
echo "✅ Airflow connections created!"
```

#### Set Environment Variables

Add environment variable files in the appropriate `env/[dev|prod|sandbox]` directory.  
Example `env/dev` file:

```env
CONNECTION_ID=snowflake_conn_dev
PROJECT=mu
ENVIRONMENT=dev

# Source (PCORnet CDM)
PCORNET_DB=DEIDENTIFIED_PCORNET_CDM
PCORNET_SCHEMA=CDM

# Target (OMOP CDM)
CDM_DB=atlas_mu_dev
CDM_SCHEMA=CDM
VOCABULARY_SCHEMA=CDM
CROSSWALK_SCHEMA=CROSSWALK

# Snowflake objects and roles
OMOP_ETL_ROLE=OMOP_ELT
OMOP_ROLE=OMOP_ATLAS_DEV
OMOP_WH=omop_atlas_dev_wh
OMOP_USER=SERVICE_USER_ATLAS
```

### Pipeline

The `Makefile` provides commands to streamline setup and management of the OMOP on PCORnet CDM environment:

- **Build Stack**:  
  `make build` checks for `docker-compose.yaml` and downloads it from the official Apache Airflow documentation if missing.

- **Start Airflow Services**:  
  `make deploy` starts all Airflow services using Docker Compose.

### Airflow DAGs

1. **INIT**
  - CREATE DATABASE
  - CREATE SCHEMA CDM, RESULTS, TEMP, VOCABULARY (CDM)
  - GENERATE DDL using R

2. **DATA REFRESH**
  - CDM REFRESH
  - ARES ANALYSIS and EXPORT RESULT TO S3

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

