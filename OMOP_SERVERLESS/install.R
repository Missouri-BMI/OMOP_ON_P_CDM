install.packages("usethis")
install.packages("keyring")
remotes::install_github(repo = 'OHDSI/DatabaseConnector')



remotes::install_github(repo = 'OHDSI/Achilles', ref='develop')
remotes::install_github(repo = 'Missouri-BMI/SqlRender', build = TRUE, force = TRUE)
remotes::install_github(repo = 'OHDSI/DataQualityDashboard')
remotes::install_github(repo = 'OHDSI/AresIndexer')

#_JAVA_OPTIONS='-Dnet.snowflake.jdbc.enableBouncyCastle=true -Xmx16g'
usethis::edit_r_environ()

# Download JDBC driver for Snowflake if not already present
downloadJdbcDrivers("snowflake", pathToDriver = './drivers/')

