# Database Setup Guide

This guide covers setting up the database for the RTO Attendance Tracking System. The application supports both SQLite (for development) and PostgreSQL (for production).

## Quick Setup (SQLite - Development)

For local development, SQLite is the easiest option:

```r
# Run this script to set up SQLite database
source("scripts/setup_database.R")
```

This will create `data/attendance.db` with all necessary tables and sample data.

## Production Setup (PostgreSQL)

### Prerequisites

- PostgreSQL 12 or higher
- Administrative access to PostgreSQL server
- psql command-line tool (optional but recommended)

### Step 1: Create Database and User

```sql
-- Connect as postgres superuser
sudo -u postgres psql

-- Create database
CREATE DATABASE attendance_prod;

-- Create application user
CREATE USER app_user WITH PASSWORD 'your_secure_password_here';

-- Grant permissions
GRANT CONNECT ON DATABASE attendance_prod TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT CREATE ON SCHEMA public TO app_user;

-- Exit psql
\q
```

### Step 2: Apply Database Schema

```bash
# Apply schema to the database
psql -h localhost -U app_user -d attendance_prod -f database/schema.sql

# Load seed data
psql -h localhost -U app_user -d attendance_prod -f database/seed_data.sql
```

### Step 3: Configure Database Connection

Edit `config/database.yml`:

```yaml
production:
  driver: "PostgreSQL"
  host: "your-db-server.com"
  port: 5432
  database: "attendance_prod"
  username: "app_user"
  password: "your_secure_password_here"
  pool_size: 10
  ssl_mode: "require"  # Use "disable" for local development
```

## Database Schema

### Tables Overview

The database consists of the following main tables:

- `team_members` - Employee information and work schedules
- `pay_periods` - Pay period definitions and date ranges  
- `attendance_records` - Daily attendance entries
- `reason_codes` - Reference table for attendance codes
- `audit_log` - Change tracking for compliance

### Detailed Schema

#### team_members
```sql
CREATE TABLE team_members (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    work_schedule TEXT,
    aws_day VARCHAR(20),
    department VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### pay_periods  
```sql
CREATE TABLE pay_periods (
    id SERIAL PRIMARY KEY,
    period_name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### attendance_records
```sql
CREATE TABLE attendance_records (
    id SERIAL PRIMARY KEY,
    team_member_id INTEGER REFERENCES team_members(id),
    pay_period_id INTEGER REFERENCES pay_periods(id),
    attendance_date DATE NOT NULL,
    status_code VARCHAR(10),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    UNIQUE(team_member_id, pay_period_id, attendance_date)
);
```

#### reason_codes
```sql
CREATE TABLE reason_codes (
    code VARCHAR(10) PRIMARY KEY,
    description TEXT NOT NULL,
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    display_order INTEGER DEFAULT 0
);
```

#### audit_log
```sql
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(20) NOT NULL, -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Database Migrations

### Creating New Migrations

When you need to modify the database schema:

```r
# Create a new migration file
source("scripts/create_migration.R")
# This creates: database/migrations/YYYY-MM-DD_HH-MM-SS_migration_name.sql
```

### Running Migrations

```r
# Apply all pending migrations
source("scripts/run_migrations.R")
```

### Migration File Format

```sql
-- Migration: Add department field to team_members
-- Created: 2025-08-04 10:30:00
-- Description: Add department tracking for organizational reporting

-- UP Migration
ALTER TABLE team_members ADD COLUMN department VARCHAR(50);
UPDATE team_members SET department = 'RTO' WHERE department IS NULL;

-- Create index for better performance
CREATE INDEX idx_team_members_department ON team_members(department);

-- DOWN Migration (for rollback)
-- ALTER TABLE team_members DROP COLUMN department;
-- DROP INDEX idx_team_members_department;
```

## Performance Optimization

### Recommended Indexes

```sql
-- Attendance records performance
CREATE INDEX idx_attendance_team_period ON attendance_records(team_member_id, pay_period_id);
CREATE INDEX idx_attendance_date ON attendance_records(attendance_date);
CREATE INDEX idx_attendance_status ON attendance_records(status_code);

-- Team members performance  
CREATE INDEX idx_team_members_active ON team_members(is_active);
CREATE INDEX idx_team_members_email ON team_members(email);

-- Pay periods performance
CREATE INDEX idx_pay_periods_dates ON pay_periods(start_date, end_date);
CREATE INDEX idx_pay_periods_active ON pay_periods(is_active);
```

### Database Maintenance

```sql
-- Regular maintenance tasks (run weekly)
VACUUM ANALYZE attendance_records;
VACUUM ANALYZE team_members;
VACUUM ANALYZE audit_log;

-- Check database size
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Backup and Recovery

### Automated Backups

```bash
#!/bin/bash
# backup_database.sh

DB_NAME="attendance_prod"
DB_USER="app_user"  
DB_HOST="localhost"
BACKUP_DIR="/path/to/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME \
  --no-password --verbose \
  --file="$BACKUP_DIR/attendance_backup_$DATE.sql"

# Compress backup
gzip "$BACKUP_DIR/attendance_backup_$DATE.sql"

# Keep only last 30 days of backups
find $BACKUP_DIR -name "attendance_backup_*.sql.gz" -mtime +30 -delete
```

### Restore from Backup

```bash
# Restore from backup
gunzip attendance_backup_20250804_103000.sql.gz
psql -h localhost -U app_user -d attendance_prod -f attendance_backup_20250804_103000.sql
```

## Security Configuration

### Database User Permissions

```sql
-- Minimal permissions for application user
REVOKE ALL ON DATABASE attendance_prod FROM app_user;
GRANT CONNECT ON DATABASE attendance_prod TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;

-- Table-specific permissions
GRANT SELECT, INSERT, UPDATE ON team_members TO app_user;
GRANT SELECT, INSERT, UPDATE ON attendance_records TO app_user;
GRANT SELECT ON reason_codes TO app_user;
GRANT SELECT ON pay_periods TO app_user;
GRANT INSERT ON audit_log TO app_user;

-- Sequence permissions (for auto-increment IDs)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_user;
```

### SSL Configuration

For production, always use SSL:

```yaml
# config/database.yml
production:
  # ... other settings ...
  ssl_mode: "require"
  ssl_cert: "/path/to/client-cert.pem"
  ssl_key: "/path/to/client-key.pem"
  ssl_ca: "/path/to/ca-cert.pem"
```

## Troubleshooting

### Common Issues

**Connection refused**
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Check if port is open
netstat -an | grep 5432
```

**Permission denied**
```sql
-- Grant missing permissions
GRANT ALL PRIVILEGES ON DATABASE attendance_prod TO app_user;
```

**Slow queries**
```sql
-- Enable query logging
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();

-- Check slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

### Health Check Queries

```sql
-- Check database connectivity
SELECT current_database(), current_user, version();

-- Check table sizes
SELECT 
    relname as table_name,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes
FROM pg_stat_user_tables;

-- Check recent attendance records
SELECT COUNT(*) as recent_records
FROM attendance_records 
WHERE created_at > NOW() - INTERVAL '7 days';
```

## Environment-Specific Setup

### Development Environment

```r
# .Renviron file
DATABASE_URL="sqlite:///data/attendance.db"
SHINY_PORT=3838
DEBUG=TRUE
```

### Production Environment

```r
# .Renviron file (use secure methods in production)
DATABASE_URL="postgresql://app_user:password@db-server:5432/attendance_prod"
SHINY_PORT=3838
DEBUG=FALSE
SSL_REQUIRED=TRUE
```

---

For additional help, contact the development team or check the main [README.md](../README.md) file.