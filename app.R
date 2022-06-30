#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinyMobile)

library(stringr)
library(magrittr)
library(dplyr)
library(rvest)

library(leaflet)

# Define UI for application that draws a histogram
ui <- f7Page(title = "RllTrails",
             navbar = f7Navbar(title = "Create map of a custom AllTrails List",
                               hairline = TRUE,
                               shadow = TRUE),
             # toolbar = f7Toolbar(position = "bottom",f7Link(label = "AllTrails.com",href = "www.alltrails.com")),
             f7Shadow(intensit = 16,
                      hover = TRUE,
                      f7Card(title = "Create a map of an AllTrails List",
                             h5('1. Find an AllTrails List that you like'),
                             h5('2. Click "Share Link" (top-right corner on mobile)'),
                             h5('3. Copy the link to your clipboard'),
                             h5('4. Paste the link in the text box below'),
                             f7Text(inputId = "allTrailsLink","AllTrails link:",value = "https://www.alltrails.com/lists/castle-rock-7634ea6?u=i"),
                             br(),
                             tags$div(
                               leafletOutput(outputId = "allTrailsMap",height = "600",width = "100%")
                               # htmlOutput(outputId = "allTrailsMap")
                             ))),
             options = list(theme = "ios",
                            dark = TRUE),
             allowPWA = TRUE)


#   fluidPage(
#
#     # Application title
#     titlePanel("All Trails List Map"),
#
#     # Sidebar with a slider input for number of bins
#     sidebarLayout(
#         sidebarPanel(
#           textInput(inputId = "allTrailsLink",label = "All Trails Link:",value = "https://www.alltrails.com/lists/castle-rock-7634ea6?u=i")
#         ),
#         # Show a plot of the generated distribution
#         mainPanel(
#           tags$div(
#             htmlOutput(outputId = "allTrailsMap")
#           ),
#         )
#     )
# )

# Define server logic required to draw a histogram
server <- function(session,input, output) {

  output$allTrailsMap <-
    renderLeaflet({
      # renderUI({

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

      plt <- leaflet() %>%
        addTiles() %>%
        setView(lng = mean(c(min(dat1$lng),max(dat1$lng))),lat = mean(c(min(dat1$lat),max(dat1$lat))),zoom = 10) %>%
        addCircleMarkers(lng = dat1$lng,lat = dat1$lat,popup = dat1$popup)

      return(plt)

      # return(HTML(paste0('
      #            <iframe class="alltrails" src="',link,'" width="100%" height="800" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" title="AllTrails: Trail Guides and Maps for Hiking, Camping, and Running"></iframe>
      #            ')))

    })

}

# Run the application
shinyApp(ui = ui, server = server)
