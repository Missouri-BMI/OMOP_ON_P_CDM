
library(DatabaseConnector)
library(Achilles)
library(keyring)

options(connectionObserver = NULL)

readRenviron("/opt/airflow/env/dev/gpc/.env")

PROJECT <- Sys.getenv("PROJECT")
ENVIRONMENT <- Sys.getenv("ENVIRONMENT")
ACCOUNT <- Sys.getenv("ACCOUNT")
USERNAME <- Sys.getenv("USERNAME")
PASSWORD <- Sys.getenv("PASSWORD")
WAREHOUSE <- Sys.getenv("WAREHOUSE")
ROLE <- Sys.getenv("ROLE")

CDM_DB <- Sys.getenv("CDM_DB")
CDM_SCHEMA <- Sys.getenv("CDM_SCHEMA")
PCORNET_DB <- Sys.getenv("PCORNET_DB")
PCORNET_SCHEMA <- Sys.getenv("PCORNET_SCHEMA")
CROSSWALK_SCHEMA <- Sys.getenv("CROSSWALK_SCHEMA")
VOCABULARY_SCHEMA <- Sys.getenv("VOCABULARY_SCHEMA")
CONNECTION_STRING <- paste0("jdbc:snowflake://", ACCOUNT, ".snowflakecomputing.com/?db=", CDM_DB, "&warehouse=", WAREHOUSE, "&role=", ROLE, "&CLIENT_RESULT_COLUMN_CASE_INSENSITIVE=true")

# Securely retrieve credentials from keyring
keyring::key_set_with_value("user", password = USERNAME)
keyring::key_set_with_value("password", password = PASSWORD)

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "snowflake", 
  connectionString = CONNECTION_STRING,
  port = "443",
  user = keyring::key_get("user"),
  password = keyring::key_get("password"),
  pathToDriver = "/opt/airflow/SCRIPTS/analysis/Achilles/drivers/snowflake/"  
)


achilles(connectionDetails = connectionDetails, 
         cdmDatabaseSchema = CDM_SCHEMA, 
         vocabDatabaseSchema = VOCABULARY_SCHEMA,
         resultsDatabaseSchema = "RESULTS", 
         cdmVersion = "5.4",
         numThreads = 6,
         createIndices = FALSE,
         optimizeAtlasCache = TRUE,
		 outputFolder = "/opt/airflow/SCRIPTS/analysis/Achilles/output")