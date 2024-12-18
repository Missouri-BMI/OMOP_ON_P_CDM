### 
```
# open Rstudio with R 4.4.1
renv::restore() 
pkgbuild::build()
install.packages("C:/Users/Administrator/Desktop/final/HSV_0.0.1.tar.gz", repos = NULL, type = "source")
```

### shinyapp.r
```
ensure_installed <- function(pkg) {
  # Ensure the input is a character string
  if (!is.character(pkg)) {
    stop("'pkg' must be a character string.", call. = FALSE)
  }
  
  # Check if the package is installed
  if (!requireNamespace(pkg, quietly = TRUE)) {
    msg <- paste0(sQuote(pkg), " must be installed for this functionality.")
    
    # If in an interactive session, prompt the user
    if (interactive()) {
      message(msg, "\nWould you like to install it?")
      choice <- menu(c("Yes", "No"))
      if (choice == 1) {
        install.packages(pkg)
      } else {
        stop(msg, call. = FALSE)
      }
    } else {
      # Stop execution in non-interactive environments
      stop(msg, call. = FALSE)
    }
  }
}
```