# install.r

install.packages("usethis", dependencies = TRUE)
install.packages("remotes", dependencies = TRUE)
install.packages("rJava")

library(usethis)
edit_r_environ()

usethis::create_github_token()
gitcreds::gitcreds_set()

renv::restore()
# or 
# renv::install()

remotes::install_github("OHDSI/PatientLevelPrediction@v5.0.5")

source('./extras/packageDeps.R')

renv::status()
renv::snapshot()

pkgbuild::build()

install.packages("F://predictions/Demo1_1.0.6.tar.gz", repos = NULL, type = "source")

library(DatabaseConnector)
downloadJdbcDrivers("snowflake", pathToDriver = './drivers/')

library(reticulate)
py_config()

reticulate::py_require(c("scikit-learn"))