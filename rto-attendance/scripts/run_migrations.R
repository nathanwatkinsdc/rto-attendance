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