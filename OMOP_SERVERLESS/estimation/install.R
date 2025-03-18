install.packages("usethis", dependencies = TRUE)
install.packages("remotes", dependencies = TRUE)

usethis::create_github_token()
gitcreds::gitcreds_set()


renv::restore() 

pkgbuild::build()

install.packages(
    "C:/Users/Administrator/Desktop/final/HSVCOHORT_0.0.1.tar.gz", 
    repos = NULL, 
    type = "source"
)


library(DatabaseConnector)
downloadJdbcDrivers("snowflake", pathToDriver = './drivers/')
