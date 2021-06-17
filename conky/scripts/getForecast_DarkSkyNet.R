#!/usr/bin/env Rscript

#### Gather weather from darksky.net

## FIXME this api will stop in the future

rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")

## other APIs
# https://darksky.net/dev
# https://www.apixu.com/

library(darksky)
library(data.table)
readRenviron("~/.Renviron")


dir.create(  "/dev/shm/WHEATHER/", recursive = T, showWarnings = F)
CURRENT_FL = "/dev/shm/WHEATHER/Current_DarkSky.Rds"
HOURLY_FL  = "/dev/shm/WHEATHER/Forecast_hourly_DarkSky.Rds"
DAILY_FL   = "/dev/shm/WHEATHER/Forecast_daily_DarkSky.Rds"
LOCATIO_FL = "/dev/shm/CONKY/last_location.dat"


## Resolve location to use
stopifnot(file.exists(LOCATIO_FL))
geo <- read.csv(LOCATIO_FL)
geo <- geo[!is.na( geo$Lat ) & !is.na( geo$Lng ),]
geo <- geo[order(geo$Dt), ]
loc <- tail(geo,1)


## get forecast for current location
res_fr <- get_current_forecast(latitude  = loc$Lat,
                               longitude = loc$Lng,
                               units     = "si",
                               extend    = "hourly",
                               add_json  = TRUE)
stopifnot(length( res_fr$hourly$time ) > 10)


#### parse current weather ####
if (file.exists(CURRENT_FL)) {
    curr <- readRDS(CURRENT_FL)
} else {
    curr <- data.frame()
}
curr <- rbind(data.table( curr ),
              data.table( res_fr$currently),
              fill = T)
saveRDS(curr, CURRENT_FL)
print(curr)



#### store daily and hourly
saveRDS(res_fr$daily,  DAILY_FL)
saveRDS(res_fr$hourly, HOURLY_FL)


# summary: Any summaries containing temperature or snow accumulation units will have their values in degrees Celsius or in centimeters (respectively).
# nearestStormDistance: Kilometers.
# precipIntensity: Millimeters per hour.
# precipIntensityMax: Millimeters per hour.
# precipAccumulation: Centimeters.
# temperature: Degrees Celsius.
# temperatureMin: Degrees Celsius.
# temperatureMax: Degrees Celsius.
# apparentTemperature: Degrees Celsius.
# dewPoint: Degrees Celsius.
# windSpeed: Meters per second.
# windGust: Meters per second.
# pressure: Hectopascals.
# visibility: Kilometers.
