#!/usr/bin/env Rscript
# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */

#### Get weather data from open-meteo.com

####  Set environment  ####
rm(list = (ls()[ls() != ""]))
# .libPaths(c(.libPaths(), "~/.R/x86_64-pc-linux-gnu-library/4.2.3/"))
Sys.setenv(TZ = "UTC")
source("~/CODE/conky/scripts/location.R")
tic <- Sys.time()
Script.Name <- "~/CODE/conky/scripts/get_open_meteo_api.R"

library(data.table)
library(curl)
library(rjson)

LOCATIO_FL <- "/dev/shm/CONKY/last_location.dat"
exportfile <- "/dev/shm/WHEATHER/open_meteo_dump.Rds"
oldness    <- 000 ## we want to be less than an hour

dir.create("/dev/shm/WHEATHER", showWarnings = F)

## Resolve location to use
if (!file.exists(LOCATIO_FL) ) {
    stop("Missing file :", LOCATIO_FL)
}
geo <- read.csv(LOCATIO_FL)
geo <- geo[!is.na(geo$Lat) & !is.na(geo$Lng), ]
geo <- geo[order(geo$Dt), ]
loc <- tail(geo, 1)


## Get data from https://open-meteo.com/

urlL <- paste0("https://api.open-meteo.com/v1/forecast?latitude=", loc$Lat,
                                                     "&longitude=",loc$Lng )

urlH <- paste0("&hourly=temperature_2m,relativehumidity_2m,apparent_temperature,precipitation,rain,showers,snowfall,freezinglevel_height,cloudcover,cloudcover_low,cloudcover_mid,cloudcover_high,windspeed_10m,windgusts_10m,shortwave_radiation,direct_radiation,diffuse_radiation,direct_normal_irradiance,terrestrial_radiation,shortwave_radiation_instant,direct_radiation_instant,diffuse_radiation_instant,direct_normal_irradiance_instant,terrestrial_radiation_instant")

urlM <- paste0("&models=best_match,ecmwf_ifs04,metno_nordic,gfs_seamless,jma_seamless,icon_seamless,gem_seamless,meteofrance_arpege_europe")

urlD <- paste0("&daily=weathercode,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,precipitation_sum,rain_sum,showers_sum,snowfall_sum,precipitation_hours")

urlT <- paste0("&current_weather=true&timezone=auto&past_days=2")

# "https://api.open-meteo.com/v1/forecast?latitude=40.64&longitude=22.93&hourly=temperature_2m,relativehumidity_2m,apparent_temperature,precipitation,rain,showers,snowfall,freezinglevel_height,cloudcover,cloudcover_low,cloudcover_mid,cloudcover_high,windspeed_10m,windgusts_10m,shortwave_radiation,direct_radiation,diffuse_radiation,direct_normal_irradiance,terrestrial_radiation,shortwave_radiation_instant,direct_radiation_instant,diffuse_radiation_instant,direct_normal_irradiance_instant,terrestrial_radiation_instant&models=best_match,ecmwf_ifs04,metno_nordic,gfs_seamless,jma_seamless,icon_seamless,gem_seamless,meteofrance_arpege_europe&daily=weathercode,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,precipitation_sum,rain_sum,showers_sum,snowfall_sum,precipitation_hours&current_weather=true&timezone=Europe%2FAthens&past_days=2"

## get new data
if (!file.exists(exportfile) || file.mtime(exportfile) < Sys.time() - oldness) {
    urlget <- paste0(urlL, urlH, urlM, urlD, urlT)
    cat("GET DATA FROM:", urlget, sep = "\n")
    dump   <- rjson::fromJSON( file = curl(urlget), unexpected.escape = "skip")
    # saveRDS(dump, exportfile)

    ## parse data
    WAPI_current         <- dump$current_weather
    dump$current_weather <- NULL

    WAPI_hourly          <- list2DF(dump$hourly)
    WAPI_hourly_units    <- dump$hourly_units
    dump$hourly          <- NULL
    dump$hourly_units    <- NULL

    WAPI_daily           <- list2DF(dump$daily)
    WAPI_daily_units     <- dump$daily_units
    dump$daily           <- NULL
    dump$daily_units     <- NULL

    WAPI_metadata        <- dump

    WAPI_metadata$Data_time <- as.POSIXct(Sys.time(), tz = "UTC")
    WAPI_metadata$City      <- loc$City

    save(list = ls(pattern = "WAPI"), file = exportfile)
} else {
    cat("\nDon't need new data from https://open-meteo.com/\n\n")
    cat(exportfile,
        "oldness: ",
        difftime(Sys.time(), file.mtime(exportfile), units = "mins"),
        "mins\n")
}

tac <- Sys.time()
cat(sprintf("\n%s %s@%s %s %f mins\n\n",Sys.time(),Sys.info()["login"],Sys.info()["nodename"],Script.Name,difftime(tac,tic,units="mins")))
