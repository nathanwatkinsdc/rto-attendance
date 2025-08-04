# Server Functions for RTO Attendance Tracking

#' Handle Cell Edit
#' 
#' Process attendance table cell edits
handle_cell_edit <- function(pool, edit_info, pay_period_id, team_data, updated_by = "user") {
  tryCatch({
    row <- edit_info$row
    col <- edit_info$col
    value <- edit_info$value
    
    # Get team member ID from row
    team_member_id <- team_data$ID[row]
    
    # Calculate date from column (columns 4+ are attendance days)
    if (col >= 4) {
      day_offset <- col - 4  # 0-based day offset
      pay_period_info <- get_pay_period_by_id(pool, pay_period_id)
      attendance_date <- pay_period_info$start_date + day_offset
      
      # Save attendance record
      success <- save_attendance_record(
        pool, team_member_id, pay_period_id, 
        attendance_date, value, updated_by = updated_by
      )
      
      if (success) {
        showNotification("Attendance updated successfully", type = "success")
      } else {
        showNotification("Error updating attendance", type = "error")
      }
    }
    
  }, error = function(e) {
    log_event(paste("Error handling cell edit:", e$message), "ERROR")
    showNotification("Error processing update", type = "error")
  })
}

#' Generate Attendance Report
#' 
#' Create attendance summary report
generate_attendance_report <- function(pool, pay_period_id) {
  summary_data <- get_attendance_summary(pool, pay_period_id)
  
  if (is.null(summary_data) || nrow(summary_data) == 0) {
    return("No attendance data available for this pay period.")
  }
  
  # Calculate totals
  totals <- list(
    total_employees = nrow(summary_data),
    total_days_recorded = sum(summary_data$total_days, na.rm = TRUE),
    total_present_days = sum(summary_data$present_days, na.rm = TRUE),
    total_leave_days = sum(summary_data$leave_days, na.rm = TRUE),
    total_aws_days = sum(summary_data$aws_days, na.rm = TRUE)
  )
  
  return(totals)
}