install.packages("remotes")
remotes::install_github("OHDSI/DataQualityDashboard")
library(DataQualityDashboard)

readRenviron("env/dev/.env")

print(Sys.getenv("user"))
# Running Achilles: Single-Threaded Mode
# In single-threaded mode, there is no need to set a `scratchDatabaseSchema`, as temporary tables will be used.


connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms     = "snowflake", 
  connectionString = "jdbc:snowflake://xp02744.us-east-2.aws.snowflakecomputing.com/?db=OMOP_CDM&schema=RESULTS&warehouse=ATLAS_WH&role=OMOP_ATLAS&CLIENT_RESULT_COLUMN_CASE_INSENSITIVE=true",
  port = "443",
  user   = Sys.getenv("user"),
  password = Sys.getenv("password"),
  pathToDriver = "./drivers/snowflake/"  
)





cdmDatabaseSchema <- "CDM" # the fully qualified database schema name of the CDM
resultsDatabaseSchema <- "RESULTS" # the fully qualified database schema name of the results schema 
cdmSourceName <- "MU CDM Data" # a human readable name for your CDM source
vocabDatabaseSchema <- "VOCABULARY"
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
                                                           numThreads =2 numThreads,
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