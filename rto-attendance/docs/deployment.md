# Deployment Guide

This guide covers various deployment options for the RTO Attendance Tracking System, from local development to production environments.

## Quick Deployment Options

| Option | Best For | Difficulty | Cost |
|--------|----------|------------|------|
| [Local Development](#local-development) | Testing, Development | Easy | Free |
| [ShinyApps.io](#shinyappsio) | Small teams, Quick setup | Easy | $0-$299/month |
| [RStudio Connect](#rstudio-connect) | Enterprise, Advanced features | Medium | Contact vendor |
| [Docker](#docker-deployment) | Flexible hosting | Medium | Variable |
| [Cloud VM](#cloud-virtual-machine) | Full control | Hard | $20-200/month |

## Local Development

Perfect for testing and development.

### Prerequisites
- R 4.0+
- RStudio (recommended)

### Setup
```r
# Clone and setup
git clone https://github.com/your-username/rto-attendance.git
cd rto-attendance

# Install dependencies
source("scripts/install_packages.R")

# Setup database
source("scripts/setup_database.R")

# Run application
shiny::runApp(port = 3838)
```

Access at: `http://localhost:3838`

## ShinyApps.io

Easiest cloud deployment option from RStudio.

### Prerequisites
- ShinyApps.io account
- `rsconnect` package

### Step 1: Setup Account
```r
# Install rsconnect
install.packages("rsconnect")

# Configure account (get token from shinyapps.io dashboard)
rsconnect::setAccountInfo(
  name = "your-account-name",
  token = "your-token",
  secret = "your-secret"
)
```

### Step 2: Prepare for Deployment
```r
# Create deployment configuration
cat('
# Specify R version
r_version: "4.3.0"

# Specify packages to include
packages:
  - shiny
  - DT
  - shinydashboard
  - shinyWidgets
  - jsonlite
  - DBI
  - RSQLite
  - pool

# Files to include
include:
  - app.R
  - R/
  - data/
  - www/
  - config/
', file = "manifest.json")
```

### Step 3: Deploy
```r
# Deploy application
rsconnect::deployApp(
  appName = "rto-attendance",
  account = "your-account-name",
  forceUpdate = TRUE
)
```

### Step 4: Configure Settings
- Set instance size (small/medium/large)
- Configure custom domain (paid plans)
- Set up authentication if needed

## RStudio Connect

Enterprise-grade deployment platform.

### Prerequisites
- RStudio Connect server
- Admin access or deployment permissions

### Step 1: Prepare Application
```r
# Create connect deployment manifest
cat('
---
title: "RTO Attendance Tracking"
description: "Internal attendance tracking system"
tags: ["attendance", "internal", "dashboard"]
schedule: false
access: "logged_in"  # or "all" for public
---
', file = "manifest.rmd")
```

### Step 2: Deploy
```r
# Connect to your RStudio Connect server
rsconnect::addServer(
  url = "https://your-connect-server.com",
  name = "company-connect"
)

# Deploy
rsconnect::deployApp(
  server = "company-connect",
  appName = "rto-attendance",
  account = "your-account"
)
```

### Step 3: Configure
- Set up authentication (LDAP/SAML)
- Configure email notifications
- Set up scheduled reports
- Configure resource limits

## Docker Deployment

Flexible containerized deployment.

### Step 1: Create Dockerfile
```dockerfile
# Use rocker/shiny as base image
FROM rocker/shiny:4.3.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shiny', 'DT', 'shinydashboard', 'shinyWidgets', 'jsonlite', 'DBI', 'RSQLite', 'RPostgreSQL', 'pool', 'config', 'yaml'), repos='https://cran.rstudio.com/')"

# Copy application files
COPY . /srv/shiny-server/dafs-attendance/

# Set permissions
RUN chown -R shiny:shiny /srv/shiny-server/dafs-attendance/

# Expose port
EXPOSE 3838

# Run application
CMD ["/usr/bin/shiny-server"]
```

### Step 2: Create Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3838:3838"
    environment:
      - DATABASE_URL=postgresql://app_user:password@db:5432/attendance
    depends_on:
      - db
    volumes:
      - ./data:/srv/shiny-server/dafs-attendance/data
      - ./logs:/var/log/shiny-server
    restart: unless-stopped

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: attendance
      POSTGRES_USER: app_user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/schema.sql:/docker-entrypoint-initdb.d/1-schema.sql
      - ./database/seed_data.sql:/docker-entrypoint-initdb.d/2-seed.sql
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_data:
```

### Step 3: Deploy
```bash
# Build and run
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f app
```

## Cloud Virtual Machine

Full control deployment on cloud providers.

### AWS EC2 Deployment

#### Step 1: Launch Instance
```bash
# Launch Ubuntu 22.04 LTS instance
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type t3.medium \
  --key-name your-key-pair \
  --security-group-ids sg-xxxxxxxxx \
  --subnet-id subnet-xxxxxxxxx \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DAFS-Attendance}]'
```

#### Step 2: Setup Server
```bash
# Connect to instance
ssh -i your-key.pem ubuntu@your-instance-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install R
sudo apt install -y r-base r-base-dev

# Install system dependencies
sudo apt install -y \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libpq-dev \
  nginx \
  postgresql \
  postgresql-contrib

# Install Shiny Server
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
sudo dpkg -i shiny-server-1.5.20.1002-amd64.deb
```

#### Step 3: Deploy Application
```bash
# Clone repository
git clone https://github.com/your-username/rto-attendance.git
sudo cp -r rto-attendance /srv/shiny-server/

# Install R packages
sudo R -e "install.packages(c('shiny', 'DT', 'shinydashboard', 'shinyWidgets', 'jsonlite', 'DBI', 'RPostgreSQL', 'pool'))"

# Setup database
sudo -u postgres createdb attendance
sudo -u postgres psql -c "CREATE USER app_user WITH PASSWORD 'secure_password';"
sudo -u postgres psql -d attendance -f /srv/shiny-server/rto-attendance/database/schema.sql

# Start services
sudo systemctl enable shiny-server
sudo systemctl start shiny-server
```

### Google Cloud Platform

#### Step 1: Create VM
```bash
# Create instance
gcloud compute instances create dafs-attendance \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=e2-medium \
  --zone=us-central1-a \
  --tags=http-server,https-server
```

#### Step 2: Setup (similar to AWS steps above)

### Azure VM

#### Step 1: Create VM
```bash
# Create resource group
az group create --name dafs-attendance-rg --location eastus

# Create VM
az vm create \
  --resource-group dafs-attendance-rg \
  --name dafs-attendance-vm \
  --image UbuntuLTS \
  --admin-username azureuser \
  --generate-ssh-keys \
  --size Standard_B2s
```

## SSL/HTTPS Setup

### Let's Encrypt (Free SSL)
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Nginx Configuration
```nginx
# /etc/nginx/sites-available/dafs-attendance
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3838;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Monitoring and Maintenance

### Health Checks
```r
# Create health check endpoint
# Add to app.R
observe({
  # Health check route
  if (session$clientData$url_pathname == "/health") {
    # Return simple health status
    session$sendCustomMessage("health-check", list(status = "ok"))
  }
})
```

### Log Management
```bash
# Setup log rotation
sudo cat > /etc/logrotate.d/shiny-server << EOF
/var/log/shiny-server/*.log {
    daily
    missingok
    rotate 52
    compress
    notifempty
    create 0644 shiny shiny
    postrotate
        systemctl reload shiny-server
    endscript
}
EOF
```

### Backup Strategy
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"

# Database backup
pg_dump attendance > "$BACKUP_DIR/db_$DATE.sql"

# Application backup
tar -czf "$BACKUP_DIR/app_$DATE.tar.gz" /srv/shiny-server/rto-attendance

# Upload to cloud storage (optional)
aws s3 cp "$BACKUP_DIR/" s3://your-backup-bucket/ --recursive
```

## Troubleshooting

### Common Issues

**Application won't start**
```bash
# Check Shiny Server logs
sudo tail -f /var/log/shiny-server.log

# Check application logs
sudo tail -f /var/log/shiny-server/rto-attendance-*
```

**Database connection issues**
```bash
# Test database connection
psql -h localhost -U app_user -d attendance

# Check PostgreSQL status
sudo systemctl status postgresql

# Check connection limits
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
```

**Performance issues**
```bash
# Monitor system resources
htop

# Check Shiny Server processes
ps aux | grep shiny

# Monitor database performance
sudo -u postgres psql -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

**Memory issues**
```bash
# Increase Shiny Server memory limits
sudo nano /etc/shiny-server/shiny-server.conf

# Add:
# run_as shiny;
# server {
#   listen 3838;
#   location / {
#     site_dir /srv/shiny-server;
#     log_dir /var/log/shiny-server;
#     directory_index on;
#     app_init_timeout 60;
#     app_idle_timeout 600;
#   }
# }
```

## Security Considerations

### Firewall Setup
```bash
# Ubuntu/Debian
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### Application Security
```r
# Add to app.R for basic security headers
addResourcePath('www', 'www')

# Security headers
tags$head(
  tags$meta(`http-equiv` = "X-Frame-Options", content = "DENY"),
  tags$meta(`http-equiv` = "X-Content-Type-Options", content = "nosniff"),
  tags$meta(`http-equiv` = "X-XSS-Protection", content = "1; mode=block")
)
```

### Database Security
```sql
-- Limit database connections
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';

-- Enable logging
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_statement = 'mod';

-- Reload configuration
SELECT pg_reload_conf();
```

## Scaling and Load Balancing

### Multiple Shiny Processes
```bash
# /etc/shiny-server/shiny-server.conf
run_as shiny;

server {
  listen 3838;
  
  location / {
    site_dir /srv/shiny-server;
    log_dir /var/log/shiny-server;
    directory_index on;
    
    # Multiple processes
    app_init_timeout 60;
    app_idle_timeout 600;
    simple_scheduler 10;  # 10 processes
  }
}
```

### Load Balancer Setup (Nginx)
```nginx
# /etc/nginx/sites-available/load-balancer
upstream shiny_backend {
    server 127.0.0.1:3838;
    server 127.0.0.1:3839;
    server 127.0.0.1:3840;
}

server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://shiny_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Maintenance Scripts

### Automated Deployment Script
```bash
#!/bin/bash
# deploy.sh

set -e

echo "Starting deployment..."

# Pull latest code
git pull origin main

# Backup current version
sudo cp -r /srv/shiny-server/rto-attendance /srv/shiny-server/rto-attendance.backup.$(date +%Y%m%d_%H%M%S)

# Copy new version
sudo cp -r . /srv/shiny-server/rto-attendance/

# Set permissions
sudo chown -R shiny:shiny /srv/shiny-server/rto-attendance/

# Run database migrations
Rscript scripts/run_migrations.R

# Restart services
sudo systemctl restart shiny-server

# Health check
sleep 10
curl -f http://localhost:3838/rto-attendance/ || exit 1

echo "Deployment completed successfully!"
```

### System Monitoring Script
```bash
#!/bin/bash
# monitor.sh

# Check if Shiny Server is running
if ! systemctl is-active --quiet shiny-server; then
    echo "Shiny Server is down! Restarting..."
    sudo systemctl restart shiny-server
    echo "Shiny Server restarted at $(date)" >> /var/log/monitor.log
fi

# Check database connectivity
if ! pg_isready -h localhost -U app_user; then
    echo "Database is unreachable!"
    echo "Database issue at $(date)" >> /var/log/monitor.log
fi

# Check disk space
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "Disk usage is above 80%: ${DISK_USAGE}%"
    echo "High disk usage: ${DISK_USAGE}% at $(date)" >> /var/log/monitor.log
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ $MEMORY_USAGE -gt 85 ]; then
    echo "Memory usage is above 85%: ${MEMORY_USAGE}%"
    echo "High memory usage: ${MEMORY_USAGE}% at $(date)" >> /var/log/monitor.log
fi
```

### Automated Backup Script
```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p $BACKUP_DIR

# Database backup
echo "Backing up database..."
pg_dump -h localhost -U app_user attendance > "$BACKUP_DIR/db_backup_$DATE.sql"
gzip "$BACKUP_DIR/db_backup_$DATE.sql"

# Application files backup
echo "Backing up application files..."
tar -czf "$BACKUP_DIR/app_backup_$DATE.tar.gz" /srv/shiny-server/rto-attendance

# Upload to cloud storage (uncomment and configure as needed)
# aws s3 cp "$BACKUP_DIR/db_backup_$DATE.sql.gz" s3://your-backup-bucket/database/
# aws s3 cp "$BACKUP_DIR/app_backup_$DATE.tar.gz" s3://your-backup-bucket/application/

# Clean old backups
find $BACKUP_DIR -name "db_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "app_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $DATE"
```

## Environment-Specific Configurations

### Development Environment
```yaml
# config/development.yml
default:
  database:
    driver: "SQLite"
    database: "data/attendance.db"
  
  app:
    debug: true
    port: 3838
    auto_reload: true
    
  logging:
    level: "DEBUG"
    file: "logs/app.log"
```

### Production Environment
```yaml
# config/production.yml
default:
  database:
    driver: "PostgreSQL"
    host: "db.internal.company.com"
    port: 5432
    database: "attendance_prod"
    username: "app_user"
    password: !ENV ${DB_PASSWORD}
    pool_size: 10
    
  app:
    debug: false
    port: 3838
    auto_reload: false
    
  logging:
    level: "INFO"
    file: "/var/log/shiny-server/app.log"
    
  security:
    ssl_required: true
    session_timeout: 3600
    max_file_size: "10MB"
```

## Final Checklist

Before going live, ensure:

- [ ] Database is properly secured and backed up
- [ ] SSL certificates are installed and configured
- [ ] Firewall rules are in place
- [ ] Monitoring and alerting are configured
- [ ] Backup strategy is tested
- [ ] Performance testing is completed
- [ ] User authentication is working
- [ ] Error handling is implemented
- [ ] Documentation is up to date
- [ ] Team training is completed

---

For specific deployment questions or issues, refer to the troubleshooting section or contact the development team.