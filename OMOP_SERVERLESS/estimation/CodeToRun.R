library(HSV41)


# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = "temp")

# Maximum number of cores to be used:
maxCores <- parallel::detectCores() - 1

# The folder where the study intermediate and result files will be written:
outputFolder <- "output"

readRenviron("env/.env")

print(Sys.getenv("user"))

# Details for connecting to the server:
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms     = "snowflake", 
  connectionString = "jdbc:snowflake://fp20843.us-east-2.aws.snowflakecomputing.com/?db=ATLAS_MU_DEV&SCHEMA=RESULTS&warehouse=ATLAS_MU_WH&role=OMOP_ATLAS&CLIENT_RESULT_COLUMN_CASE_INSENSITIVE=true",
  port = "443",
  user   = Sys.getenv("user"),
  password = Sys.getenv("password"),
  pathToDriver = "./drivers/"  
)


# The name of the database schema where the CDM data can be found:
cdmDatabaseSchema <- "CDM"

# The name of the database schema and table where the study-specific cohorts will be instantiated:
cohortDatabaseSchema <- "TEMP"
cohortTable <- "HSV41"

# Some meta-information that will be used by the export function:
databaseId <- "HSV41DBId"
databaseName <- "HSV41DB"
databaseDescription <- "HSV41DB DESCRIPTION"

# For some database platforms (e.g. Oracle): define a schema that can be used to emulate temp tables:
options(sqlRenderTempEmulationSchema = NULL)

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        outputFolder = outputFolder,
        databaseId = databaseId,
        databaseName = databaseName,
        databaseDescription = databaseDescription,
        verifyDependencies = FALSE,
        createCohorts = TRUE,
        synthesizePositiveControls = TRUE,
        runAnalyses = TRUE,
        packageResults = TRUE,
        maxCores = maxCores)

resultsZipFile <- file.path(outputFolder, "export", paste0("Results_", databaseId, ".zip"))
dataFolder <- file.path(outputFolder, "shinyData")

# You can inspect the results if you want:
prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
launchEvidenceExplorer(dataFolder = dataFolder, blind = FALSE, launch.browser = FALSE)