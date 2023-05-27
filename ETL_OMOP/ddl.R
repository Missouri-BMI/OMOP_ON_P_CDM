install.packages("devtools", dependecies=TRUE)
library(devtools)

devtools::install_github("DatabaseConnector")
library(DatabaseConnector)

cd <- DatabaseConnector::createConnectionDetails(
  dbms     = "postgresql", 
  server   = "localhost/omop_cdm", 
  user     = "mhmcb", 
  password = "Password123", 
  port     = 5432, 
  pathToDriver = "./"  
)

CommonDataModel::executeDdl(connectionDetails = cd,
                            cdmVersion = "5.4",
                            cdmDatabaseSchema = "cdm"
)