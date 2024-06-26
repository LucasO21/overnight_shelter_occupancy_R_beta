# EXTRACT SHELTER DATA FROM API SCRIPT ----
# *** ----

# *****************************************************************************
# SETUP ----
# *****************************************************************************

# * Libraries ----
library(dplyr)
library(lubridate)
library(stringr)
library(opendatatoronto)
library(janitor)
library(here)
library(readr)

# * Set Working Dir ----
setwd(here::here("dev", "R"))


#library(bigrquery)


# *****************************************************************************
# **** ----
# MODULES ----
# *****************************************************************************

#"https://bigrquery.r-dbi.org/reference/api-perform.html"

# * Big Query Connection ----
# get_bigquery_connection <- function (project = "toronto-shelter-project",
#                                      dataset = "data_raw") {
#     
#     # Connect to BigQuery
#     con <- DBI::dbConnect(
#         bigrquery::bigquery(),
#         project = project,
#         dataset = dataset,
#         billing = project  
#     )
#     
#     # Message
#     if (!is.null(con)) {
#         msg = "BiqQuery connection - Complete"
#     } else {
#         msg = "No BiqQuery connection established"
#     }
#     
#     message(str_glue(msg))
#     
#     # Message
#     return(con)
# }

# con <- get_bigquery_connection()

# * Extract Shelter Data ----
get_shelter_data <- function(year = 2024) {
    
    # Big Query Connection
    #con <- get_bigquery_connection(dataset = "data_raw")
    
    # Get Last Date in Big Query 
    # max_date <- DBI::dbGetQuery(
    #     con,
    #     "select max(occupancy_date) from `toronto-shelter-project.data_raw.raw_shelter_2023`"
    # )
    
    #max_date <- max_date %>% pull() %>% as.Date()

    # Oped Data API Info
    info <- opendatatoronto::show_package("21c83b32-d5a8-4106-a54f-010dbe49f6f2") %>%
        list_package_resources() %>%
        filter(str_to_lower(format) %in% c("csv", "geojson")) %>%
        filter(! is.na(last_modified)) %>%
        arrange(desc(last_modified)) %>%
        mutate(last_modified_year = lubridate::year(last_modified))

    info_2 <- info %>%
        filter(last_modified_year == year) %>%
        arrange(desc(last_modified)) %>%
        head(1)

    # # Info Check
    if (is.null(info) || length(info) == 0) {
        stop("No API info extracted! Check API info code chunk", call. = FALSE)
        msg = "No API info extracted!"
    }

    # # Data Extract (Open Data API)
    data <- info_2 %>%
        get_resource() %>%
        janitor::clean_names() %>%
        mutate(occupancy_date = lubridate::ymd(occupancy_date)) %>%
        head(5)

    # # Data Check
    if (is.null(data) || length(data) == 0) {
        stop("No data extracted! Check data chunk", call. = FALSE)
        msg = "No data extracted!"
    }

    # # metadata
    # metadata_tbl <- info_2 %>% 
    #     mutate(extraction_time = Sys.time())
    
    # Check: New Data
    # if (max(data$occupancy_date) == max_date) {
    #     stop("Max occupancy date from API matches max data in BigQuery", call. = FALSE)
    # }
    
    # Filter API Data > Max Occupancy Date in BQ
    # ret <- data %>% 
    #     filter(occupancy_date > max_date) %>% 
    #     mutate(extract_date = Sys.time())
    
    # Metadata
    # mtd <- str_glue(
    #     "Metadata (Open Data Toronto API):
    #         Last Extract Date: {Sys.time()}
    #         Date Range for New Data Extact: {min(output$occupancy_date)} - {max(output$occupancy_date)}
    #         Max Date in Big Query: {max_date}
    #         New Data Rows: {nrow(output)}
    #         New Data Cols: {ncol(output)}
    #     "
    # )
    
    # Message
    #message(str_glue("Raw shelter data extract - Complete!"))
    
    
    ret <- data %>% mutate(time = Sys.time())
    
    # Return
    return(ret)
    
}

shelter_raw_tbl <- get_shelter_data()

save_path <- str_glue("../../data/shelter_raw_tbl_{Sys.time()}.csv")

shelter_raw_tbl %>% readr::write_csv(save_path)



# * Load to Big Query ----
# get_bigquery_upload <- function(values, 
#                                 project            = "toronto-shelter-project", 
#                                 dataset            = "data_raw", 
#                                 table              = NULL,
#                                 create_disposition = "CREATE_IF_NEEDED",
#                                 write_disposition  = "WRITE_APPEND",
#                                 upload_job         = "shelter") {
#     
#     # Validate parameters
#     stopifnot(
#         is.data.frame(values),
#         is.character(project), length(project) == 1,
#         is.character(dataset), length(dataset) == 1,
#         is.character(table), length(table) == 1,
#         is.character(create_disposition), length(create_disposition) == 1
#     )
#     
#     # Perform upload
#     # job <- bigrquery::insert_upload_job(
#     #     values  = values,
#     #     project = project,
#     #     dataset = dataset,
#     #     table   = table,
#     #     create_disposition = create_disposition,
#     #     write_disposition  = write_disposition
#     # )
#     
#     job <- bigrquery::bq_perform_upload(
#         x = bq_table(project = project, dataset = dataset, table = table),
#         values = values,
#         write_disposition = write_disposition,
#         create_disposition = create_disposition,
#         quiet = FALSE
#     )
#     
#     # Message
#     job_time <- tibble(
#         creation_time = as.numeric(job$statistics$creationTime),
#         start_time    = as.numeric(job$statistics$startTime)
#     ) %>% 
#         mutate(creation_time = format(
#             as.POSIXct(creation_time / 1000, origin = "1970-01-01"), "%Y-%m-%d %I:%M %p"
#         )) %>% 
#         mutate(start_time = format(
#             as.POSIXct(start_time / 1000, origin = "1970-01-01"), "%Y-%m-%d %I:%M %p"
#         ))
#     
#     # Metadata
#     if (upload_job == "shelter") {
#         mtd_title = "Metadata (Shelter Occupancy Data Upload):"
#     } else if (upload_job == "weather") {
#         mtd_title = "Metadata (AccuWeather Forecast Data Upload):"
#     }
#     
#     mtd <- stringr::str_glue(
#         "
#             {mtd_title}
#                 Job Status: {job$status}
#                 Job ID: {job$jobReference$jobId}
#                 Job Creation Time: {job_time$creation_time}
#                 Job Start Time: {job_time$start_time}
#             "
#     )
#     
#     message(mtd)
#     
#     return(mtd)
# }
# 
# 
# # * Upload to Big Query ---
# upload_job <- get_bigquery_upload(
#     values = shelter_raw_tbl[[1]],
#     table  = "raw_shelter_2023",
#     write_disposition = "WRITE_APPEND"
#     
#)



# *****************************************************************************
# **** ----
# COLLECT METADATA ----
# *****************************************************************************

# list(
#     shelter_extract_mtd = shelter_raw_tbl[[2]],
#     shelter_upload_mtd  = upload_job
# ) %>% 
#     write_rds("../artifacts/metadata_list.rds")
# 
# 
# read_rds("../artifacts/metadata_list.rds")

# *****************************************************************************
# **** ----
# INITIAL UPLOADS ----
# *****************************************************************************

# * 2022 ----
# shelter_data_2022 <- get_shelter_data(slice = 3)
# 
# shelter_data_2022 %>% 
#     get_bigquery_upload(
#         table = "raw_shelter_2022"
#     )


# # * 2023 ----
# shelter_data_2023 <- get_shelter_data(slice = 1) %>%
#     filter(occupancy_date <= as.Date("2023-10-09"))
# 
# shelter_data_2023 %>%
#     get_bigquery_upload(
#         table = "raw_shelter_2023"
#     )

# *****************************************************************************
# **** ----
# DESCRIPTION ----
# *****************************************************************************

#' get_shelter_data();
#' The get_shelter_data function is designed to retrieve, clean, and transform 
#' shelter data from a specified data source, presumably a package or API that 
#' provides access to various datasets related to shelter information. The function 
#' primarily focuses on extracting data in CSV or GeoJSON format, ensuring that 
#' the datasets are not only available but also recently modified, thereby providing 
#' the most up-to-date information available.
#'
#' The function operates in two main steps:
#' 1. Information Retrieval: It first retrieves metadata about available resources 
#'    using show_package() and list_package_resources(), filtering for relevant 
#'    data formats and ensuring that the data is recent by checking the last_modified 
#'    field. The datasets are then arranged in descending order based on their 
#'    last modification date to prioritize the most recent data.
#' 2. Data Extraction and Cleaning: The function then extracts the specified slice 
#'    of data using slice() and get_resource(), and cleans the variable names 
#'    using janitor::clean_names() to ensure they are syntactically valid and 
#'    easy to work with in R.


#' get_bigquery_upload();
#' The get_bigquery_upload function is designed to facilitate the uploading of data 
#' to Google BigQuery while providing flexibility and robustness in handling various 
#' datasets and destinations. It aims to streamline the process of data upload by 
#' establishing a connection to BigQuery, initiating an upload job, and providing 
#' feedback about the job status and timings.
#'
#' The function performs several key operations:
#' 1. Parameter Validation: It validates the input parameters to ensure they are 
#'    of the correct type and non-empty, preventing unintended operations or unclear 
#'    error messages during the upload process.
#' 2. BigQuery Connection: Establishes a connection to Google BigQuery, specifying 
#'    the project and dataset to be used, and assuming the billing to be charged 
#'    to the specified project.
#' 3. Data Upload: Initiates an upload job to insert the data into the specified 
#'    table in BigQuery, with flexibility in handling table creation disposition.
#' 4. Feedback Provision: Provides feedback about the job status, ID, creation time, 
#'    and start time, aiding in monitoring and debugging.


# *****************************************************************************
# **** ----
# SAVE MODULES ----
# *****************************************************************************

# * Save Modules ----
# dump(
#     list   = c("get_shelter_data", "get_bigquery_upload", "get_bigquery_connection"),
#     file   = "../functions/extract_shelter_data.R",
#     append = FALSE
# )
# 
# dump(
#     list   = c("get_shelter_data", "get_bigquery_upload", "get_bigquery_connection"),
#     file   = "../app/modules/analysis/extract_shelter_data.R",
#     append = FALSE
# )