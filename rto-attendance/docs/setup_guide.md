# Complete Project Structure Setup Guide

This guide shows you how to organize all the files for your RTO Attendance Tracking System GitHub repository.

## Step 1: Create the Directory Structure

First, create the complete folder structure:

```bash
mkdir -p rto-attendance/{config,data,database/migrations,docs,R,scripts,tests,www,screenshots,nginx,logs}
cd rto-attendance
```

## Step 2: File Organization

Here's exactly where each file should go:

```
rto-attendance/
├── app.R                           # Main Shiny application (from first artifact)
├── README.md                       # Project documentation
├── LICENSE                         # MIT License file
├── .gitignore                      # Git ignore rules
├── .env.example                    # Environment variables template
├── Dockerfile                      # Docker configuration
├── docker-compose.yml              # Docker Compose setup
├── renv.lock                       # R package dependencies
│
├── config/
│   ├── config.yml                  # Application configuration
│   └── database.yml.example        # Database config template
│
├── data/
│   ├── team_data.csv.example       # Sample team data
│   ├── pay_periods.csv.example     # Sample pay periods
│   └── README.md                   # Data directory documentation
│
├── database/
│   ├── schema.sql                  # Database schema
│   ├── seed_data.sql               # Initial data
│   └── migrations/                 # Database migrations
│       └── README.md               # Migration instructions
│
├── docs/
│   ├── deployment.md               # Deployment guide
│   ├── database_setup.md           # Database setup guide
│   ├── user_guide.md               # User documentation
│   ├── api_reference.md            # API documentation
│   └── troubleshooting.md          # Common issues and solutions
│
├── R/
│   ├── utils.R                     # Utility functions
│   ├── database.R                  # Database functions
│   ├── ui_components.R             # UI helper functions
│   └── server_functions.R          # Server helper functions
│
├── scripts/
│   ├── install_packages.R          # Package installation
│   ├── setup_database.R            # Database setup
│   ├── run_migrations.R            # Database migrations
│   ├── deploy.sh                   # Deployment script
│   ├── backup.sh                   # Backup script
│   └── monitor.sh                  # Monitoring script
│
├── tests/
│   ├── testthat.R                  # Test configuration
│   ├── test_utils.R                # Utility function tests
│   ├── test_database.R             # Database function tests
│   └── test_app.R                  # Application tests
│
├── www/
│   ├── custom.css                  # Custom CSS styles
│   ├── custom.js                   # Custom JavaScript
│   ├── favicon.ico                 # Application icon
│   └── logo.png                    # Organization logo
│
├── nginx/
│   ├── nginx.conf                  # Nginx configuration
│   └── ssl/                        # SSL certificates (gitignored)
│
├── logs/
│   └── .gitkeep                    # Keep directory in git
│
└── screenshots/
    ├── main-interface.png
    ├── codes-reference.png
    └── team-info.png
```

## Step 3: Quick Setup Commands

Run these commands to set up your project quickly:

```bash
# Clone or create your repository
git clone https://github.com/your-username/rto-attendance.git
# OR
git init rto-attendance

cd rto-attendance

# Create all directories
mkdir -p config data database/migrations docs R scripts tests www nginx/ssl logs screenshots

# Create placeholder files to preserve directory structure
touch logs/.gitkeep
touch www/.gitkeep
touch screenshots/.gitkeep

# Copy environment template
cp .env.example .env

# Make scripts executable
chmod +x scripts/*.sh
```

## Step 4: Initialize Git Repository

```bash
# Initialize git (if not already done)
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: RTO Attendance Tracking System

- Complete R Shiny application for attendance tracking
- Database schema and setup scripts
- Docker containerization support
- Comprehensive documentation
- Deployment guides for multiple platforms
- Automated backup and monitoring scripts"

# Add remote repository (replace with your GitHub URL)
git remote add origin https://github.com/your-username/rto-attendance.git

# Push to GitHub
git push -u origin main
```

## Step 5: Additional Files to Create

### Create sample data files:

**data/team_data.csv.example**
```csv
ID,TeamMember,WorkSchedule,Email,Department
1,John Doe,MF / 8-5:30 / 2nd Tues,john.doe@treasury.gov,RTO
2,Jane Smith,F / 6:30-3 / No,jane.smith@treasury.gov,RTO
```

**data/pay_periods.csv.example**
```csv
PayPeriod,StartDate,EndDate,Status
PP 17,2025-07-28,2025-08-08,Active
PP 18,2025-08-11,2025-08-22,Active
```

### Create additional R files:

**R/ui_components.R**
```r
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
```

**R/server_functions.R**
```r
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
```

**tests/testthat.R**
```r
# Test configuration for RTO Attendance Tracking

library(testthat)
library(dafs.oca.attendance)  # Your package name

test_check("dafs.oca.attendance")
```

**tests/test_utils.R**
```r
# Unit tests for utility functions

library(testthat)

test_that("generate_pay_period works correctly", {
  result <- generate_pay_period("2025-07-28")
  
  expect_equal(length(result$dates), 14)
  expect_equal(result$start_date, as.Date("2025-07-28"))
  expect_equal(result$end_date, as.Date("2025-08-10"))
  expect_equal(length(result$week1), 7)
  expect_equal(length(result$week2), 7)
})

test_that("validate_status_code works correctly", {
  expect_true(validate_status_code("AL"))
  expect_true(validate_status_code("AWS"))
  expect_true(validate_status_code(""))
  expect_true(validate_status_code(NA))
  expect_false(validate_status_code("INVALID"))
})

test_that("format_work_schedule cleans input", {
  expect_equal(format_work_schedule("  MF / 8-5:30  "), "MF / 8-5:30")
  expect_equal(format_work_schedule(""), "Standard")
  expect_equal(format_work_schedule(NA), "Standard")
})
```

**scripts/run_migrations.R**
```r
#!/usr/bin/env Rscript

# Run database migrations for RTO Attendance Tracking

library(DBI)
library(RSQLite)

cat("Running database migrations...\n")

# Connect to database
con <- dbConnect(RSQLite::SQLite(), "data/attendance.db")

# Create migrations table if it doesn't exist
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS schema_migrations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filename TEXT UNIQUE NOT NULL,
    applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )
")

# Get list of applied migrations
applied_migrations <- dbGetQuery(con, "SELECT filename FROM schema_migrations")$filename

# Get list of migration files
migration_files <- list.files("database/migrations", pattern = "\\.sql$", full.names = TRUE)
migration_files <- sort(migration_files)

if (length(migration_files) == 0) {
  cat("No migration files found.\n")
  dbDisconnect(con)
  quit()
}

# Apply new migrations
for (file in migration_files) {
  filename <- basename(file)
  
  if (!filename %in% applied_migrations) {
    cat("Applying migration:", filename, "\n")
    
    tryCatch({
      # Read and execute migration
      migration_sql <- readLines(file)
      migration_sql <- paste(migration_sql, collapse = "\n")
      
      # Split by semicolons and execute
      statements <- strsplit(migration_sql, ";")[[1]]
      for (stmt in statements) {
        stmt <- trimws(stmt)
        if (nchar(stmt) > 0 && !grepl("^--", stmt)) {
          dbExecute(con, stmt)
        }
      }
      
      # Record migration as applied
      dbExecute(con, "INSERT INTO schema_migrations (filename) VALUES (?)", 
                params = list(filename))
      
      cat("✓ Applied:", filename, "\n")
      
    }, error = function(e) {
      cat("✗ Failed to apply", filename, ":", e$message, "\n")
      stop("Migration failed")
    })
  } else {
    cat("• Already applied:", filename, "\n")
  }
}

dbDisconnect(con)
cat("All migrations completed successfully!\n")
```

**scripts/backup.sh**
```bash
#!/bin/bash

# Backup script for RTO Attendance Tracking System

set -e

# Configuration
BACKUP_DIR="/var/backups/dafs-attendance"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30
APP_DIR="/srv/shiny-server/rto-attendance"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting RTO Attendance Backup - $(date)${NC}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Database backup
echo -e "${YELLOW}Backing up database...${NC}"
if [ -f "$APP_DIR/data/attendance.db" ]; then
    cp "$APP_DIR/data/attendance.db" "$BACKUP_DIR/attendance_db_$DATE.db"
    gzip "$BACKUP_DIR/attendance_db_$DATE.db"
    echo "✓ Database backup completed"
else
    echo -e "${RED}✗ Database file not found${NC}"
fi

# Application files backup
echo -e "${YELLOW}Backing up application files...${NC}"
if [ -d "$APP_DIR" ]; then
    tar -czf "$BACKUP_DIR/app_files_$DATE.tar.gz" \
        -C "$(dirname $APP_DIR)" \
        "$(basename $APP_DIR)" \
        --exclude="logs/*.log" \
        --exclude="temp/*" \
        --exclude=".git"
    echo "✓ Application files backup completed"
else
    echo -e "${RED}✗ Application directory not found${NC}"
fi

# Configuration backup
echo -e "${YELLOW}Backing up configuration...${NC}"
if [ -f "$APP_DIR/config/config.yml" ]; then
    cp "$APP_DIR/config/config.yml" "$BACKUP_DIR/config_$DATE.yml"
    echo "✓ Configuration backup completed"
fi

# Clean old backups
echo -e "${YELLOW}Cleaning old backups...${NC}"
find "$BACKUP_DIR" -name "attendance_db_*.db.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "app_files_*.tar.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "config_*.yml" -mtime +$RETENTION_DAYS -delete

# Upload to cloud storage (uncomment and configure as needed)
# echo -e "${YELLOW}Uploading to cloud storage...${NC}"
# aws s3 cp "$BACKUP_DIR/" s3://your-backup-bucket/dafs-attendance/ --recursive --exclude "*" --include "*_$DATE.*"

# Backup verification
echo -e "${YELLOW}Verifying backups...${NC}"
backup_count=$(ls -1 "$BACKUP_DIR"/*_$DATE.* 2>/dev/null | wc -l)
if [ "$backup_count" -gt 0 ]; then
    echo "✓ $backup_count backup files created"
    ls -lh "$BACKUP_DIR"/*_$DATE.*
else
    echo -e "${RED}✗ No backup files created${NC}"
    exit 1
fi

echo -e "${GREEN}Backup completed successfully - $(date)${NC}"

# Log backup completion
echo "$(date): Backup completed successfully" >> "$BACKUP_DIR/backup.log"
```

**scripts/monitor.sh**
```bash
#!/bin/bash

# Monitoring script for RTO Attendance Tracking System

# Configuration
APP_URL="http://localhost:3838/rto-attendance/"
LOG_FILE="/var/log/dafs-attendance-monitor.log"
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
```

## Step 6: GitHub Repository Setup

### Create GitHub repository:

1. Go to GitHub.com and create a new repository named `rto-attendance`
2. Don't initialize with README (you already have one)
3. Copy the repository URL

### Push your code:

```bash
# Add GitHub as remote origin
git remote add origin https://github.com/your-username/rto-attendance.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Set up GitHub Actions (optional):

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: r-lib/actions/setup-r@v2
      with:
        r-version: '4.3.0'
        
    - name: Install system dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev
        
    - name: Install R dependencies
      run: |
        Rscript scripts/install_packages.R
        
    - name: Run tests
      run: |
        Rscript -e "testthat::test_dir('tests/')"
        
    - name: Check app loads
      run: |
        Rscript -e "shiny::runApp(port=3838, host='0.0.0.0', launch.browser=FALSE)" &
        sleep 10
        curl -f http://localhost:3838/ || exit 1
```

## Step 7: Documentation

Add these additional documentation files:

**docs/user_guide.md** - Complete user manual
**docs/api_reference.md** - API documentation if you add REST endpoints
**docs/troubleshooting.md** - Common issues and solutions

## Step 8: Final Checklist

Before publishing your repository:

- [ ] All sensitive information removed (passwords, API keys)
- [ ] `.gitignore` properly configured
- [ ] README.md is complete and accurate
- [ ] Database setup scripts work correctly
- [ ] Sample data files are provided
- [ ] Documentation is comprehensive
- [ ] Scripts are executable (`chmod +x scripts/*.sh`)
- [ ] Docker setup is tested
- [ ] License is appropriate for your organization

Your repository is now ready for GitHub and production deployment! 🚀