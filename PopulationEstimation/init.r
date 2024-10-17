# install R
# install Java
# R tool

# install packages
install.packages("rJava")
library("rJava")

install.packages('devtools')
library(devtools)

install.packages("usethis")
library(usethis)

#_JAVA_OPTIONS='-Xmx4g'
edit_r_environ()

create_github_token(scopes = c("(no scope)"), description = "R:GITHUB_PAT", host = "https://github.com")
## GITHUB_PAT = 'github_personal_access_token'
edit_r_environ()


install.packages("pkgbuild")
pkgbuild::check_build_tools()

install.packages("renv")

install.packages("remotes")
remotes::install_github("OHDSI/CohortMethod")


## restore from lockfile
renv::init()
renv::status()


renv::init(bare = TRUE)
renv::hydrate()
renv::install()
renv::snapshot()


devtools::build()
devtools::install()

library(ESTIMATION)