# RllTrails
A mobile-friendly shiny app to visualize custom AllTrails Lists. (Forgive the terrible name.)

The app is available here: [https://jzemmels.shinyapps.io/RllTrails/](https://jzemmels.shinyapps.io/RllTrails/)

The map UI on the Android version of AllTrails sucks (at least on my phone) and the app doesn't allow you to visualize a user-created list of trails on a map.
I built this app using the `shiny` and `shinyMobile` R packages; the former constructs interactive web applications and the latter converts an application to a mobile-friendly interface.
After pasting an AllTrails list link into the text box, I use the `rvest` package to pull the necessary trail data from a JSON file buried in the AllTrails source.
Other `tidyverse` packages are used to convert the trail data to a data frame that can be visualized on an interactive `leaflet` map.
Clicking on a trail marker shows summary information of the trail including the length, duration, rating, AllTrails link, and thumbnail.
