setwd("~/Desktop/Repositories/OMOP_ON_P_CDM/OMOP_ON_PCORNET_CDM")

if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools")
    install.packages("keyring")
    install.packages("remotes")
    devtools::install_github("OHDSI/CommonDataModel", "v5.4")
    devtools::install_github("OHDSI/DatabaseConnector")
    remotes::install_github(repo = 'OHDSI/Achilles', ref='develop')
    remotes::install_github(repo = 'Missouri-BMI/SqlRender', build = TRUE, force = TRUE)
    remotes::install_github(repo = 'OHDSI/DataQualityDashboard')
    remotes::install_github(repo = 'OHDSI/AresIndexer')
}
# usethis::edit_r_environ()
# Programmatically add Java options for Snowflake JDBC to .Renviron
renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")
java_opts_line <- "_JAVA_OPTIONS='-Dnet.snowflake.jdbc.enableBouncyCastle=true -Xmx16g --add-opens=java.base/java.nio=ALL-UNNAMED'"
# Overwrite _JAVA_OPTIONS if it exists, otherwise add it
if (file.exists(renviron_path)) {
    renv_lines <- readLines(renviron_path)
    if (any(grepl("^_JAVA_OPTIONS=", renv_lines))) {
        renv_lines <- gsub("^_JAVA_OPTIONS=.*", java_opts_line, renv_lines)
        writeLines(renv_lines, renviron_path)
    } else {
        write(java_opts_line, file = renviron_path, append = TRUE)
    }
} else {
    write(java_opts_line, file = renviron_path)
}

# Download JDBC driver for Snowflake if not already present
downloadJdbcDrivers("snowflake", pathToDriver = './drivers/')

