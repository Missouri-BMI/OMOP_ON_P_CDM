install.packages("remotes", dependencies = TRUE)
install.packages("usethis", dependencies = TRUE)
install.packages("ggplot2")
usethis::create_github_token()
gitcreds::gitcreds_set()

library(usethis)
edit_r_environ()

remotes::install_version("DT", version = "0.27", repos = "http://cran.us.r-project.org")
remotes::install_version("shiny", version = "1.9.1", repos = "http://cran.us.r-project.org")
remotes::install_github("OHDSI/SqlRender")


launchEvidenceExplorer <- function(dataFolder, blind = TRUE, launch.browser = TRUE) {
  dataFolder <- normalizePath(dataFolder)
  appDir <- file.path(getwd(), "inst", "shiny", "EvidenceExplorer")
  .GlobalEnv$shinySettings <- list(dataFolder = dataFolder, blind = blind)
  on.exit(rm("shinySettings", envir = .GlobalEnv))
  shiny::runApp(appDir) 
}

outputFolder <- "output"
dataFolder <- file.path(outputFolder, "shinyData")
launchEvidenceExplorer(dataFolder = dataFolder, blind = TRUE, launch.browser = FALSE)
