# R/utils.R
# Utility functions for RTO Attendance Tracking System

#' Generate Pay Period Dates
#' 
#' Creates a list of dates for a two-week pay period
#' 
#' @param start_date Character string in YYYY-MM-DD format
#' @return List with week1, week2, and all dates
generate_pay_period <- function(start_date) {
  dates <- seq(as.Date(start_date), by = "day", length.out = 14)
  week1 <- dates[1:7]
  week2 <- dates[8:14]
  
  list(
    week1 = week1,
    week2 = week2,
    dates = dates,
    start_date = dates[1],
    end_date = dates[14]
  )
}

#' Format Work Schedule Display
#' 
#' Clean up work schedule text for display
#' 
#' @param schedule Character string with work schedule
#' @return Formatted schedule string
format_work_schedule <- function(schedule) {
  if (is.na(schedule) || schedule == "") {
    return("Standard")
  }
  
  # Clean up common formatting issues
  schedule <- gsub("\\s+", " ", schedule)  # Multiple spaces to single
  schedule <- trimws(schedule)
  
  return(schedule)
}

#' Validate Status Code
#' 
#' Check if a status code is valid
#' 
#' @param code Character string with status code
#' @param valid_codes Vector of valid codes
#' @return Logical indicating if code is valid
validate_status_code <- function(code, valid_codes = NULL) {
  if (is.null(valid_codes)) {
    valid_codes <- c("AL", "AWS", "JD", "PA", "FRE", "FNM", "FHLB", "OF", "OST", "OSM")
  }
  
  if (is.na(code) || code == "") {
    return(TRUE)  # Empty is valid (regular office day)
  }
  
  # Remove asterisk if present
  clean_code <- gsub("\\*", "", code)
  
  return(clean_code %in% valid_codes)
}

#' Create Empty Attendance Data Frame
#' 
#' Generate empty attendance data structure for a pay period
#' 
#' @param team_data Data frame with team member information
#' @param pay_period List with pay period date information
#' @return Data frame with empty attendance structure
create_empty_attendance <- function(team_data, pay_period) {
  n_members <- nrow(team_data)
  
  attendance <- data.frame(
    ID = team_data$ID,
    TeamMember = team_data$TeamMember,
    WorkSchedule = team_data$WorkSchedule,
    stringsAsFactors = FALSE
  )
  
  # Add columns for each day
  for (i in 1:14) {
    day_name <- format(pay_period$dates[i], "%a")
    date_short <- format(pay_period$dates[i], "%m/%d")
    col_name <- paste0("Day_", i, "_", day_name, "_", date_short)
    attendance[[col_name]] <- ""
  }
  
  return(attendance)
}

#' Get Business Days in Pay Period
#' 
#' Filter pay period dates to only business days (M-F)
#' 
#' @param pay_period List with pay period information
#' @return Vector of business day dates
get_business_days <- function(pay_period) {
  all_dates <- pay_period$dates
  weekdays <- weekdays(all_dates)
  business_days <- all_dates[!weekdays %in% c("Saturday", "Sunday")]
  return(business_days)
}

#' Calculate Attendance Summary
#' 
#' Generate summary statistics for attendance data
#' 
#' @param attendance_data Data frame with attendance records
#' @return List with summary statistics
calculate_attendance_summary <- function(attendance_data) {
  if (nrow(attendance_data) == 0) {
    return(list(
      total_records = 0,
      present_days = 0,
      leave_days = 0,
      aws_days = 0,
      external_days = 0
    ))
  }
  
  # Count different types of codes
  codes <- attendance_data$status_code
  codes[is.na(codes)] <- ""
  
  summary <- list(
    total_records = nrow(attendance_data),
    present_days = sum(codes == ""),
    leave_days = sum(codes == "AL"),
    aws_days = sum(grepl("AWS", codes)),
    external_days = sum(codes %in% c("FRE", "FNM", "FHLB", "OF"))
  )
  
  return(summary)
}

#' Format Date for Display
#' 
#' Format dates consistently for UI display
#' 
#' @param date Date object or character string
#' @param format Character string with desired format
#' @return Formatted date string
format_display_date <- function(date, format = "%m/%d/%Y") {
  if (is.na(date) || is.null(date)) {
    return("")
  }
  
  if (is.character(date)) {
    date <- as.Date(date)
  }
  
  return(format(date, format))
}

#' Log Application Event
#' 
#' Write event to application log
#' 
#' @param message Character string with log message
#' @param level Character string with log level (INFO, WARN, ERROR)
#' @param user Character string with username (optional)
log_event <- function(message, level = "INFO", user = NULL) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  
  log_entry <- paste0(
    "[", timestamp, "] ",
    "[", level, "] ",
    if (!is.null(user)) paste0("[", user, "] "),
    message
  )
  
  # Write to console for development
  cat(log_entry, "\n")
  
  # Write to log file if exists
  log_file <- "logs/app.log"
  if (dir.exists(dirname(log_file))) {
    write(log_entry, file = log_file, append = TRUE)
  }
}

#' Safe Database Query
#' 
#' Execute database query with error handling
#' 
#' @param con Database connection
#' @param query Character string with SQL query
#' @param params List of parameters for prepared statement
#' @return Query results or NULL on error
safe_db_query <- function(con, query, params = NULL) {
  tryCatch({
    if (is.null(params)) {
      result <- dbGetQuery(con, query)
    } else {
      result <- dbGetQuery(con, query, params = params)
    }
    return(result)
  }, error = function(e) {
    log_event(paste("Database query error:", e$message), "ERROR")
    return(NULL)
  })
}