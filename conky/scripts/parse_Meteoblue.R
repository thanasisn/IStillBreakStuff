#!/usr/bin/env Rscript

#### This is executed by conky/scripts/meteoblue_get.sh
## just parse and prepare data for use

rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
readRenviron("~/.Renviron")


dir.create(  "/dev/shm/WHEATHER/", recursive = T, showWarnings = F)
CURRENT_FL = "/dev/shm/WHEATHER/Forecast_meteoblue.Rds"
INPUT_FL   = "/dev/shm/WHEATHER/meteoblue.json"
KEEP_MAX   = 1000

library(rjson)

## get weather data
data <- fromJSON(file = INPUT_FL)
forc <- data.frame( data$data_day )

## check we got data to use
stopifnot(length( forc$time ) > 2)

forc$source <- "meteoblue"
forc$time   <- as.Date(forc$time)

names(forc)[names(forc) == "time"] <- "day"

## load previous data
if (file.exists(CURRENT_FL)) {
    Forecast_data <- readRDS(CURRENT_FL)
} else {
    Forecast_data <- data.frame()
}

## new data will overwrite older forecasts
if ( dim(Forecast_data)[1] > 0 & dim(forc)[1] > 2 ) {
    ## starting day of current forecast
    new_date <- min(forc$day)
    ## this data are obsolete now
    sel_del      <- Forecast_data$day >= new_date
    Forecast_data <- Forecast_data[ !sel_del, ]
}

## store data for later use
Forecast_data <- plyr::rbind.fill( Forecast_data, forc )
Forecast_data <- Forecast_data[order(Forecast_data$day),]
Forecast_data <- unique(Forecast_data)
Forecast_data <- tail(Forecast_data, KEEP_MAX)

saveRDS( Forecast_data, CURRENT_FL, compress = "xz" )

