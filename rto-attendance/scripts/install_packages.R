# scripts/install_packages.R
#!/usr/bin/env Rscript

# Install required packages for RTO Attendance Tracking System

cat("Installing required R packages...\n")

# List of required packages
packages <- c(
  "shiny",
  "DT", 
  "shinydashboard",
  "shinyWidgets",
  "jsonlite",
  "DBI",
  "RSQLite",
  "RPostgreSQL", 
  "pool",
  "config",
  "yaml",
  "lubridate",
  "dplyr",
  "readr",
  "stringr",
  "purrr",
  "testthat"
)

# Function to install packages if not already installed
install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    cat(paste("Installing", pkg, "...\n"))
    install.packages(pkg, repos = "https://cran.rstudio.com/")
    if (!require(pkg, character.only = TRUE)) {
      stop(paste("Failed to install package:", pkg))
    }
  } else {
    cat(paste(pkg, "is already installed.\n"))
  }
}

# Install packages
for (pkg in packages) {
  install_if_missing(pkg)
}

cat("\nAll packages installed successfully!\n")

# Verify installation
cat("\nVerifying package versions:\n")
for (pkg in packages) {
  version <- packageVersion(pkg)
  cat(paste(pkg, ":", version, "\n"))
}

cat("\nPackage installation complete!\n")

---

# scripts/setup_database.R
#!/usr/bin/env Rscript

# Database setup script for RTO Attendance Tracking System

library(DBI)
library(RSQLite)
library(dplyr)
library(readr)

cat("Setting up RTO Attendance Database...\n")

# Create data directory if it doesn't exist
if (!dir.exists("data")) {
  dir.create("data")
}

# Connect to SQLite database (creates if doesn't exist)
con <- dbConnect(RSQLite::SQLite(), "data/attendance.db")

# Read and execute schema
cat("Creating database schema...\n")
schema_sql <- readLines("database/schema.sql")
schema_sql <- paste(schema_sql, collapse = "\n")

# Split by semicolons and execute each statement
statements <- strsplit(schema_sql, ";")[[1]]
for (stmt in statements) {
  stmt <- trimws(stmt)
  if (nchar(stmt) > 0) {
    dbExecute(con, stmt)
  }
}

# Insert seed data
cat("Inserting seed data...\n")
seed_sql <- readLines("database/seed_data.sql")
seed_sql <- paste(seed_sql, collapse = "\n")

statements <- strsplit(seed_sql, ";")[[1]]
for (stmt in statements) {
  stmt <- trimws(stmt)
  if (nchar(stmt) > 0 && !grepl("^--", stmt)) {
    tryCatch({
      dbExecute(con, stmt)
    }, error = function(e) {
      cat("Warning:", e$message, "\n")
    })
  }
}

# Verify setup
cat("Verifying database setup...\n")

# Check tables
tables <- dbListTables(con)
cat("Created tables:", paste(tables, collapse = ", "), "\n")

# Check some data
if ("team_members" %in% tables) {
  team_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM team_members")
  cat("Team members count:", team_count$count, "\n")
}

if ("reason_codes" %in% tables) {
  codes_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM reason_codes")
  cat("Reason codes count:", codes_count$count, "\n")
}

# Close connection
dbDisconnect(con)

cat("Database setup completed successfully!\n")
cat("Database location: data/attendance.db\n")