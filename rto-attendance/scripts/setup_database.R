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