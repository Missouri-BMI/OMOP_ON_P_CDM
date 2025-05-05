# install.packages("remotes")
# remotes::install_github("OHDSI/DataQualityDashboard")

# Load necessary libraries
library(DatabaseConnector)
library(Achilles)

# Download JDBC driver for Snowflake if not already present
downloadJdbcDrivers("snowflake", pathToDriver = './drivers/')

# Load environment variables
readRenviron("../../../env/prod/mu/.env")

# Read credentials and config
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
RESULTS_SCHEMA <- "results"

# Build JDBC connection string
CONNECTION_STRING <- paste0(
  "jdbc:snowflake://", ACCOUNT, 
  ".snowflakecomputing.com/?db=", CDM_DB,
  "&schema=", RESULTS_SCHEMA,
  "&warehouse=", WAREHOUSE, 
  "&role=", ROLE, 
  "&CLIENT_RESULT_COLUMN_CASE_INSENSITIVE=true"
)

# Disable connection observer to avoid RStudio viewer issues
options(connectionObserver = NULL)

# Create connection details directly using credentials
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "snowflake", 
  connectionString = CONNECTION_STRING,
  port = "443",
  user = 'SERVICE_USER_ATLAS',
  password = '',
  pathToDriver = "./drivers/"
)

# Run Achilles
achilles(
  connectionDetails = connectionDetails, 
  cdmDatabaseSchema = CDM_SCHEMA, 
  vocabDatabaseSchema = VOCABULARY_SCHEMA,
  resultsDatabaseSchema = "RESULTS", 
  cdmVersion = "5.4",
  numThreads = 1,
  createIndices = FALSE,
  optimizeAtlasCache = TRUE,
  outputFolder = "output"
)
