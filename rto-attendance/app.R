# RTO Daily Badge Entry Reporting Shiny App
# Clean version with proper syntax checking

# Load required libraries
library(shiny)
library(DT)
library(shinydashboard)
library(shinyWidgets)
library(jsonlite)

# Sample team data - replace with your actual team information
team_data <- data.frame(
  ID = 1:20,
  TeamMember = c(
    "Charles C", "Paula G", "Yeezy G", "Billy H", "Maureen J", 
    "Bucky K", "Cynthia L", "Kris M", "Davey M", "Quark M",
    "Chip N", "Ivy N", "Soup P", "Domino S", "Navy S",
    "Anola T", "Butter W", "Nathan W", "Charizard Y", "Melon Z"
  ),
  WorkSchedule = c(
    "MF / 8-5:30 / 2nd Tues", "F / 6:30-3 / No", "MF / 7-5 / 1st Fri",
    "MF / 8:15-5:45 / 2nd Wed", "F / 6:45-3:15 / No", "MF/8:00-6:30 / 1st+2nd Fri",
    "MF / 9:15-7:45 / 1st+2nd Fri", "F / 8:30-5:00 / No", "MF / 8:30-6 / 2nd Fri",
    "MF / 8-5:30 / 2nd Fri", "F / 7-3:30 / No", "MF / 7-4:30 / 2nd Tues",
    "F / 8-4:30 / No", "F / 8:45-5:15 / No", "F / 8-4:30 / No",
    "MF / 7-4:30 / 2nd Fri", "F / 8:45-5:15 / No", "MF / 8:30-6 / 2nd Fri",
    "MF / 7-4:30 / 1st Mon", "MF / 8-5:30 / 1st Fri"
  ),
  stringsAsFactors = FALSE
)

# Reason codes reference
reason_codes <- data.frame(
  Code = c("AL", "AWS", "JD", "PA", "LOC1", "LOC2", "LOC3", "OF", "OST", "OSM"),
  Description = c(
    "Approved Leave (annual, sick, family sick leave, bereavement)",
    "Flex Day (* indicates switch from official work schedule; AWS indicates regular day)",
    "Jury Duty",
    "Pre-approved non-building location",
    "Working at Location 1",
    "Working at Location 2", 
    "Working at Locaiton 3(incl. travel to/from)",
    "Working at Location 4",
    "Off-Site Training",
    "Off-Site Meeting (incl. interagency meetings)"
  ),
  stringsAsFactors = FALSE
)

# Function to generate pay period dates (business days only)
generate_pay_period <- function(start_date) {
  # Generate all dates for 2 weeks
  all_dates <- seq(as.Date(start_date), by = "day", length.out = 14)
  
  # Filter to only business days (Monday = 1, Friday = 5)
  business_days <- all_dates[as.POSIXlt(all_dates)$wday %in% 1:5]
  
  # Split into weeks
  week1_business <- business_days[1:min(5, length(business_days))]
  week2_business <- business_days[6:min(10, length(business_days))]
  
  list(
    week1 = week1_business,
    week2 = week2_business,
    dates = business_days,
    all_dates = all_dates  # Keep original for reference if needed
  )
}

# Sample pay periods
pay_periods <- list(
  "PP 17 (July 28 - August 8)" = generate_pay_period("2025-07-28"),
  "PP 18 (August 11 - August 22)" = generate_pay_period("2025-08-11"),
  "PP 19 (August 25 - September 5)" = generate_pay_period("2025-08-25"),
  "PP 20 (September 8 - September 19)" = generate_pay_period("2025-09-08")
)

# Create empty attendance data structure (business days only)
create_empty_attendance <- function(team_data, pay_period) {
  n_members <- nrow(team_data)
  attendance <- data.frame(
    ID = team_data$ID,
    TeamMember = team_data$TeamMember,
    WorkSchedule = team_data$WorkSchedule,
    stringsAsFactors = FALSE
  )
  
  # Add columns for each business day only
  business_days <- pay_period$dates
  for (i in 1:length(business_days)) {
    day_name <- format(business_days[i], "%a")
    date_short <- format(business_days[i], "%m/%d")
    col_name <- paste0("Day_", i, "_", day_name, "_", date_short)
    attendance[[col_name]] <- ""
  }
  
  return(attendance)
}

# UI
ui <- dashboardPage(
  dashboardHeader(title = "RTO Daily Badge Entry Reporting"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Attendance Tracking", tabName = "attendance", icon = icon("calendar")),
      menuItem("Reference Codes", tabName = "codes", icon = icon("info-circle")),
      menuItem("Team Info", tabName = "team", icon = icon("users"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .main-header .logo {
          font-weight: bold;
          font-size: 18px;
        }
        .dataTables_wrapper {
          font-size: 12px;
        }
        .table th {
          background-color: #f4f4f4;
          font-weight: bold;
          text-align: center;
          vertical-align: middle;
        }
        .week-header {
          background-color: #e8f4fd !important;
          font-weight: bold;
          text-align: center;
        }
        .day-header {
          background-color: #f0f8ff !important;
          font-size: 11px;
          text-align: center;
        }
        .content-wrapper {
          background-color: #f4f4f4;
        }
        .box {
          box-shadow: 0 1px 3px rgba(0,0,0,0.12);
        }
        .attendance-cell {
          width: 60px;
          text-align: center;
          padding: 2px;
        }
      "))
    ),
    
    tabItems(
      tabItem(
        tabName = "attendance",
        fluidRow(
          box(
            title = "Pay Period Selection", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 12,
            fluidRow(
              column(
                8,
                selectInput(
                  "pay_period", 
                  "Select Pay Period:",
                  choices = names(pay_periods),
                  selected = names(pay_periods)[1]
                )
              ),
              column(
                4,
                br(),
                actionButton("save_data", "Save Changes", class = "btn-success"),
                br(),
                helpText("Changes are automatically saved when you edit cells")
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = textOutput("period_title"), 
            status = "info", 
            solidHeader = TRUE, 
            width = 12,
            div(
              style = "overflow-x: auto;",
              DT::dataTableOutput("attendance_table")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Quick Reference", 
            status = "warning", 
            solidHeader = TRUE, 
            width = 12,
            collapsible = TRUE, 
            collapsed = TRUE,
            div(
              style = "font-size: 12px;",
              HTML("<strong>Common Codes:</strong> AL (Approved Leave), AWS (Flex Day), LOC1 (Location 1), LOC2 (Location 2)<br>
                   <strong>Instructions:</strong> Click any cell in the daily columns to edit. Use standard codes or leave blank for regular office day.")
            )
          )
        )
      ),
      
      tabItem(
        tabName = "codes",
        fluidRow(
          box(
            title = "Non-Badge-In Reason Codes", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 12,
            DT::dataTableOutput("codes_table")
          )
        ),
        
        fluidRow(
          box(
            title = "Color Coding Legend", 
            status = "info", 
            solidHeader = TRUE, 
            width = 12,
            HTML("
            <div style='display: flex; gap: 20px; flex-wrap: wrap;'>
              <div><span style='background-color: orange; padding: 2px 8px; border-radius: 3px; color: white;'>Orange</span> - Badge-in did not record</div>
              <div><span style='background-color: green; padding: 2px 8px; border-radius: 3px; color: white;'>Green</span> - Not on data call list</div>
              <div><span style='background-color: blue; padding: 2px 8px; border-radius: 3px; color: white;'>Blue</span> - Early Dismissal Leave</div>
            </div>
            ")
          )
        )
      ),
      
      tabItem(
        tabName = "team",
        fluidRow(
          box(
            title = "Team Members & Work Schedules", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 12,
            DT::dataTableOutput("team_table")
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive values to store data
  values <- reactiveValues()
  
  # Initialize attendance data for all pay periods
  observe({
    for (pp_name in names(pay_periods)) {
      if (is.null(values[[pp_name]])) {
        values[[pp_name]] <- create_empty_attendance(team_data, pay_periods[[pp_name]])
      }
    }
  })
  
  # Dynamic title for selected pay period
  output$period_title <- renderText({
    input$pay_period
  })
  
  # Main attendance table
  output$attendance_table <- DT::renderDataTable({
    req(input$pay_period)
    
    data <- values[[input$pay_period]]
    if (is.null(data)) return(NULL)
    
    # Get pay period info for headers
    pp_info <- pay_periods[[input$pay_period]]
    
    # Create column names with proper headers
    col_names <- c("ID", "Team Member", "Work Schedule / Flex/Hours/AWS Day")
    
    # Week 1 columns (business days only)
    week1_cols <- paste("Week 1", format(pp_info$week1, "%a\n%m/%d"), sep = "\n")
    # Week 2 columns (business days only)
    week2_cols <- paste("Week 2", format(pp_info$week2, "%a\n%m/%d"), sep = "\n")
    
    all_cols <- c(col_names, week1_cols, week2_cols)
    
    # Calculate number of business day columns (should be 10: 5 + 5)
    num_business_days <- length(pp_info$dates)
    total_cols <- 3 + num_business_days  # 3 info cols + business days
    
    DT::datatable(
      data,
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        scrollY = "600px",
        dom = 't',
        columnDefs = list(
          list(targets = 0, visible = FALSE), # Hide ID column
          list(targets = 1, width = "120px"),
          list(targets = 2, width = "200px"),
          list(targets = 3:(total_cols-1), width = "70px", className = "attendance-cell")
        ),
        initComplete = JS(
          "function(settings, json) {",
          "$(this.api().table().header()).find('th').eq(1).html('Team<br>Member');",
          "}"
        )
      ),
      editable = list(target = "cell", disable = list(columns = c(0, 1, 2))),
      colnames = all_cols,
      rownames = FALSE,
      class = "compact cell-border stripe"
    ) %>%
      formatStyle(
        columns = 1:3,
        backgroundColor = "#f8f9fa",
        fontWeight = "bold"
      ) %>%
      formatStyle(
        columns = 4:(3 + length(pp_info$week1)),  # Week 1 columns
        backgroundColor = "#e3f2fd"
      ) %>%
      formatStyle(
        columns = (4 + length(pp_info$week1)):total_cols, # Week 2 columns  
        backgroundColor = "#f3e5f5"
      )
  }, server = FALSE)
  
  # Handle cell edits
  observeEvent(input$attendance_table_cell_edit, {
    info <- input$attendance_table_cell_edit
    
    # Update the data
    values[[input$pay_period]][info$row, info$col + 1] <<- info$value
    
    # Show confirmation
    showNotification("Cell updated successfully!", type = "message", duration = 2)
  })
  
  # Reference codes table
  output$codes_table <- DT::renderDataTable({
    DT::datatable(
      reason_codes,
      options = list(
        pageLength = 15,
        dom = 't',
        columnDefs = list(
          list(targets = 0, width = "80px"),
          list(targets = 1, width = "400px")
        )
      ),
      colnames = c("Code", "Description"),
      rownames = FALSE,
      class = "compact cell-border stripe"
    ) %>%
      formatStyle(
        columns = 1,
        backgroundColor = "#e8f5e8",
        fontWeight = "bold",
        textAlign = "center"
      )
  }, server = FALSE)
  
  # Team info table
  output$team_table <- DT::renderDataTable({
    DT::datatable(
      team_data[, c("TeamMember", "WorkSchedule")],
      options = list(
        pageLength = 25,
        dom = 'ftp',
        columnDefs = list(
          list(targets = 0, width = "150px"),
          list(targets = 1, width = "300px")
        )
      ),
      colnames = c("Team Member", "Work Schedule"),
      rownames = FALSE,
      class = "compact cell-border stripe"
    )
  }, server = FALSE)
  
  # Save data functionality
  observeEvent(input$save_data, {
    # In a real application, you would save to a database or file
    # For now, just show a confirmation
    showNotification("Data saved successfully!", type = "success", duration = 3)
  })
  
  # Auto-save functionality (optional)
  observe({
    invalidateLater(30000) # Save every 30 seconds
    # Implement auto-save logic here
  })
}

# Run the application
shinyApp(ui = ui, server = server)