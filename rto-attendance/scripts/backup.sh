#!/bin/bash

# Backup script for RTO Attendance Tracking System

set -e

# Configuration
BACKUP_DIR="/var/backups/rto-attendance"
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
# aws s3 cp "$BACKUP_DIR/" s3://your-backup-bucket/rto-attendance/ --recursive --exclude "*" --include "*_$DATE.*"

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