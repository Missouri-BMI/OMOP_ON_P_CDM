setwd("~/Desktop/Repositories/OMOP_ON_P_CDM/OMOP_ON_PCORNET_CDM/SCRIPTS/config")

install.packages("devtools")
devtools::install_github("OHDSI/CommonDataModel")
devtools::install_github("ohdsi/DatabaseConnector")


library(DatabaseConnector)
downloadJdbcDrivers("snowflake", pathToDriver = './drivers/')

# #snowflake
# CommonDataModel::listSupportedDialects()
# #5.4
# CommonDataModel::listSupportedVersions()


# CommonDataModel::buildRelease(cdmVersions = "5.4",
#                               targetDialects = "snowflake",
#                               outputfolder = "output/")

jdbcUrl <- "jdbc:snowflake://fp20843.us-east-2.aws.snowflakecomputing.com/?db=ATLAS_MU_PROD&warehouse=omop_etl_wh&role=omop_elt&CLIENT_RESULT_COLUMN_CASE_INSENSITIVE=true&authenticator=externalbrowser"

cd  <- DatabaseConnector::createConnectionDetails(
  dbms     = "snowflake", 
  connectionString = jdbcUrl,
  port = "443",
  password = "",
  user   = 'mhmcb@umsystem.edu',
  pathToDriver = "./drivers/"  
)

CommonDataModel::executeDdl(connectionDetails = cd,
                            cdmVersion = "5.4",
                            cdmDatabaseSchema = "cdm"
)