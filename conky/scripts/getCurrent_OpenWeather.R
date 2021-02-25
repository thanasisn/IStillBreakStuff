#!/usr/bin/env Rscript

rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")

## OpenWeatherMAP api key 66dcbe4ad697153afa84d7312a097016
## gather weather from OpenWeatherMAP APIs

## other APIs
# https://darksky.net/dev
# https://www.apixu.com/

library(owmr)
library(plyr)
Sys.setenv(OWM_API_KEY = "66dcbe4ad697153afa84d7312a097016")

dir.create(  "/dev/shm/WHEATHER/", recursive = T, showWarnings = F)
CURRENT_FL = "/dev/shm/WHEATHER/Current_OpenWeather.Rds"
LOCATIO_FL = "/dev/shm/CONKY/last_location.dat"
# LAST_WEATH = "/dev/shm/WHEATHER/last.dat"
KEEP_MAX   = 1000


## Resolve location to ask weather for
stopifnot(file.exists(LOCATIO_FL))
geo <- read.csv(LOCATIO_FL, stringsAsFactors = F)
geo <- geo[!is.na( geo$Lat ) & !is.na( geo$Lng ),]
geo <- geo[order(geo$Dt), ]
## just choose last
loc <- tail(geo,1)


## get current weather
res_cr <- get_current(lat  = loc$Lat, lon = loc$Lng, units = "metric")
stopifnot(length(res_cr) > 10) ## should be 12


## parse and format data
currW             <- as.data.frame(res_cr)

currW$dt          <- strptime( currW$dt,          format = "%s" )
currW$sys.sunrise <- strptime( currW$sys.sunrise, format = "%s" )
currW$sys.sunset  <- strptime( currW$sys.sunset,  format = "%s" )
currW$source      <- "OpenWeatherMAP"

## drop some data
wecare <- grep("country|cod|id$|sys.message|sys.type|weather.icon" ,
               names(currW), ignore.case = T, value = T, invert = T)
currW  <- data.frame(currW[wecare])

## use common names
currW <- remove_prefix(currW, c("main","sys","coord","weather"))

colnames(currW)[colnames(currW) == "all"]   <- "cloud_cover"
colnames(currW)[colnames(currW) == "speed"] <- "wind_speed"
colnames(currW)[colnames(currW) == "deg"]   <- "wind_direction"


## load previous data
if (file.exists(CURRENT_FL)) {
    Current_data <- readRDS(CURRENT_FL)
} else {
    Current_data <- data.frame()
}


## store data for later use
Current_data <- rbind.fill(Current_data, currW)
Current_data <- Current_data[order(Current_data$dt),]
Current_data <- unique(Current_data)
Current_data <- tail(Current_data, KEEP_MAX)


## store last weather conditions
saveRDS( Current_data, CURRENT_FL )

## export most resent output from all sources
# last    <- tail(Current_data,100)
# last$dt <- as.POSIXlt( last$dt, tz = "Europe/Athens" )
# write.csv(x    = last,
#           file = LAST_WEATH, quote = F, row.names = F )

## to terminal
print(tail(Current_data,5))

########################################################################################
##
##  coord
##      coord.lon City geo location, longitude
##      coord.lat City geo location, latitude
##  weather (more info Weather condition codes)
##      weather.id           Weather condition id
##      weather.main         Group of weather parameters (Rain, Snow, Extreme etc.)
##      weather.description  Weather condition within the group
##      weather.icon Weather icon id
##  base Internal parameter
##  main
##      main.temp       Temperature. Unit Default: Kelvin, Metric: Celsius, Imperial: Fahrenheit.
##      main.pressure   Atmospheric pressure (on the sea level, if there is no sea_level or grnd_level data), hPa
##      main.humidity   Humidity, %
##      main.temp_min   Minimum temperature at the moment. This is deviation from current temp that is possible for large cities and megalopolises geographically expanded (use these parameter optionally). Unit Default: Kelvin, Metric: Celsius, Imperial: Fahrenheit.
##      main.temp_max   Maximum temperature at the moment. This is deviation from current temp that is possible for large cities and megalopolises geographically expanded (use these parameter optionally). Unit Default: Kelvin, Metric: Celsius, Imperial: Fahrenheit.
##      main.sea_level  Atmospheric pressure on the sea level, hPa
##      main.grnd_level Atmospheric pressure on the ground level, hPa
##  wind
##      wind.speed      Wind speed. Unit Default: meter/sec, Metric: meter/sec, Imperial: miles/hour.
##      wind.deg        Wind direction, degrees (meteorological)
##  clouds
##      clouds.all      Cloudiness, %
##  rain
##      rain.3h         Rain volume for the last 3 hours
##  snow
##      snow.3h         Snow volume for the last 3 hours
##  dt                  Time of data calculation, unix, UTC
##  sys
##      sys.type        Internal parameter
##      sys.id          Internal parameter
##      sys.message     Internal parameter
##      sys.country     Country code (GB, JP etc.)
##      sys.sunrise     Sunrise time, unix, UTC
##      sys.sunset      Sunset time, unix, UTC
##  id   City ID
##  name City name
##  cod Internal parameter
##
###########################################################################################3
