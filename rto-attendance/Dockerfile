# Dockerfile
FROM rocker/shiny:4.3.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    libpq-dev \
    libsasl2-dev \
    libldap2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c( \
    'shiny', \
    'DT', \
    'shinydashboard', \
    'shinyWidgets', \
    'jsonlite', \
    'DBI', \
    'RSQLite', \
    'RPostgreSQL', \
    'pool', \
    'config', \
    'yaml', \
    'lubridate', \
    'dplyr' \
), repos='https://cran.rstudio.com/')"

# Create app directory
RUN mkdir -p /srv/shiny-server/dafs-attendance

# Copy application files
COPY . /srv/shiny-server/dafs-attendance/

# Set working directory
WORKDIR /srv/shiny-server/dafs-attendance

# Set permissions
RUN chown -R shiny:shiny /srv/shiny-server/dafs-attendance

# Create necessary directories
RUN mkdir -p logs data

# Expose port
EXPOSE 3838

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3838/dafs-attendance/ || exit 1

# Run application
CMD ["/usr/bin/shiny-server"]