#!/bin/bash

# Monitoring script for RTO Attendance Tracking System

# Configuration
APP_URL="http://localhost:3838/rto-attendance/"
LOG_FILE="/var/log/rto-attendance-monitor.log"
ALERT_EMAIL="admin@your-domain.com"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to send alert
send_alert() {
    local subject="$1"
    local message="$2"
    
    echo "$message" | mail -s "$subject" "$ALERT_EMAIL" 2>/dev/null || true
    log_message "ALERT: $subject - $message"
}

# Check if Shiny Server is running
check_shiny_server() {
    if ! systemctl is-active --quiet shiny-server; then
        send_alert "Shiny Server Down" "Shiny Server is not running. Attempting restart..."
        sudo systemctl restart shiny-server
        sleep 10
        
        if systemctl is-active --quiet shiny-server; then
            log_message "INFO: Shiny Server restarted successfully"
        else
            send_alert "Shiny Server Restart Failed" "Failed to restart Shiny Server"
        fi
    fi
}

# Check application accessibility
check_app_accessibility() {
    if ! curl -f -s "$APP_URL" > /dev/null; then
        send_alert "Application Unreachable" "Cannot access application at $APP_URL"
        return 1
    fi
    return 0
}

# Check database connectivity
check_database() {
    if [ -f "/srv/shiny-server/rto-attendance/data/attendance.db" ]; then
        # Simple SQLite check
        if ! sqlite3 "/srv/shiny-server/rto-attendance/data/attendance.db" "SELECT 1;" > /dev/null 2>&1; then
            send_alert "Database Error" "Cannot query SQLite database"
        fi
    else
        send_alert "Database Missing" "Database file not found"
    fi
}

# Check disk space
check_disk_space() {
    local usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$usage" -gt 90 ]; then
        send_alert "Critical Disk Space" "Disk usage is at ${usage}%"
    elif [ "$usage" -gt 80 ]; then
        log_message "WARNING: Disk usage is at ${usage}%"
    fi
}

# Check memory usage
check_memory() {
    local usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    
    if [ "$usage" -gt 90 ]; then
        send_alert "High Memory Usage" "Memory usage is at ${usage}%"
    elif [ "$usage" -gt 85 ]; then
        log_message "WARNING: Memory usage is at ${usage}%"
    fi
}

# Check log file size
check_log_size() {
    local log_dir="/var/log/shiny-server"
    
    if [ -d "$log_dir" ]; then
        # Check for log files larger than 100MB
        find "$log_dir" -name "*.log" -size +100M -exec basename {} \; | while read log_file; do
            log_message "WARNING: Large log file detected: $log_file"
        done
    fi
}

# Main monitoring routine
main() {
    log_message "INFO: Starting monitoring check"
    
    check_shiny_server
    check_app_accessibility
    check_database
    check_disk_space
    check_memory
    check_log_size
    
    log_message "INFO: Monitoring check completed"
}

# Run main function
main

# If running as a cron job, you might want to add:
# 0 */5 * * * /path/to/scripts/monitor.sh