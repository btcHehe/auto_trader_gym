# Shiny app server code

library(shiny)
library(plotly)

source('shared_data.R') # get shared data

gym_server <- function(input, output, session) {
    # update data frame with info selected by user and data downloaded from API
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
    
    # save button handler
    output$download <- downloadHandler(
        filename = 'timeseries.csv', 
        content = function (filename) {
            df <- coin_data()
            df_save <- data.frame(df$Date, df$high, df$low, df$mean)
            colnames(df_save) <- c('date', 'high', 'low', 'mean')
            write.csv(df_save, filename, row.names = FALSE)
        }
    )
    
    # render selected plot
    output$plot_timeseries <- renderPlotly({
        # load data uploaded by user
        file <- input$pred_file
        if (!is.null(file) && is.null(pred_data)) {
            pred_data <- read.csv(file$datapath)
        }
        
        # get data from API
        data <- coin_data()
        split_sel <- strsplit(input$fiat, split = " ")
        selected_convert <- split_sel[[1]]
        if (input$plot_type == "candlestick") { # plot candlestick chart
            plt <- data %>% plot_ly(x = ~Date, type='candlestick',
                                    open = ~open, close = ~close,
                                    high = ~high, low = ~low)
            plt <- plt %>% layout(title = 'Price',
                                  plot_bgcolor="rgb(40, 44, 52)", paper_bgcolor="rgb(40, 44, 52)",
                                  font = list(color="white"), xaxis = list(gridcolor="white"), yaxis = list(gridcolor="white"))
        } else if (input$plot_type == "line") { # plot line charts
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