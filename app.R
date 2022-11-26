library(tidyverse)
library(shiny)
library(globe4r)
delay_od<- read_csv("data/delay_od.csv")


ui<- fluidPage(
  tags$hr(),
  sliderInput("n", "top # delayed routes", value = 20,
              min = 0,
              max = 150),
  globeOutput("globe"),
  dataTableOutput('table')
)


server<- function(input, output){

  df<- reactive({rbind(delay_od %>%
                  select(origin, latitude_origin, longitude_origin, average_delay) %>%
                  rename(airport = origin, latitude = latitude_origin, longitude = longitude_origin) %>%
                    top_n(input$n, average_delay),
                delay_od %>%
                  select(dest, latitude_destination, longitude_destination, average_delay) %>%
                  rename(airport = dest, latitude = latitude_destination, longitude = longitude_destination) %>%
                  top_n(input$n, average_delay)) %>%
    unique()}) 
  
  output$globe<- renderGlobe({
    create_globe(delay_od %>% 
                   top_n(input$n, average_delay)) %>%
      globe_pov(39, -90, 0.5) %>%
      globe_arcs(coords(start_lat = latitude_origin,
                        start_lon = longitude_origin,
                        end_lat = latitude_destination,
                        end_lon = longitude_destination)) %>%
      globe_hex(coords(latitude_destination, 
                       longitude_destination, 
                       altitude =0.002)) %>%
      arcs_altitude_scale(0.2) %>%
      globe_labels(coords(latitude, longitude, text = airport), data = df())
  })
  output$table <- renderDataTable(delay_od %>% 
                                    select(od, average_delay) %>%
                                    top_n(input$n, average_delay),
                                  options = list(
                                    pageLength = 5))
}

shinyApp(ui, server)

