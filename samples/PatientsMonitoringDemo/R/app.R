source("req.R")
library("shiny")
library("tidyr")
library("tidyverse")
library("dplyr")
library("ggplot2")
source("ecgGraph.R")

gdata = reactiveVal()

currentPatient =""
graph_data = data.frame()

ui <- fluidPage(
  # Application title
  titlePanel("Patient monitoring dashboard"),

  sidebarLayout(
    sidebarPanel(
      h3("Filters"),
      checkboxInput('alerts','Patients with alerts only'),
    ),

    mainPanel(
      DT::dataTableOutput("mytable1")
    )
  )
)


dataframe1 <- data.frame(Player = rep(c("Lebron", "Steph", "Harden",
                                        "Giannis"), each = 30),
                         Game = rep(1:30, 4),
                         Points = round(runif(120, 15, 40), 0))

reload <- function(filtr){
  status_url =  "http://localhost:8014/health/Status/ports/input/0/tuples" 
    vitals_url = "http://localhost:8014/health/VitalsData/ports/input/0/tuples"
    wave_url = "http://localhost:8014/health/WaveformData/ports/input/0/tuples?partition="
    mydf <- poll(status_url)$patientMap
    packed = pivot_longer(mydf, starts_with("patient-"), names_to = "id")
    packed = packed$value
    if (filtr){
      packed  = dplyr::filter(packed, alert == TRUE)
    }
    return(packed)
    
}

# Define server logic to show current time, update every second ----
server <- function(input, output, session) {
    playerFilt <- reactive({
    dataframe1 %>%
      filter(Player == input$player)
  })

  
  autoInvalidate <- reactiveTimer(10000)
  server_data <- reactiveValues()
  
  observe({
    # auto refresh
    autoInvalidate()
    server_data$mydf <- reload(input$alerts)
  })

  output$mytable1 <- DT::renderDataTable({
      
    DT::datatable(server_data$mydf, rownames=FALSE,  selection = 'single')
  })

plotModal <- function(message, patientId) {
  modalDialog(
      plotOutput("ecg"),
         message,
         title = paste("Patient " , patientId),
        
        footer = tagList(
          actionButton("closeDialog", "OK")
        )
      )
}

 observeEvent(input$closeDialog, {
     currentPatient <<- ""
      graph_data = data.frame()
      gdata(NULL)
     invalidate_ecg()
     removeModal()
    })



  observeEvent(input$mytable1_cell_clicked, {
    info = input$mytable1_cell_clicked
    # do nothing if not clicked yet, or the clicked cell is not in the 1st column
    if (is.null(info$value)) {
      return()
    }
  
    row = server_data$mydf[info$row, ]
    hasAlerts = row$alert
    message = p("No alerts")
    if (hasAlerts == TRUE) {
      message = p(toString(unlist(row$messages)))
    }
    invalidate_ecg()
    graph_data <<- data.frame()

    currentPatient <<- row$patientId
    showModal(plotModal(message, row$patientId))
  })


   output$ecg <- renderPlot({
      updateInterval = 1000
      invalidateLater(updateInterval, session)


        # auto refresh
        if (currentPatient != "") {
          latest =refresh(currentPatient)
          if(nrow(latest) > 0){
              graph_data <<- bind_rows(graph_data, latest)
              gdata(graph_data)
              
                    ggplot(gdata(), aes(x=time, y=value)) +
                          geom_line(colour='black') +
                          get_theme()
          }
        } else {
          gdata(NULL)
        }
    })

}

# Create Shiny app ----
shinyApp(ui, server,options=list(host="0.0.0.0", port=8015))
