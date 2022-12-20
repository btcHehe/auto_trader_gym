# Main application file, group all modules and starts the Shiny app

# import modules
source('ui.R')
source('server.R')

shinyApp(gym_ui, gym_server)  # run application