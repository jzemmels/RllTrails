#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
# library(shinyMobile)

library(stringr)
library(magrittr)
library(dplyr)
library(rvest)

library(leaflet)

ui <- shiny::fluidPage(title = "Create a map of an AllTrails List",
                       column(width = 12,
                              h3(strong("Create a map of an AllTrails List")),
                              h4('1. Find an AllTrails List that you like'),
                              h4('2. Click "Share Link" (top-right corner on mobile)'),
                              h4('3. Copy the link to your clipboard'),
                              h4('4. Paste the link in the text box below'),
                              # br(),
                              div(style = "display:inline-block;",
                                  textInput(inputId = "allTrailsLink",
                                            label = "AllTrails link:",
                                            width = "300px",
                                            value = "https://www.alltrails.com/lists/castle-rock-7634ea6?u=i")),
                              div(style = "display:inline-block;",
                                  numericInput(inputId = "mapHeight",
                                               label = "Map Height (pixels)",
                                               width = "90px",
                                               value = 800)),
                              div(style = "display:inline-block;",
                                  numericInput(inputId = "mapWidth",
                                               label = "Map Width (% of screen)",
                                               width = "90px",
                                               value = 100)),
                              tags$div(
                                tags$style("overflow-y: scroll;"),
                                uiOutput(outputId = "leafletMap")
                              ))
)

# Define server logic required to draw a histogram
server <- function(session,input, output) {

  output$leafletMap <- renderUI({

    leafletOutput(outputId = "allTrailsMap",
                  height = paste0(input$mapHeight,"px"),
                  width = paste0(input$mapWidth,"%"))

  })

  output$allTrailsMap <-
    renderLeaflet({

      req(input$allTrailsLink)

      link <- input$allTrailsLink %>%
        str_split("lists/") %>%
        .[[1]] %>%
        .[2] %>%
        str_remove("\\?.*$")

      link <- paste0("https://www.alltrails.com/widget/list/",link,"?u=i")

      pageData <- rvest::read_html(link)

      dat <- pageData %>%
        html_nodes('div[data-react-class="MapWidget"]') %>%
        html_attr("data-react-props")

      dat1 <- dat %>%
        jsonlite::fromJSON()  %>%
        .$list %>%
        tidyr::unnest("_geoloc") %>%
        dplyr::select(name,lat,lng,area_name,city_name,state_name,
                      duration_minutes,length,elevation_gain,difficulty_rating,route_type,
                      avg_rating,is_closed,is_private_property,
                      slug,popularity,profile_photo_url) %>%
        mutate(difficultyName = ifelse(difficulty_rating == 1,"Easy",
                                       ifelse(difficulty_rating == 3,"Moderate",
                                              "Hard")),
               popup = paste0('
        <img src = "',profile_photo_url,'" width = "150"/>
        <br/><strong>',name,'</strong>, ',route_type,' route
        <br/>',round(duration_minutes/60,2),' hours, ',difficultyName,'
        <br/>',round(length/1609,2),' miles, ',round(elevation_gain/1609,2),' mile elevation gain
        <br/>
        <a target="_blank" rel="noopener noreferrer" href="https://www.alltrails.com/',slug,'"> AllTrails Link </a>'))

      plt <- leaflet(height = input$mapHeight) %>%
        addTiles() %>%
        setView(lng = mean(c(min(dat1$lng),max(dat1$lng))),lat = mean(c(min(dat1$lat),max(dat1$lat))),zoom = 10) %>%
        addCircleMarkers(lng = dat1$lng,lat = dat1$lat,popup = dat1$popup)

      return(plt)

    })

}

# Run the application
shinyApp(ui = ui, server = server)
