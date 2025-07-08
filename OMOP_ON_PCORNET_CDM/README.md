# AIRFLOW DAGs:
## INIT:
### CREATE DATABASE;
### CREATE SCHEMA CDM, RESULTS, TEMP, VOCABULARY(CDM);
### GENERATE DDL using R

## DATA REFRESH:
### CDM REFRESH
### ARES ANALYSIS and EXPORT RESULT TO S3

# Airflow sample connection

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
