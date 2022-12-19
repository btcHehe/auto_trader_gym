library(shiny)
library(RColorBrewer)
library(dplyr)
library(crypto2)
library(plotly)
library(lubridate)
library(shinythemes)

available_coins <- crypto_list(only_active = TRUE)
available_coins <- available_coins[order(available_coins$rank), ] # sort by descending ranks
fiats <- fiat_list()
intervals <- c("daily", "weekly", "monthly", "yearly")
plot_types <- c("candlestick", "line")
pred_data <- NULL

ui <- fluidPage(
    theme = shinytheme("slate"),
    titlePanel("Auto Trader Gym"),
    sidebarLayout(
        sidebarPanel(
            dateRangeInput("date_range", "Date range", start = Sys.Date()-30, end = Sys.Date(), min = Sys.Date()-8*365, max = Sys.Date(), format = "yyyy-mm-dd"),
            selectInput("coin", "Selected coin", choices = available_coins$name, selected = available_coins$name[1], multiple = FALSE),
            selectInput("fiat", "Fiat currency", choices = paste(fiats$name, "|", fiats$symbol), selected = "USD", multiple = FALSE),
            selectInput("interval", "Time interval", choices = intervals, selected = intervals[1], multiple = FALSE),
            radioButtons("plot_type", "Plot type", plot_types),
            textInput("save_file", 'Filename: '),
            actionButton("save_button", 'Save timeseries'),
            fileInput("pred_file", 'Upload your predictions (.csv)', accept='.csv')
        ),
        mainPanel(
            plotlyOutput("plot_timeseries", width = "100%", height = "600px")
        )
    )
)

server <- function(input, output, session) {
    
    # update data frame with info selected by user
    coin_data <- reactive({
        selected_coin <- available_coins[available_coins$name == input$coin, ]
        split_sel <- strsplit(input$fiat, split = " ")
        selected_convert <- split_sel[[1]][length(split_sel[[1]])]
        selected_start <- gsub('-', '', input$date_range[1])
        selected_end <- gsub('-', '', input$date_range[2])
        selected_interval <- input$interval
        
        coin_dataframe <- crypto_history(coin_list = selected_coin,
                                    convert = selected_convert,
                                    start_date = selected_start,
                                    end_date = selected_end,
                                    interval = selected_interval)
        coin_dataframe['timestamp'] <- as.POSIXct(coin_dataframe$timestamp)
        colnames(coin_dataframe)[1] <- 'Date'
        high_low <- data.frame(coin_dataframe$high, coin_dataframe$low)
        mean_price <- rowMeans(high_low)
        coin_dataframe['mean'] <- mean_price
        coin_dataframe
    })
    
    # button handler
    observeEvent(input$save_button, {
        filename <- gsub(' ', '', paste(input$save_file, '.csv'))
        df <- coin_data()
        df_save <- data.frame(df$Date, df$high, df$low, df$mean)
        colnames(df_save) <- c('date', 'high', 'low', 'mean')
        write.csv(df_save, filename, row.names = FALSE)
        showModal(modalDialog(
            title = "Info",
            paste('File', filename, 'saved successfully')
        ))
    })
    
    
    output$plot_timeseries <- renderPlotly({
        file <- input$pred_file

        if (!is.null(file) && is.null(pred_data)) {
            pred_data <- read.csv(file$datapath)
        }

        data <- coin_data()
        split_sel <- strsplit(input$fiat, split = " ")
        selected_convert <- split_sel[[1]]
        if (input$plot_type == "candlestick") {
            plt <- data %>% plot_ly(x = ~Date, type='candlestick',
                                    open = ~open, close = ~close,
                                    high = ~high, low = ~low)
            plt <- plt %>% layout(title = 'Price',
                                  plot_bgcolor="rgb(40, 44, 52)", paper_bgcolor="rgb(40, 44, 52)",
                                  font = list(color="white"), xaxis = list(gridcolor="white"), yaxis = list(gridcolor="white"))
        } else if (input$plot_type == "line") {
            plt <- plot_ly(data, type = 'scatter', mode = 'lines') %>%
                                    add_trace(x = ~Date, y = ~high, name = 'high', line = list(color = 'green')) %>%
                                    add_trace() %>%
                                    add_trace(x = ~Date, y = ~low, name = 'low', line = list(color = 'red')) %>%
                                    add_trace() %>%
                                    add_trace(x = ~Date, y = ~mean, name = 'mean', line = list(color = 'cyan'))
            plt <- plt %>% layout(title = 'Price',
                                  plot_bgcolor="rgb(40, 44, 52)", paper_bgcolor="rgb(40, 44, 52)",
                                  font = list(color="white"), xaxis = list(gridcolor="white"), yaxis = list(gridcolor="white"))
        }

    })
    
}

shinyApp(ui, server)