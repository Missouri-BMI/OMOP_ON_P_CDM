if (!require("remotes")) install.packages("remotes")
remotes::install_github("OHDSI/Achilles")
library(DatabaseConnector)
library(Achilles)

readRenviron(".env")


# Running Achilles: Single-Threaded Mode
# In single-threaded mode, there is no need to set a `scratchDatabaseSchema`, as temporary tables will be used.

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms     = "snowflake", 
  connectionString = "jdbc:snowflake://xp02744.us-east-2.aws.snowflakecomputing.com/?db=OMOP_CDM&schema=RESULTS&warehouse=ATLAS_WH&role=OMOP_ATLAS&CLIENT_RESULT_COLUMN_CASE_INSENSITIVE=true",
  port = "443",
  user   = Sys.getenv("user"),
  password = Sys.getenv("password"),
  pathToDriver = "./snowflake/"  
)

# conn <- connect(connectionDetails)
# disconnect(conn)


## Explore more parameter from: https://github.com/OHDSI/Achilles/blob/main/vignettes/RunningAchilles.Rmd
## https://github.com/OHDSI/Achilles/blob/main/R/Achilles.R
achilles(connectionDetails = connectionDetails, 
         cdmDatabaseSchema = "CDM", 
         vocabDatabaseSchema = "VOCABULARY",
         resultsDatabaseSchema = "RESULTS", 
         cdmVersion = "5.4",
         numThreads = 10,
		 outputFolder = "output")


## Creating Indices
# Not supported by Amazon Redshift or IBM Netezza; function will skip this step if using those platforms*
#To improve query performance of the Achilles results tables, run the **createIndices** function.

createIndices(connectionDetails = connectionDetails, 
              resultsDatabaseSchema = "RESULTS", 
              outputFolder = "output")

citation("Achilles")              
