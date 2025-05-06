# install.packages("remotes")
# remotes::install_github("OHDSI/DataQualityDashboard")

library(DatabaseConnector)
library(DataQualityDashboard)

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


cdmDatabaseSchema <- CDM_SCHEMA # the fully qualified database schema name of the CDM
resultsDatabaseSchema <- RESULTS_SCHEMA # the fully qualified database schema name of the results schema 
cdmSourceName <- "MU-CDM-Data" # a human readable name for your CDM source
vocabDatabaseSchema <- VOCABULARY_SCHEMA
cdmVersion <- "5.4" # the CDM version you are targetting. Currently supports 5.2, 5.3, and 5.4
# determine how many threads (concurrent SQL sessions) to use ----------------------------------------
numThreads <- 1 # on Redshift, 3 seems to work well
# specify if you want to execute the queries or inspect them ------------------------------------------
sqlOnly <- FALSE # set to TRUE if you just want to get the SQL scripts and not actually run the queries
sqlOnlyIncrementalInsert <- FALSE # set to TRUE if you want the generated SQL queries to calculate DQD results 
sqlOnlyUnionCount <- 1 # in sqlOnlyIncrementalInsert mode, the number of check sqls to union in a single 
# NOTES specific to sqlOnly <- TRUE option ------------------------------------------------------------
# 1. You do not need a live database connection. Instead, connectionDetails only needs these parameters:
# connectionDetails <- DatabaseConnector::createConnectionDetails(
# dbms = "", # specify your dbms
# pathToDriver = "/"
# )
# 2. Since these are fully functional queries, this can help with debugging.
# 3. In the results output by the sqlOnlyIncrementalInsert queries, placeholders are populated for execution_# 4. In order to use the generated SQL to insert metadata and check results into output table, you must # where should the results and logs go? ----------------------------------------------------------------
outputFolder <- "output"
outputFile <- "results.json"
# logging type -------------------------------------------------------------------------------------
verboseMode <- TRUE # set to FALSE if you don't want the logs to be printed to the console
# write results to table? ------------------------------------------------------------------------------
writeToTable <- TRUE # set to FALSE if you want to skip writing to a SQL table in the results schema
# specify the name of the results table (used when writeToTable = TRUE and when sqlOnlyIncrementalInsert writeTableName <- "dqdashboard_results"
# write results to a csv file? -----------------------------------------------------------------------

writeToCsv <- FALSE # set to FALSE if you want to skip writing to csv file
csvFile <- "" # only needed if writeToCsv is set to TRUE
# if writing to table and using Redshift, bulk loading can be initialized -------------------------------
# Sys.setenv("AWS_ACCESS_KEY_ID" = "",
# "AWS_SECRET_ACCESS_KEY" = "",
# "AWS_DEFAULT_REGION" = "",
# "AWS_BUCKET_NAME" = "",
# "AWS_OBJECT_KEY" = "",
# "AWS_SSE_TYPE" = "AES256",
# "USE_MPP_BULK_LOAD" = TRUE)
# which DQ check levels to run -------------------------------------------------------------------
checkLevels <- c("TABLE", "FIELD", "CONCEPT")
# which DQ checks to run? ------------------------------------
checkNames <- c() # Names can be found in inst/csv/OMOP_CDM_v5.3_Check_Descriptions.csv
# want to EXCLUDE a pre-specified list of checks? run the following code:
##
checksToExclude <- c() # Names of check types to exclude from your DQD run
# allChecks <- DataQualityDashboard::listDqChecks()
# checkNames <- allChecks$checkDescriptions %>%
# subset(!(checkName %in% checksToExclude)) %>%
# select(checkName)
# which CDM tables to exclude? ------------------------------------
# tablesToExclude <- c("CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS")
tablesToExclude <- c("COHORT_DEFINITION","CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN")
# run the job --------------------------------------------------------------------------------------
DataQualityDashboard::executeDqChecks(connectionDetails = connectionDetails,
                                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                                           resultsDatabaseSchema = resultsDatabaseSchema,
                                                           vocabDatabaseSchema = vocabDatabaseSchema,
                                                           cdmSourceName = cdmSourceName,
                                                           cdmVersion = cdmVersion,
                                                           numThreads = numThreads,
                                                           sqlOnly = sqlOnly,
                                                           sqlOnlyUnionCount = sqlOnlyUnionCount,
                                                           sqlOnlyIncrementalInsert = sqlOnlyIncrementalInsert,
                                                           outputFolder = outputFolder,
                                                           outputFile = outputFile,
                                                           verboseMode = verboseMode,
                                                           writeToTable = writeToTable,
                                                           writeToCsv = writeToCsv,
                                                           csvFile = csvFile,
                                                           checkLevels = checkLevels,
                                                           tablesToExclude = tablesToExclude,
                                                           checkNames = checkNames)
# inspect logs ----------------------------------------------------------------------------
ParallelLogger::launchLogViewer(logFileName = file.path(outputFolder, cdmSourceName,
                                                      sprintf("log_DqDashboard_%s.txt", cdmSourceName)))



# (OPTIONAL) if you want to write the JSON file to the results table separately -----------------------------
#jsonFilePath <- ""
#DataQualityDashboard::writeJsonResultsToTable(connectionDetails = connectionDetails,
 #                                             resultsDatabaseSchema = resultsDatabaseSchema,
  #                                            jsonFilePath = jsonFilePath)