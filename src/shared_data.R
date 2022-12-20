# set of global variables used for setup of ui and server functions

library(crypto2)

available_coins <<- crypto_list(only_active = TRUE)
available_coins <<- available_coins[order(available_coins$rank), ] # sort by descending ranks
fiats <<- fiat_list()  # countries currencies that api permits
intervals <<- c("daily", "weekly", "monthly", "yearly")  # time intervals between data samples
plot_types <<- c("candlestick", "line")  # types of plot that can be chosen on app
pred_data <<- NULL  # prediction data (it contains time series data uploaded by user)
