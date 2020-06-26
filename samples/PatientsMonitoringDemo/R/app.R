source("req.R")
library("shiny")
library("tidyr")
library("tidyverse")
library("dplyr")
library("ggplot2")
source("ecgGraph.R")
source("html_js_utils.R")


library("shinydashboard")

STATUS_URL =  "http://localhost:8014/health/Status/ports/input/0/tuples" 
#STATUS_URL = "https://syss161.pok.stglabs.ibm.com:30104/streams/jobs/9/health/Status/ports/input/0/tuples"
ECG_URL = "http://localhost:8014/health/WaveformData/ports/input/0/tuples?&partition="
#ECG_URL = "https://syss161.pok.stglabs.ibm.com:30104/streams/jobs/9/health/WaveformData/ports/input/0/tuples?partition="#=patient-8&partition=8310-5

gdata = reactiveVal()
currentPatient = ""
GRAPH_DATA = data.frame()

ui <- dashboardPage(
  # Application title

  dashboardHeader(title = "Patient Dashboard"),

  dashboardSidebar(
      h3("Filters"),
      checkboxInput('alerts','Patients with alerts only')
    ),

    dashboardBody(
      get_html_css_includes(),
      tags$style(type="text/css", ".recalculating {opacity: 1.0;}"),
      fluidRow(
         column(width=12, uiOutput("patient_grid"))
      )
    )
)



# Define server logic to show current time, update every second ----
server <- function(input, output, session) {
  
    refreshPatientTimer <- reactiveTimer(10000)
    server_data <- reactiveValues()
  
    observe({
      # auto refresh
      refreshPatientTimer()
      server_data$mydf <- get_all_patients_as_df(input$alerts)
    })

    output$patient_grid <- renderUI ({
      HTML(generate_patient_grid(server_data$mydf))
    })


    observeEvent(input$closeDialog, {
      
        currentPatient <<- ""
        GRAPH_DATA = data.frame()
        gdata(NULL)
        invalidate_ecg()
        removeModal()
    })


      
    plotModal <- function(message, patientId) {

      modalDialog(
          fluidRow(
            column(width=6, plotOutput("ecg",  height="200px")),
            column(width=6, message)),
            hr(),
              infoBoxOutput("hr1", width=6),
             infoBoxOutput("ABp", width=6),
             infoBoxOutput("SP02", width=6), 
              infoBoxOutput("Temp", width=6),
            
            title = patientId,
            
            footer = tagList(
              actionButton("closeDialog", "OK")
            )
          )
    }



    # when a row in the table is clicked, show popup
    observeEvent(input$cell, {
      row_index = input$cell$idx
      clicked_patient =  server_data$mydf[row_index, ]
      hasAlerts = clicked_patient$alert
      message = p("No alerts")
      msg_as_array = unlist(clicked_patient$messages)
      if (hasAlerts == TRUE) {
        if (length(msg_as_array) == 1){
          message = tagList(tags$h3("Alerts"), p(msg_as_array[1]))
        } else {
          message = tagList(tags$h3("Alerts"),
                            tags$ul(class="alertMessages", 
                                     lapply(msg_as_array, tags$li, class="alertMessages")
                                  )
                      )
        }
      }

      invalidate_ecg()
      GRAPH_DATA <<- data.frame()
      name = input$cell$name
      currentPatient <<- clicked_patient$patientId
      modal = plotModal(message, name)
      showModal(modal)
    })
  
  
    output$ecg <- renderPlot({
        updateInterval = 1000
        invalidateLater(updateInterval, session)
          # auto refresh
          if (currentPatient != "") {
            latest = get_next_ecg_data(ECG_URL, currentPatient)
            if(nrow(latest) > 0){
                GRAPH_DATA <<- bind_rows(GRAPH_DATA, latest)
                GRAPH_DATA = select(GRAPH_DATA, time, value)
                gdata(GRAPH_DATA) #update our reactive variable
                ggplot(gdata(), aes(x=time, y=value)) +
                            geom_line(colour='black') +
                            get_theme()
            } else {
              gdata(NULL)
            }
          } else {
            gdata(NULL)
          }
      })
 output$hr1 <- renderInfoBox({
    infoBox(
      "H   aaR", "80%", color="green", icon=icon("heartbeat")
    )
  }) 
  output$ABp <- renderInfoBox({
    infoBox(
      "ABp", "80%", color="blue", icon=icon("dashboard", lib="glyphicon")
    )
  })
   output$SP02 <- renderInfoBox({
    infoBox(
      "SP02", "80%", color = "yellow", icon= icon("tint")
    )
  })
   output$Temp <- renderInfoBox({
    infoBox(
      "Temperature", "29", color="maroon", icon=icon("thermometer-three-quarters")
    )
  })

}

addResourcePath("www", paste(getwd(), "www", sep='/'))

# Create Shiny app ----
shinyApp(ui, server,options=list(host="0.0.0.0", port=8015))
