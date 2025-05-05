install.packages("usethis", dependencies = TRUE)
install.packages("remotes", dependencies = TRUE)

usethis::create_github_token()
gitcreds::gitcreds_set()


renv::init()
#change dt to 0.27 in renv.lock
renv::restore()

remotes::install_github("OHDSI/CohortMethod@v4.2.3")
remotes::install_github("OHDSI/MethodEvaluation")
remotes::install_github("OHDSI/OhdsiSharing")
remotes::install_github("OHDSI/Cyclops@v3.1.2")

renv::snapshot()

pkgbuild::build()

install.packages(
  "F:/estimations/HSV41_0.0.1.tar.gz", 
  repos = NULL, 
  type = "source"
)

library(DatabaseConnector)
downloadJdbcDrivers("snowflake", pathToDriver = './drivers/')
