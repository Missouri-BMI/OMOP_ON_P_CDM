setwd("~/Desktop/Repositories/OMOP_ON_P_CDM/OMOP_ON_PCORNET_CDM")

# #snowflake
# CommonDataModel::listSupportedDialects()
# #5.4
# CommonDataModel::listSupportedVersions()


library(DatabaseConnector)
downloadJdbcDrivers("snowflake", pathToDriver = './drivers')


# Build JDBC connection string
CONNECTION_STRING <- paste0(
  "jdbc:snowflake://", "TKNLTGA-I2B2DB", 
  ".snowflakecomputing.com/?db=", "atlas_mu_sandbox",
  "&warehouse=", "OMOP_ETL_WH", 
  "&role=", "OMOP_ELT", 
  "&CLIENT_RESULT_COLUMN_CASE_INSENSITIVE=true",
  "&private_key_file=", "./env/deidentified/rsa_key.p8",
  "&private_key_file_pwd=", ""
)

keyring::key_set_with_value("connectionString", password = CONNECTION_STRING)
keyring::key_set_with_value("user", password = "ATLAS_ETL_USER")
keyring::key_set_with_value("password", password = "")

# Create connection details directly using credentials
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "snowflake", 
  server = "",
  connectionString = keyring::key_get("connectionString"),
  user = keyring::key_get("user"),
  password = keyring::key_get("password"),
  pathToDriver = "./drivers"
)

CommonDataModel::buildRelease(cdmVersions = "5.4",
                               targetDialects = "snowflake",
                               outputfolder = "./output")

#CommonDataModel::executeDdl(connectionDetails = cd,
 #                           cdmVersion = "5.4",
  #                          cdmDatabaseSchema = "cdm"
#)