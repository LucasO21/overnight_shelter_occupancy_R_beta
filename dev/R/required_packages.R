# p <- c("dplyr", "stringr", "lubridate", "readr", "janitor", "here", "opendatatoronto")
# 
# pkg <- .packages(all.available = TRUE)
# for(i in p){
#     if(!i %in% pkg){
#       message("Package", i, "is not installed. Installing the package:")
#       install.packages(i)
#     }
# 
# }



packages <- c("dplyr", "stringr", "lubridate", "readr", "janitor", "here", "opendatatoronto")
for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
        message("Installing package: ", pkg)
        install.packages(pkg)
    }
}
