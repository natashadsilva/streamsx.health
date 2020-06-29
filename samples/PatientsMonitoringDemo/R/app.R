source("req.R")
library("shiny")
library("tidyr")
library("tidyverse")
library("dplyr")
library("ggplot2")
source("ecgGraph.R")
source("html_js_utils.R")


library("shinydashboard")

# STREAMS_URL  = "https://syss161.pok.stglabs.ibm.com:30104/streams/jobs/14/"

STREAMS_URL =  "http://localhost:8014/" 
STATUS_ENDPOINT = "health/Status/ports/input/0/tuples"
ECG_ENDPOINT = "health/WaveformData/ports/input/0/tuples?partition="

STATUS_URL = paste(STREAMS_URL, STATUS_ENDPOINT, sep="")
print(STATUS_URL)
ECG_URL = paste(STREAMS_URL, ECG_ENDPOINT, sep="")
print(ECG_URL)

SECONDS_TO_SHOW = 20
#ECG_URL = "https://syss161.pok.stglabs.ibm.com:30104/streams/jobs/9/health/WaveformData/ports/input/0/tuples?partition="#=patient-8&partition=8310-5

gdata = reactiveVal()
currentPatient = ""
GRAPH_DATA = data.frame()
GRAPH_TIMER = 0
LAST_ROW_OF_DATA = 0
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
        GRAPH_TIMER =0
        gdata(NULL)
        invalidate_ecg()
        removeModal()
    })


      
    plotModal <- function(message, patientId) {

      modalDialog(
          fluidRow(
            column(width=12, plotOutput("ecg",  height="250px")),
            column(width=4, message)),
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
        updateInterval = 1100
        invalidateLater(updateInterval, session)
          # auto refresh
          if (currentPatient != "") {
       
            batch_of_readings = get_next_ecg_data(ECG_URL, currentPatient)
            latest = batch_of_readings$data


            num_rows = nrow(latest)
            # column names in latest are
            # value, time, window,
            # Every row in the GRAPH_DATA data frame belongs
            # to a window in WINDOW LIST..
            # e.g window list could be (1,3, 6)
            if(num_rows > 0){
                windows = batch_of_readings$windows
                print(windows)
                WINDOW_LIST <<- append(WINDOW_LIST, unique(windows))

                # WINDOW LIST has list of windows, each window
                # is a second of readings
                # we only want to show readings from the last 6 Seconds
                #of ECG data, so we only want the last 6 windows
                # What we want is a queue of size 6 but there is no
                # such feature in R (to my knowledge)
                # So if we have more than 6 windows,
                # we have more than 6 seconds of data
                if (length(WINDOW_LIST) > SECONDS_TO_SHOW) {
                    # if we have more than 6 seconds of data
                     age_out_index = length(WINDOW_LIST) - SECONDS_TO_SHOW
                     # age out index is the start index in list of windows to keep
                    splice = c(age_out_index: length(WINDOW_LIST))
                    # remove all other windows
                    WINDOW_LIST <<- WINDOW_LIST[splice]
                }
                # merge latest graph data with existing data
                GRAPH_DATA <<- bind_rows(GRAPH_DATA, latest)
                # remove any rows that are older than 6 seconds ago
                GRAPH_DATA <<- filter (GRAPH_DATA, window %in% WINDOW_LIST)

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
#list of current windows that will be displayed
WINDOW_LIST = c()
addResourcePath("www", paste(getwd(), "www", sep='/'))

# Create Shiny app ----
shinyApp(ui, server,options=list(host="0.0.0.0", port=8015))
