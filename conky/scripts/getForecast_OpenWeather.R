#!/usr/bin/env Rscript

rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")

#### Get weather forecast from OpenWeatherMAP for current location

library(owmr)
readRenviron("~/.Renviron")

dir.create(  "/dev/shm/WHEATHER/", recursive = T, showWarnings = F)
CURRENT_FL = "/dev/shm/WHEATHER/Forecast_OpenWeather.Rds"
LOCATIO_FL = "/dev/shm/CONKY/last_location.dat"


## Resolve location to ask weather for
stopifnot(file.exists(LOCATIO_FL))
geo <- read.csv(LOCATIO_FL, stringsAsFactors = F)
geo <- geo[!is.na( geo$Lat ) & !is.na( geo$Lng ),]
geo <- geo[order(geo$Dt), ]
## just choose last
loc <- tail(geo,1)


# get forecast for current location
res_fr        <- get_forecast(lat  = loc$Lat, lon = loc$Lng, units = "metric")

stopifnot(length(res_fr) > 3) ## should be 12
stopifnot( res_fr$cnt > 5   ) ## should be 40


## parse and format data
currFR        <- owmr_as_tibble(res_fr)
currFR        <- data.frame( currFR )

## use always UTC
currFR$dt        <- as.POSIXct(currFR$dt_txt, tz = "UTC" )
currFR$Data_time <- as.POSIXct(Sys.time(),    tz = "UTC")

## drop some data
wecare        <- grep( "id$|icon$|weather$|dt_txt", names(currFR),
                       ignore.case = T, value = T, invert = T )
currFR        <- currFR[wecare]
currFR$name   <- res_fr$city$name
currFR$source <- "OpenWeatherMAP"

colnames(currFR)[colnames(currFR) == "all"  ] <- "cloud_cover"
colnames(currFR)[colnames(currFR) == "speed"] <- "wind_speed"
colnames(currFR)[colnames(currFR) == "deg"  ] <- "wind_diredtion"
colnames(currFR)[colnames(currFR) == "pop"  ] <- "Precip_Proba"

saveRDS( currFR, CURRENT_FL )


###########################################################################################################
##
## code Internal parameter
## message Internal parameter
## city
##     city.id City ID
##     city.name City name
##     city.coord
##         city.coord.lat City geo location, latitude
##         city.coord.lon City geo location, longitude
##     city.country Country code (GB, JP etc.)
## cnt Number of lines returned by this API call
## list
##     list.dt Time of data forecasted, unix, UTC
##     list.main
##         list.main.temp       Temperature. Unit Default: Kelvin, Metric: Celsius, Imperial: Fahrenheit.
##         list.main.temp_min   Minimum temperature at the moment of calculation. This is deviation from 'temp' that is possible for large cities and megalopolises geographically expanded (use these parameter optionally). Unit Default: Kelvin, Metric: Celsius, Imperial: Fahrenheit.
##         list.main.temp_max   Maximum temperature at the moment of calculation. This is deviation from 'temp' that is possible for large cities and megalopolises geographically expanded (use these parameter optionally). Unit Default: Kelvin, Metric: Celsius, Imperial: Fahrenheit.
##         list.main.pressure   Atmospheric pressure on the sea level by default, hPa
##         list.main.sea_level  Atmospheric pressure on the sea level, hPa
##         list.main.grnd_level Atmospheric pressure on the ground level, hPa
##         list.main.humidity   Humidity, %
##         list.main.temp_kf    Internal parameter
##     list.weather (more info Weather condition codes)
##         list.weather.id      Weather condition id
##         list.weather.main    Group of weather parameters (Rain, Snow, Extreme etc.)
##         list.weather.description Weather condition within the group
##         list.weather.icon Weather icon id
##     list.clouds
##         list.clouds.all Cloudiness, %
##     list.wind
##         list.wind.speed  Wind speed. Unit Default: meter/sec, Metric: meter/sec, Imperial: miles/hour.
##         list.wind.deg    Wind direction, degrees (meteorological)
##     list.rain
##         list.rain.3h Rain volume for last 3 hours, mm
##     list.snow
##         list.snow.3h Snow volume for last 3 hours
##     list.dt_txt Data/time of calculation, UTC
##
###########################################################################################################



# get weather data from stations
# stations <- find_stations_by_geo_point(lat = 40.61986, lon = 22.96248, cnt = 10)
# stations %>% .[c("distance", "station.id", "station.name", "last.main.temp")]

##   distance station.id station.name last.main.temp
## 1   13.276       4926         EDVK         274.15
## 2   26.926       4954         ETHF         276.15
## 3   69.579       4910         EDLP         275.15
## 4   89.149      73733    Uwe Kruse         275.55
## 5   93.344 1460732694        hlw31         275.43
## 6   97.934 1442728908         AmiH         273.15
## 7   98.978       4951         ETHB         276.15

