# Shiny app UI code

library(shiny)
library(shinythemes)
library(dplyr)
library(plotly)


source('shared_data.R') # get shared data

gym_ui <- fluidPage(
    theme = shinytheme("slate"),
    titlePanel("Auto Trader Gym"),
    sidebarLayout(
        sidebarPanel(
            dateRangeInput("date_range", "Date range", start = Sys.Date()-30, end = Sys.Date(), min = Sys.Date()-8*365, max = Sys.Date(), format = "yyyy-mm-dd"),
            selectInput("coin", "Selected coin", choices = available_coins$name, selected = available_coins$name[1], multiple = FALSE),
            selectInput("fiat", "Fiat currency", choices = paste(fiats$name, "|", fiats$symbol), selected = "USD", multiple = FALSE),
            selectInput("interval", "Time interval", choices = intervals, selected = intervals[1], multiple = FALSE),
            radioButtons("plot_type", "Plot type", plot_types),
            downloadButton("download", 'Save timeseries'),
            fileInput("pred_file", 'Upload your predictions (.csv)', accept='.csv')
        ),
        mainPanel(
            plotlyOutput("plot_timeseries", width = "100%", height = "600px")
        )
    )
)
