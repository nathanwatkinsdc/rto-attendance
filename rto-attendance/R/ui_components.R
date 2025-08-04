# UI Component Functions for RTO Attendance Tracking

#' Create Pay Period Selector
#' 
#' Generate dropdown for pay period selection
create_pay_period_selector <- function(pay_periods) {
  choices <- setNames(pay_periods$id, pay_periods$period_name)
  
  selectInput(
    "pay_period",
    "Select Pay Period:",
    choices = choices,
    selected = choices[1]
  )
}

#' Create Attendance Table Headers
#' 
#' Generate column headers for attendance table
create_attendance_headers <- function(pay_period_info) {
  base_headers <- c("ID", "Team Member", "Work Schedule")
  
  # Week 1 headers
  week1_headers <- paste(
    "Week 1",
    format(pay_period_info$week1, "%a %m/%d"),
    sep = "\n"
  )
  
  # Week 2 headers
  week2_headers <- paste(
    "Week 2", 
    format(pay_period_info$week2, "%a %m/%d"),
    sep = "\n"
  )
  
  return(c(base_headers, week1_headers, week2_headers))
}

#' Create Status Badge
#' 
#' Generate colored badge for status codes
create_status_badge <- function(code, description = NULL) {
  if (is.na(code) || code == "") {
    return(tags$span("Present", class = "badge badge-success"))
  }
  
  # Color mapping for different codes
  colors <- list(
    "AL" = "warning",
    "AWS" = "info", 
    "FRE" = "danger",
    "FNM" = "danger",
    "JD" = "secondary"
  )
  
  color_class <- colors[[code]] %||% "secondary"
  
  tags$span(
    code,
    class = paste("badge badge", color_class, sep = "-"),
    title = description
  )
}