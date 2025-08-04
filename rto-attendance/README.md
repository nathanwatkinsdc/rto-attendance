# RTO Attendance Tracking System

A modern R Shiny web application for tracking daily badge entry and attendance reporting, replacing traditional Excel spreadsheets with a collaborative, real-time solution.

![App Screenshot](screenshots/main-interface.png)

## Features

- 📅 **Multi-Pay Period Support** - Switch between different pay periods seamlessly
- 👥 **Real-time Collaboration** - Multiple users can edit simultaneously
- 📱 **Responsive Design** - Works on desktop, tablet, and mobile devices
- 🔄 **Auto-save** - Changes are automatically preserved
- 📊 **Interactive Tables** - Click-to-edit functionality like Excel
- 🏷️ **Built-in Reference** - Quick access to reason codes and team schedules
- 🎨 **Color-coded Interface** - Visual distinction between weeks and data types
- 🔍 **Search & Filter** - Find team members and information quickly

## Quick Start

### Prerequisites

- R (version 4.0.0 or higher)
- RStudio (recommended)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/rto-attendance.git
   cd rto-attendance
   ```

2. **Install required R packages**
   ```r
   source("scripts/install_packages.R")
   ```

3. **Set up the database**
   ```r
   source("scripts/setup_database.R")
   ```

4. **Run the application**
   ```r
   shiny::runApp()
   ```

The app will open in your default web browser at `http://localhost:3838`

## Project Structure

```
rto-attendance/
├── app.R                    # Main Shiny application
├── README.md               # This file
├── .gitignore             # Git ignore rules
├── renv.lock              # Package dependency lock file
├── config/
│   ├── config.yml         # Application configuration
│   └── database.yml       # Database configuration
├── data/
│   ├── team_data.csv      # Team member information
│   ├── pay_periods.csv    # Pay period definitions
│   └── sample_data.csv    # Sample attendance data
├── database/
│   ├── schema.sql         # Database schema
│   ├── seed_data.sql      # Initial data
│   └── migrations/        # Database migrations
├── docs/
│   ├── deployment.md      # Deployment guide
│   ├── database_setup.md  # Database setup guide
│   ├── user_guide.md      # User documentation
│   └── api_reference.md   # API documentation
├── R/
│   ├── utils.R            # Utility functions
│   ├── database.R         # Database functions
│   ├── ui_components.R    # UI helper functions
│   └── server_functions.R # Server helper functions
├── scripts/
│   ├── install_packages.R # Package installation
│   ├── setup_database.R   # Database setup
│   └── deploy.R           # Deployment script
├── tests/
│   ├── testthat.R         # Test configuration
│   └── test_functions.R   # Unit tests
├── www/
│   ├── custom.css         # Custom CSS styles
│   ├── custom.js          # Custom JavaScript
│   └── favicon.ico        # Application icon
└── screenshots/
    ├── main-interface.png
    ├── codes-reference.png
    └── team-info.png
```

## Configuration

### Team Data Setup

1. Edit `data/team_data.csv` with your team information:
   ```csv
   ID,TeamMember,WorkSchedule,Email,Department
   1,John Doe,MF / 8-5:30 / 2nd Tues,john.doe@agency.gov,Finance
   ```

2. Update pay periods in `data/pay_periods.csv`:
   ```csv
   PayPeriod,StartDate,EndDate,Status
   PP 17,2025-07-28,2025-08-08,Active
   ```

### Database Configuration

Edit `config/database.yml`:
```yaml
default:
  driver: "SQLite"
  database: "data/attendance.db"

production:
  driver: "PostgreSQL"
  host: "localhost"
  port: 5432
  database: "attendance_prod"
  username: "app_user"
  password: "secure_password"
```

## Deployment

### Local Development
```r
shiny::runApp(port = 3838)
```

### ShinyApps.io
```r
rsconnect::deployApp(account = "your-account")
```

### RStudio Connect
```r
rsconnect::deployApp(server = "your-connect-server")
```

### Docker
```bash
docker build -t rto-attendance .
docker run -p 3838:3838 rto-attendance
```

See [docs/deployment.md](docs/deployment.md) for detailed deployment instructions.

## Usage

### Basic Operations

1. **Select Pay Period**: Use the dropdown to switch between pay periods
2. **Edit Attendance**: Click any cell in the daily columns to edit
3. **Save Changes**: Use the "Save Changes" button or rely on auto-save
4. **View References**: Check the "Reference Codes" tab for code meanings

### Common Codes

- **AL**: Approved Leave (annual, sick, family sick leave, bereavement)
- **AWS**: Flex Day (* indicates switch from official work schedule)
- **FRE**: Working at Freddie Mac
- **FNM**: Working at Fannie Mae
- **JD**: Jury Duty
- **OST**: Off-Site Training

See [docs/user_guide.md](docs/user_guide.md) for complete documentation.

## Development

### Adding New Features

1. Create a new branch:
   ```bash
   git checkout -b feature/new-feature
   ```

2. Make your changes in the appropriate files:
   - UI changes: `R/ui_components.R`
   - Server logic: `R/server_functions.R`
   - Database: `R/database.R`

3. Test your changes:
   ```r
   source("tests/test_functions.R")
   ```

4. Submit a pull request

### Database Migrations

To add new database changes:
```r
source("scripts/create_migration.R")
```

### Testing

Run tests with:
```r
testthat::test_dir("tests/")
```

## Security Considerations

- ✅ Input validation on all user inputs
- ✅ SQL injection prevention using parameterized queries
- ✅ XSS protection through proper HTML escaping
- ✅ Authentication integration ready
- ⚠️ Configure HTTPS in production
- ⚠️ Set up proper database access controls

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Troubleshooting

### Common Issues

**App won't start**
- Check that all required packages are installed
- Verify database connection settings
- Check R version compatibility

**Database connection errors**
- Verify database server is running
- Check connection credentials
- Ensure database exists and schema is applied

**Performance issues**
- Check database indexes
- Monitor server resources
- Consider pagination for large datasets

See [docs/troubleshooting.md](docs/troubleshooting.md) for more solutions.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📧 Email: [your-email@agency.gov]
- 📋 Issues: [GitHub Issues](https://github.com/your-username/rto-attendance/issues)
- 📖 Documentation: [docs/](docs/)

## Changelog

### v1.0.0 (2025-08-04)
- Initial release
- Multi-pay period support
- Real-time editing
- Reference code integration
- Mobile responsive design

---

**Built with ❤️ for RTO team efficiency**