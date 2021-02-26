#!/usr/bin/env Rscript

#### Plot current location weather

rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
Script.Name = funr::sys.script()

library(scales)
library(myRtools)


try({
    library(extrafont)
    choose_font("Liberation Sans")
    choose_font("Liberation Mono")
})

## plot options
MIN_SCALE_RAIN = 3
MIN_RAIN       = 0.1            ## mm
TIME_BACK      = 30 * 3600      ## show previous forecasts
TIME_FRONT     = 6 * 24 * 3600  ## show future forecasts
CLOUD_PLOT     = .5
CEX            = .75


## plot weather and forecast

OPENWEA_FL = "/dev/shm/WHEATHER/Current_OpenWeather.Rds"
DARC_CUR   = "/dev/shm/WHEATHER/Current_DarkSky.Rds"

FORECAS_FL = "/dev/shm/WHEATHER/Forecast_OpenWeather.Rds"
DARKSKY_FL = "/dev/shm/WHEATHER/Forecast_hourly_DarkSky.Rds"
METEOBL_FL = "/dev/shm/WHEATHER/Forecast_meteoblue.Rds"
DAILY_FL   = "/dev/shm/WHEATHER/Forecast_daily_DarkSky.Rds"

OUTPUT_01  = "/dev/shm/WHEATHER/Loc_Weather.png"

LAPDAV_FL  = "/home/athan/LOGs/LAP_AUTH_davis.csv"


fore <- readRDS(FORECAS_FL)
dark <- readRDS(DARKSKY_FL)
blue <- readRDS(METEOBL_FL)
dail <- readRDS(DAILY_FL)

curr <- readRDS(OPENWEA_FL)
curD <- readRDS(DARC_CUR)

lapd <- read.csv(LAPDAV_FL)


dark$source <- "DarkSky"

## create column if not exist
fncols <- function(data, cname) {
    add <- cname[!cname %in% names(data)]

    if ( length(add) != 0 ) data[add] <- NA
    data
}



## create a fake record for later
fake_rec <- plyr::rbind.fill( data.frame(dt = as.POSIXct("2017-01-01 00:00:01"),
                                         rain.3h = MIN_SCALE_RAIN), fore )[1,]

## convert to local dates
fore$dt          <- as.POSIXlt(fore$dt,          tz = "Europe/Athens")
curr$dt          <- as.POSIXlt(curr$dt,          tz = "Europe/Athens")
dark$dt          <- as.POSIXlt(dark$time,        tz = "Europe/Athens")
fake_rec$dt      <- as.POSIXlt(fake_rec$dt,      tz = "Europe/Athens")
dail$time        <- as.POSIXlt(dail$time,        tz = "Europe/Athens")
curD$dt          <- as.POSIXlt(curD$time,        tz = "Europe/Athens")
dail$sunriseTime <- as.POSIXlt(dail$sunriseTime, tz = "Europe/Athens")
dail$sunsetTime  <- as.POSIXlt(dail$sunsetTime,  tz = "Europe/Athens")


## plot time range
dt_start <- as.POSIXlt(paste(format(Sys.time() - TIME_BACK,  format = "%F"), "00:00"), tz = "Europe/Athens" )
dt_end   <- as.POSIXlt(paste(format(Sys.time() + TIME_FRONT, format = "%F"), "00:00"), tz = "Europe/Athens" )

## subset date we want to see
fore <- fore[ fore$dt > dt_start, ]
curr <- curr[ curr$dt > dt_start, ]
dark <- dark[ dark$dt > dt_start, ]
curD <- curD[ curD$dt > dt_start, ]

fore <- fore[ fore$dt < dt_end, ]
curr <- curr[ curr$dt < dt_end, ]
dark <- dark[ dark$dt < dt_end, ]
curD <- curD[ curD$dt < dt_end, ]




## one data frame for each physical variable

#### Prepare Temperature ####
temp01 <- fore[ , grep( "dt$|temp|source|feels", names(fore), value = T)]
temp02 <- dark[ , grep( "dt$|emperature|source", names(dark), value = T)]

## unify names
names(temp01)[names(temp01) == "temp"    ] <- "Temp"
names(temp01)[names(temp01) == "temp_min"] <- "Temp_min"
names(temp01)[names(temp01) == "temp_max"] <- "Temp_max"

names(temp02)[names(temp02) == "temperature"         ] <- "Temp"
names(temp02)[names(temp02) == "apparentTemperature" ] <- "Temp_feel"

Temp <- merge( temp01, temp02, all = T )
Temp <- Temp[order(Temp$dt),]
rm(temp01, temp02)


#### Prepare Rain ####

rain01 <- fore[ , grep( "dt$|rain|source",   names(fore), value = T)]
rain02 <- dark[ , grep( "dt$|precip|source", names(dark), value = T)]

names(rain01)[names(rain01) == "rain_3h" ] <- "Rain.3h"
names(rain02)[names(rain02) == "precipIntensity"   ] <- "Rain.1h"
names(rain02)[names(rain02) == "precipProbability" ] <- "Prob.1h"
names(rain02)[names(rain02) == "precipType"        ] <- "Type.1h"

Rain <- merge( rain01, rain02, all = T )
# rm(rain01, rain02)

#### Prepare Wind ####
wind01 <- fore[ , grep( "dt$|wind|source", names(fore), value = T)]
wind02 <- dark[ , grep( "dt$|wind|source", names(dark), value = T)]

Wind <- merge( wind01, wind02, all = T )
# rm(wind01, wind02)

## conver to km/h
# Wind$wind_speed <- Wind$wind_speed * (10/36)
# Wind$windSpeed  <- Wind$windSpeed  * (10/36)
# Wind$windGust   <- Wind$windGust * (10/36)


#### Prepare Cloud ####
cloud1 <- fore[ , grep( "dt$|cloud|source", names(fore), value = T)]
cloud1$clouds_all <- cloud1$clouds_all / 100
cloud2 <- dark[ , grep( "dt$|cloud|source", names(dark), value = T)]

Cloud <- merge( cloud1, cloud2, all = T )
rm(cloud1, cloud2)


## test Temperature
# plot(Temp$dt, Temp$Temp )
# lines(Temp$dt[Temp$source=="DarkSky"],        Temp$Temp[Temp$source=="DarkSky"],        col=2 )
# lines(Temp$dt[Temp$source=="OpenWeatherMAP"], Temp$Temp[Temp$source=="OpenWeatherMAP"], col=3)
# points(Temp$dt, Temp$Temp_feel, col=4)

## test Rain
# plot(   Rain$dt, Rain$Rain.1h )
# plot( Rain$dt, Rain$Rain.3h)


## test wind
# plot( dark$dt, dark$windSpeed )
# points( dark$dt, dark$windGust )
# points( fore$dt, fore$wind_speed)

Rain <- fncols(Rain, "Rain.3h")

## count plots
has_temp <- sum(!is.na(Temp$Temp)) > 1
has_rain <- any(c(Rain$Rain.3h, Rain$Rain.1h) > MIN_RAIN, na.rm = TRUE)
has_wind <- any(!is.na(c(Wind$wind_speed, Wind$windSpeed)), na.rm = TRUE)

# has_rain = F


#### Prepare daily value from meteo blue ####

blue$From  <- as.POSIXct(strptime( paste(blue$day, "00:00"), "%F %R" ), tz = "Europe/Athens")
blue$Until <- as.POSIXct(paste(blue$day, "24:00"), tz = "Europe/Athens")

blue <- data.frame(blue)

blue <- blue[ blue$From <= dt_end ]


#### Prepare data from LAP DAVIS  ####
lapd$time <- as.POSIXct(lapd$dateTime, origin = "1970-01-01")
lapd$dt   <- as.POSIXlt(lapd$time,     tz = "Europe/Athens")

## remove same data cols
lapd <- lapd[,vapply(lapd, function(x) length(unique(x)) > 1, logical(1L))]

lapd$outTemp   <- fahrenheit_to_celsius(lapd$outTemp)
lapd$inTemp    <- fahrenheit_to_celsius(lapd$inTemp)
lapd$appTemp   <- fahrenheit_to_celsius(lapd$appTemp)
lapd$dewpoint  <- fahrenheit_to_celsius(lapd$dewpoint)
lapd$heatindex <- fahrenheit_to_celsius(lapd$heatindex)
lapd$humidex   <- fahrenheit_to_celsius(lapd$humidex)

testa <- lapd[ lapd$dateTime > Sys.Date() - 10 * 3600 * 24, ]

plot( testa$dt, testa$appTemp,   "l")
lines(testa$dt, testa$outTemp,   col = 2)
lines(testa$dt, testa$heatindex, col = 3)
lines(testa$dt, testa$humidex, col = 3)


#### Start plotting ####
 # x11()
Sys.setlocale(locale = "el_GR.utf8")
png( OUTPUT_01, bg = "transparent", family = "Liberation Sans",
     width = 540, height = 255, units = "px", pointsize = 15, type = "cairo")
{
    how_graphs = sum(has_temp, has_rain, has_wind)
    if ( how_graphs == 3 ) {
        layout(matrix(c(1,1,1,2,2,3), 6, 1, byrow = TRUE))
        # layout.show(2)
    }
    if ( how_graphs == 2 ) {
        layout(matrix(c(1,1,2), 3, 1, byrow = TRUE))
        # layout.show(2)
    }

    par("cex"=CEX)

    ## set ranges to plot
    next_day <- Sys.time() + 24*3600
    drange <- range( dt_start,        Temp$dt,                         na.rm = T )
    trange <- range( Temp$Temp,       Temp$Temp_feel, Temp$feels_like, na.rm = T )
    rrange <- range( Rain$Rain.1h,    Rain$Rain.3h, 0, MIN_SCALE_RAIN, na.rm = T )
    wrange <- range( Wind$wind_speed, Wind$windSpeed                 , na.rm = T )
    name   <- as.character(tail(curr$name[!is.na(curr$name)],1))

    ## set colors
    par(bg = "transparent")
    # par(bg = "black")

    col_other <- alpha("grey",    0.9  )
    col_dark  <- alpha("green",   0.8  )
    col_curen <- alpha("magenta", 0.8  )
    col_open  <- alpha("blue",    0.8  )
    col_grid  <- alpha("grey",    0.2  )
    col_rain1 <- alpha("#002EFF", 0.6  )
    col_rain2 <- alpha("#0057FF", 0.6  )
    col_sun   <- alpha("#E0DC35", 0.08 )
    col_cloud <- alpha("grey",    0.10 )
    col_font  <- "grey"


    ## adjust clouds to rain
    upcloud <- rrange[2]
    dncloud <- rrange[2] - (rrange[2] - rrange[1]) * CLOUD_PLOT
    ## height of cloud to plot in rain units
    Cloud$cloud_cover <- (upcloud - dncloud) * Cloud$clouds_all
    Cloud$cloudCover  <- (upcloud - dncloud) * Cloud$cloudCover


    ####  Temperature plot  ####################################################
    par(mar = c( 0.7, 1.1, 1, 0.9 ))
    plot(1, type = "n", axes = F,
         xlab = "", ylab = "",
         # yaxs = "i",
         xlim = as.POSIXct(drange),
         ylim = trange )

    ## add decorations on graph
    abline( v = seq( drange[1], drange[2], by = "day"),
            lwd = 2 , lty = 2, col = col_grid )
    abline( v = seq( drange[1], drange[2], by = "day") + 12*3600,
            lty = 3, col = col_grid )
    abline( h = pretty(drange, min.n = 1), lty = 2, col = col_grid )
    abline( h = 0, lwd = 2, lty = 2, col = col_grid )
    abline( v = Sys.time(), lwd = 2, lty = 2, col = col_font )

    ## plot sun background
    rect(dail$sunriseTime, trange[1] - 10,
         dail$sunsetTime,  trange[2] + 10,
         col = col_sun, border = NA, lwd = 1 )

    ## plot lap davis
    lines(lapd$dt, lapd$appTemp,   col = "red", lty = 1 )
    lines(lapd$dt, lapd$outTemp,   col = "red", lty = 2 )
    lines(lapd$dt, lapd$heatindex, col = "red", lty = 3 )


    ## plot meteoblue daily extremes
    # segments(x0 = blue$From, x1 = blue$Until,
    #          y0 = blue$temperature_mean,    col = "blue" , lwd = 2 )
    segments(x0 = blue$From, x1 = blue$Until,
             y0 = blue$temperature_max,     col = "green", lwd = 2 )
    segments(x0 = blue$From, x1 = blue$Until,
             y0 = blue$temperature_min,     col = "cyan" , lwd = 2 )
    segments(x0 = blue$From, x1 = blue$Until,
             y0 = blue$felttemperature_min, col = "cyan" , lwd = 2 , lty = 3 )


    ## plot temperature lines
    lines(Temp$dt[Temp$source == "OpenWeatherMAP"], Temp$Temp[      Temp$source == "OpenWeatherMAP"], lwd = 3, col = col_open)
    lines(Temp$dt[Temp$source == "OpenWeatherMAP"], Temp$feels_like[Temp$source == "OpenWeatherMAP"], lwd = 3, col = col_open, lty = 3)
    lines(Temp$dt[Temp$source == "DarkSky"],        Temp$Temp[      Temp$source == "DarkSky"],        lwd = 3, col = col_dark)
    lines(Temp$dt[Temp$source == "DarkSky"],        Temp$Temp_feel[ Temp$source == "DarkSky"],        lwd = 3, col = col_dark, lty = 3)
    lines(curr$dt, curr$temp, lwd = 3, lty = 1, col = col_curen)


    ## temperature axis
    axis(side = 2, line = -1,
         at = curr$temp[length(curr$temp)],
         labels = F, tcl = .5,
         col = col_curen, lwd=2, col.axis = col_curen  )

    text(drange[1], curr$temp[length(curr$temp)],
         round(curr$temp[length(curr$temp)], digits = 1), pos = 4, col = col_curen  )

    ## x axis below
    axis.POSIXct( side = 1, at = seq( drange[1], drange[2], by = "day"), format = "%a", labels = F ,
                  lwd.ticks = 3, col = col_other, col.axis = col_other, font = 2 )
    axis.POSIXct( side = 1, at = seq( drange[1], drange[2], by = "3 hour"), labels = F ,
                  lwd.ticks = 3, tcl = -0.2 , col = col_other, col.axis = col_other)
    ##  y axis
    axis( side = 2, line = -1,
          at = c(pretty(trange, min.n = 1, n = 5),
                 round(min(trange),0),
                 round(max(trange),0)),
          las = 2,
          col = col_other, lwd = 2, col.axis = col_other, font = 2 )
    axis( side = 2, line = -1,
          at = seq(round(min(trange),0), round(max(trange),0), by = 1 ),
          labels = F,
          tcl = -0.2,
          col = col_other, lwd = 2, col.axis = col_other )

    axis( side = 4, line = -1.5,
          at = c(pretty(trange, min.n = 1, n = 5),
                 round(min(trange),0),
                 round(max(trange),0)),
          las = 2,
          col = col_other, lwd = 2, col.axis = col_other, font = 2 )
    axis( side = 4, line = -1.5,
          at = seq(round(min(trange),0), round(max(trange),0), by = 1 ),
          labels = F,
          tcl = -0.2,
          col = col_other, lwd = 2, col.axis = col_other )

    title(main = paste(name, format( Sys.time(),"%H:%M",tz = "Europe/Athens" )), font = 2, cex.main = .9, col.main = col_font)


    ## next 24h
    today <- Temp[ Temp$dt < next_day & Temp$dt > Sys.time(), ]
    text(today$dt[which.max(today$Temp)], max(today$Temp, na.rm = T), labels = round(max(today$Temp, na.rm = T),1), col = col_other, pos = 4, font = 2 )
    text(today$dt[which.min(today$Temp)], min(today$Temp, na.rm = T), labels = round(min(today$Temp, na.rm = T),1), col = col_other, pos = 1, font = 2 )


    ####  Precip plot  #########################################################
    if (has_rain) {

        plot(0, type = "n", axes = F,
             xlab = "", ylab = "",
             yaxs = "i",
             xlim = as.POSIXct(drange),
             ylim = rrange )

        ## plot sun
        rect(dail$sunriseTime, trange[1] - 10, dail$sunsetTime, trange[2] + 10,
             col = col_sun, border = NA, lwd = 1 )

        ## add decoration
        abline( v = seq( drange[1], drange[2], by = "day"), lwd = 2 , lty = 2, col = col_grid )
        abline( v = seq( drange[1], drange[2], by = "day") + 12*3600, lty = 3, col = col_grid )
        abline( h = pretty(drange, min.n = 1), lty = 2, col = col_grid )
        abline( v = Sys.time(), lwd = 2, lty = 2, col = col_font )


        rrange
        paste0(blue$precipitation_probability,"% ",blue$precipitation_hours,"h")

        text(x = blue$From,
             y = rrange[2],
             labels = paste0(blue$precipitation_probability,"% ",blue$precipitation_hours,"h"),
             adj = c(0,1.1),
             cex = 1.3, font = 2, col = "magenta")


        Rain$Rain.1h[Rain$Rain.1h == 0] <- NA
        Rain$Rain.3h[Rain$Rain.3h == 0] <- NA

        rect(Cloud$dt[Cloud$source == "DarkSky"],            upcloud,
             Cloud$dt[Cloud$source == "DarkSky"] - 1 * 3600, upcloud - Cloud$cloudCover[Cloud$source == "DarkSky"],
             col = col_cloud, border = NA)

        rect(Cloud$dt[Cloud$source == "OpenWeatherMAP"],            upcloud,
             Cloud$dt[Cloud$source == "OpenWeatherMAP"] - 3 * 3600, upcloud - Cloud$cloud_cover[Cloud$source == "OpenWeatherMAP"],
             col = col_cloud, border = NA)


        ## plot rain
        rect(Rain$dt, rrange[1], Rain$dt - 1*3600, Rain$Rain.1h,
             col = col_rain2, border = col_rain2, lwd = 1 )

        rect(Rain$dt, rrange[1], Rain$dt - 3*3600, Rain$Rain.3h,
             col = NA, border = col_rain1, lwd = 3 )

        ## add axis x above
        axis.POSIXct( side = 3, at = seq( drange[1], drange[2], by = "day")+ 12 * 3600,
                      labels = format(seq( drange[1], drange[2], by = "day"), "%a"),
                      lwd = 0, col = col_other, col.axis = col_other, font = 2, line = -.9 )

        ## x axis below
        axis.POSIXct( side = 1, at = seq( drange[1], drange[2], by = "day"), format = "%a",  labels = F ,
                      lwd.ticks = 3, col = col_other, col.axis = col_other, font = 2 )
        axis.POSIXct( side = 1, at = seq( drange[1], drange[2], by = "3 hour"), labels = F ,
                      lwd.ticks = 3, tcl = -0.2 , col = col_other, col.axis = col_other)

        ## y axis
        axis( side = 2, line = -1,
              at = c(pretty(rrange, min.n = 1, n = 4),
                     round(min(rrange),0),
                     round(max(rrange),0)),
              las = 2,
              col = col_other, lwd = 2, col.axis = col_other, font = 2 )
        axis( side = 2, line = -1,
              at = seq(round(min(rrange),0), round(max(rrange),0), by = 1 ),
              labels = F,
              tcl = -0.2,
              col = col_other, lwd = 2, col.axis = col_other )


        axis( side = 4, line = -1.5,
              at = c(pretty(rrange, min.n = 1, n = 4),
                     round(min(rrange),0),
                     round(max(rrange),0)),
              las = 2,
              col = col_other, lwd = 2, col.axis = col_other, font = 2 )
        axis( side = 4, line = -1.5,
              at = seq(round(min(rrange),0), round(max(rrange),0), by = 1 ),
              labels = F,
              tcl = -0.2,
              col = col_other, lwd = 2, col.axis = col_other )

        ## next 24h
        today <- Rain[ Rain$dt < next_day & Rain$dt > Sys.time(), ]
        text(today$dt[which.max(today$Rain.3h)], max(today$Rain.3h, na.rm = T), labels = round(max(today$Rain.3h, na.rm = T),1), col = col_other, pos = 3, font = 2 )
        text(today$dt[which.max(today$Rain.1h)], max(today$Rain.1h, na.rm = T), labels = round(max(today$Rain.1h, na.rm = T),1), col = col_other, pos = 3, font = 2 )

    }


    ####  Wind plot  ###########################################################################################
    if (has_wind) {

        if (how_graphs == 3) {
            par(mar = c( 0.9, 1.1, 0, 0.9 ))
        }

        plot(0, type = "n", axes = F,
             xlab = "", ylab = "",
             yaxs = "i",
             xlim = as.POSIXct(drange),
             ylim = wrange )

        ## add decoration
        abline( v = seq( drange[1], drange[2], by = "day"), lwd = 2 , lty = 2, col = col_grid )
        abline( v = seq( drange[1], drange[2], by = "day") + 12*3600, lty = 3, col = col_grid )
        abline( h = pretty(drange, min.n = 1), lty = 2, col = col_grid )
        abline( v = Sys.time(), lwd = 2, lty = 2, col = col_font )


        lines( dark$dt, dark$windSpeed,  lwd = 2, col = col_dark)
        lines( fore$dt, fore$wind_speed, lwd = 2, col = col_open)

        ## x above
        if (how_graphs==2){
            axis.POSIXct( side = 3, at = seq( drange[1], drange[2], by = "day")+ 12 * 3600,
                          labels = format(seq( drange[1], drange[2], by = "day"), "%a"),
                          lwd = 0, col = col_other, col.axis = col_other, font = 2, line = -.9 )
        }
        ## x below
        axis.POSIXct( side = 1, at = seq( drange[1], drange[2], by = "day"), format = "%a",  labels = F ,
                      lwd.ticks = 3, col = col_other, col.axis = col_other, font = 2 , line = 0.15 )
        axis.POSIXct( side = 1, at = seq( drange[1], drange[2], by = "3 hour"), labels = F ,
                      lwd.ticks = 3, tcl = -0.2 , col = col_other, col.axis = col_other, line = 0.15)

        ## y axis
        axis( side = 2, line = -1,
              at = c(pretty(wrange, min.n = 2, n = 3)),
              las = 2,
              col = col_other, lwd = 2, col.axis = col_other, font = 2 )
        axis( side = 2, line = -1,
              at = seq(round(min(wrange),0), round(max(wrange),0), by = 1 ),
              labels = F,
              tcl = -0.2,
              col = col_other, lwd = 2, col.axis = col_other )

        axis( side = 4, line = -1.5,
              at = c(pretty(wrange, min.n = 2, n = 2 )),
              las = 2,
              col = col_other, lwd = 2, col.axis = col_other, font = 2 )
        axis( side = 4, line = -1.5,
              at = seq(round(min(wrange),0), round(max(wrange),0), by = 1 ),
              labels = F,
              tcl = -0.2,
              col = col_other, lwd = 2, col.axis = col_other )
    }
}
# dev.copy(png, OUTPUT_01, bg = "transparent",
#          width = 530, height = 240, units = "px", pointsize = 15, type = "cairo")
dev.off()
Sys.setlocale(locale = "en_US.utf8")




# # xaxt = "n"
# # png("/dev/shm/WHEATHER/temp.png", bg = "transparent",
# #          width = 530, height = 240, units = "px", pointsize = 15)
# {
#     Sys.setlocale(locale = "el_GR.utf8")
#     par(mar = c(2,1.1,1,2.1))
#     par(bg = "transparent")
#
#     range02 <- function(x){ (x - min(x,na.rm = T))/(max(x,na.rm = T) - min(x,na.rm = T)) * (xx[2] - xx[1]) + xx[1] }
#
#     ## add fake record for scaling
#     fore <- rbind(fore,fake_rec)
#
#     fore$rain.3h[is.na(fore$rain.3h)] <- 0
#
#     rain   <- range02(fore$rain.3h)
#     rlabes <- pretty(fore$rain.3h, n = 5, min.n = 0)
#     rat    <- range02(rlabes)
#     ## for clouds
#     fore$cloud_cover[fore$cloud_cover == 0] <- NA
#     cloud <- range02(fore$cloud_cover)/3
#
#     magic = temp_range[1] - min(rain, na.rm = T)
#
#     if ( length(rat) > 0 &&  !is.nan(rat)) {
#         axis( side = 4 , line = -1,
#               at = rat - magic , labels = rlabes, col = col_rain,
#               lwd = 3, col.axis = col_rain, font = 2)
#
#         mtext("mm", side = 4, line = 1, col = col_rain, font = 2)
#     }
#
# }
# dev.copy(png, "/dev/shm/WHEATHER/temp.png", bg = "transparent",
#          width = 530, height = 240, units = "px", pointsize = 15)
# dev.off()

