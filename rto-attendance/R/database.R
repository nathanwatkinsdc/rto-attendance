# R/database.R
# Database functions for RTO Attendance Tracking System

library(DBI)
library(RSQLite)
library(pool)
library(config)

#' Get Database Connection
#' 
#' Create database connection using pool for connection management
#' 
#' @param config_name Character string with config environment name
#' @return Database pool object
get_db_connection <- function(config_name = Sys.getenv("R_CONFIG_ACTIVE", "default")) {
  cfg <- config::get(file = "config/config.yml", config = config_name)
  
  if (cfg$database$driver == "SQLite") {
    pool <- dbPool(
      drv = RSQLite::SQLite(),
      dbname = cfg$database$database,
      host = "localhost"
    )
  } else if (cfg$database$driver == "PostgreSQL") {
    pool <- dbPool(
      drv = RPostgreSQL::PostgreSQL(),
      dbname = cfg$database$database,
      host = cfg$database$host,
      port = cfg$database$port,
      user = cfg$database$username,
      password = cfg$database$password,
      minSize = 1,
      maxSize = cfg$database$pool_size %||% 10
    )
  } else {
    stop("Unsupported database driver: ", cfg$database$driver)
  }
  
  return(pool)
}

#' Get Team Members
#' 
#' Retrieve all active team members
#' 
#' @param pool Database pool connection
#' @return Data frame with team member information
get_team_members <- function(pool) {
  query <- "
    SELECT id, employee_id, first_name, last_name, full_name,
           email, work_schedule, aws_day, department, is_active
    FROM team_members 
    WHERE is_active = 1
    ORDER BY last_name, first_name
  "
  
  result <- safe_db_query(pool, query)
  return(result)
}

#' Get Pay Periods
#' 
#' Retrieve all active pay periods
#' 
#' @param pool Database pool connection
#' @return Data frame with pay period information
get_pay_periods <- function(pool) {
  query <- "
    SELECT id, period_name, period_number, start_date, end_date, is_active
    FROM pay_periods 
    WHERE is_active = 1
    ORDER BY start_date DESC
  "
  
  result <- safe_db_query(pool, query)
  if (!is.null(result)) {
    result$start_date <- as.Date(result$start_date)
    result$end_date <- as.Date(result$end_date)
  }
  return(result)
}

#' Get Reason Codes
#' 
#' Retrieve all active reason codes
#' 
#' @param pool Database pool connection
#' @return Data frame with reason code information
get_reason_codes <- function(pool) {
  query <- "
    SELECT code, description, category, color_code, display_order
    FROM reason_codes 
    WHERE is_active = 1
    ORDER BY display_order, code
  "
  
  result <- safe_db_query(pool, query)
  return(result)
}

#' Get Attendance Records
#' 
#' Retrieve attendance records for a specific pay period
#' 
#' @param pool Database pool connection
#' @param pay_period_id Integer pay period ID
#' @param team_member_id Integer team member ID (optional)
#' @return Data frame with attendance records
get_attendance_records <- function(pool, pay_period_id, team_member_id = NULL) {
  if (is.null(team_member_id)) {
    query <- "
      SELECT ar.id, ar.team_member_id, ar.pay_period_id, ar.attendance_date,
             ar.status_code, ar.notes, ar.updated_by, ar.updated_at,
             tm.full_name as team_member_name
      FROM attendance_records ar
      JOIN team_members tm ON ar.team_member_id = tm.id
      WHERE ar.pay_period_id = ?
      ORDER BY tm.last_name, tm.first_name, ar.attendance_date
    "
    params <- list(pay_period_id)
  } else {
    query <- "
      SELECT ar.id, ar.team_member_id, ar.pay_period_id, ar.attendance_date,
             ar.status_code, ar.notes, ar.updated_by, ar.updated_at,
             tm.full_name as team_member_name
      FROM attendance_records ar
      JOIN team_members tm ON ar.team_member_id = tm.id
      WHERE ar.pay_period_id = ? AND ar.team_member_id = ?
      ORDER BY ar.attendance_date
    "
    params <- list(pay_period_id, team_member_id)
  }
  
  result <- safe_db_query(pool, query, params)
  if (!is.null(result)) {
    result$attendance_date <- as.Date(result$attendance_date)
  }
  return(result)
}

#' Save Attendance Record
#' 
#' Insert or update an attendance record
#' 
#' @param pool Database pool connection
#' @param team_member_id Integer team member ID
#' @param pay_period_id Integer pay period ID
#' @param attendance_date Date object
#' @param status_code Character string with status code
#' @param notes Character string with notes (optional)
#' @param updated_by Character string with username
#' @return Logical indicating success
save_attendance_record <- function(pool, team_member_id, pay_period_id, 
                                 attendance_date, status_code, notes = NULL, 
                                 updated_by = "system") {
  
  # Validate inputs
  if (is.na(team_member_id) || is.na(pay_period_id) || is.na(attendance_date)) {
    log_event("Invalid parameters for save_attendance_record", "ERROR")
    return(FALSE)
  }
  
  # Clean status code
  if (is.na(status_code) || status_code == "") {
    status_code <- NULL
  }
  
  tryCatch({
    # Use UPSERT (INSERT OR REPLACE for SQLite, ON CONFLICT for PostgreSQL)
    query <- "
      INSERT OR REPLACE INTO attendance_records 
      (team_member_id, pay_period_id, attendance_date, status_code, notes, updated_by)
      VALUES (?, ?, ?, ?, ?, ?)
    "
    
    poolWithTransaction(pool, function(con) {
      dbExecute(con, query, params = list(
        team_member_id, pay_period_id, attendance_date, 
        status_code, notes, updated_by
      ))
    })
    
    log_event(paste("Saved attendance record for team member", team_member_id, 
                   "on", attendance_date), "INFO", updated_by)
    return(TRUE)
    
  }, error = function(e) {
    log_event(paste("Error saving attendance record:", e$message), "ERROR")
    return(FALSE)
  })
}

#' Delete Attendance Record
#' 
#' Remove an attendance record
#' 
#' @param pool Database pool connection
#' @param record_id Integer record ID
#' @param updated_by Character string with username
#' @return Logical indicating success
delete_attendance_record <- function(pool, record_id, updated_by = "system") {
  tryCatch({
    query <- "DELETE FROM attendance_records WHERE id = ?"
    
    poolWithTransaction(pool, function(con) {
      dbExecute(con, query, params = list(record_id))
    })
    
    log_event(paste("Deleted attendance record", record_id), "INFO", updated_by)
    return(TRUE)
    
  }, error = function(e) {
    log_event(paste("Error deleting attendance record:", e$message), "ERROR")
    return(FALSE)
  })
}

#' Add Team Member
#' 
#' Insert a new team member
#' 
#' @param pool Database pool connection
#' @param employee_id Character string with employee ID
#' @param first_name Character string with first name
#' @param last_name Character string with last name
#' @param email Character string with email
#' @param work_schedule Character string with work schedule
#' @param aws_day Character string with AWS day
#' @param department Character string with department
#' @return Integer with new team member ID or NULL on error
add_team_member <- function(pool, employee_id, first_name, last_name, 
                           email = NULL, work_schedule = NULL, aws_day = NULL,
                           department = "RTO") {
  tryCatch({
    query <- "
      INSERT INTO team_members 
      (employee_id, first_name, last_name, email, work_schedule, aws_day, department)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    "
    
    result <- poolWithTransaction(pool, function(con) {
      dbExecute(con, query, params = list(
        employee_id, first_name, last_name, email, 
        work_schedule, aws_day, department
      ))
      dbGetQuery(con, "SELECT last_insert_rowid() as id")
    })
    
    new_id <- result$id[1]
    log_event(paste("Added team member:", first_name, last_name, "(ID:", new_id, ")"), "INFO")
    return(new_id)
    
  }, error = function(e) {
    log_event(paste("Error adding team member:", e$message), "ERROR")
    return(NULL)
  })
}

#' Add Pay Period
#' 
#' Insert a new pay period
#' 
#' @param pool Database pool connection
#' @param period_name Character string with period name
#' @param period_number Integer with period number
#' @param start_date Date object with start date
#' @param end_date Date object with end date
#' @return Integer with new pay period ID or NULL on error
add_pay_period <- function(pool, period_name, period_number, start_date, end_date) {
  tryCatch({
    query <- "
      INSERT INTO pay_periods (period_name, period_number, start_date, end_date)
      VALUES (?, ?, ?, ?)
    "
    
    result <- poolWithTransaction(pool, function(con) {
      dbExecute(con, query, params = list(
        period_name, period_number, start_date, end_date
      ))
      dbGetQuery(con, "SELECT last_insert_rowid() as id")
    })
    
    new_id <- result$id[1]
    log_event(paste("Added pay period:", period_name, "(ID:", new_id, ")"), "INFO")
    return(new_id)
    
  }, error = function(e) {
    log_event(paste("Error adding pay period:", e$message), "ERROR")
    return(NULL)
  })
}

#' Get Attendance Summary
#' 
#' Generate summary statistics for attendance
#' 
#' @param pool Database pool connection
#' @param pay_period_id Integer pay period ID
#' @return Data frame with summary statistics
get_attendance_summary <- function(pool, pay_period_id) {
  query <- "
    SELECT 
      tm.full_name as team_member,
      COUNT(ar.id) as total_days,
      SUM(CASE WHEN ar.status_code IS NULL OR ar.status_code = '' THEN 1 ELSE 0 END) as present_days,
      SUM(CASE WHEN ar.status_code = 'AL' THEN 1 ELSE 0 END) as leave_days,
      SUM(CASE WHEN ar.status_code LIKE '%AWS%' THEN 1 ELSE 0 END) as aws_days,
      SUM(CASE WHEN ar.status_code IN ('FRE', 'FNM', 'FHLB', 'OF') THEN 1 ELSE 0 END) as external_days
    FROM team_members tm
    LEFT JOIN attendance_records ar ON tm.id = ar.team_member_id AND ar.pay_period_id = ?
    WHERE tm.is_active = 1
    GROUP BY tm.id, tm.full_name
    ORDER BY tm.last_name, tm.first_name
  "
  
  result <- safe_db_query(pool, query, list(pay_period_id))
  return(result)
}