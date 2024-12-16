if (!require("remotes")) install.packages("remotes")
remotes::install_github("OHDSI/Achilles")
remotes::install_github("OHDSI/DataQualityDashboard")
library(DatabaseConnector)
library(Achilles)
options(connectionObserver = NULL)

readRenviron("env/dev/.env")

print(Sys.getenv("user"))
# Running Achilles: Single-Threaded Mode
# In single-threaded mode, there is no need to set a `scratchDatabaseSchema`, as temporary tables will be used.


connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms     = "snowflake", 
  connectionString = "jdbc:snowflake://fp20843.us-east-2.aws.snowflakecomputing.com/?db=ATLAS_MU_DEV&warehouse=OMOP_ETL_WH&role=OMOP_ELT&CLIENT_RESULT_COLUMN_CASE_INSENSITIVE=true",
  port = "443",
  user   = Sys.getenv("user"),
  password = Sys.getenv("password"),
  pathToDriver = "./drivers/snowflake/"  
)

# conn <- connect(connectionDetails)
# disconnect(conn)


## Explore more parameter from: https://github.com/OHDSI/Achilles/blob/main/vignettes/RunningAchilles.Rmd
## https://github.com/OHDSI/Achilles/blob/main/R/Achilles.R
achilles(connectionDetails = connectionDetails, 
         cdmDatabaseSchema = "CDM", 
         vocabDatabaseSchema = "CDM",
         resultsDatabaseSchema = "RESULTS", 
         cdmVersion = "5.4",
         numThreads = 6,
         createIndices = FALSE,
         optimizeAtlasCache = TRUE,
		 outputFolder = "output")


## Creating Indices
# Not supported by Amazon Redshift or IBM Netezza; function will skip this step if using those platforms*
#To improve query performance of the Achilles results tables, run the **createIndices** function.

createIndices(connectionDetails = connectionDetails, 
              resultsDatabaseSchema = "RESULTS", 
              outputFolder = "output")

citation("Achilles")              

