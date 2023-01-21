#!/usr/bin/env Rscript

#### Plot current location weather

rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
Script.Name = funr::sys.script()

library(scales)
library(myRtools)
library(data.table)

# try({
#     library(extrafont)
#     choose_font("Liberation Sans")
#     choose_font("Liberation Mono")
# })

## plot options
MIN_SCALE_RAIN = 3
MIN_RAIN       = 0.1            ## mm
TIME_BACK      = 35 * 3600      ## show previous forecasts
TIME_FRONT     = 6 * 24 * 3600  ## show future forecasts
CLOUD_PLOT     = .5
CEX            = .75


## plot weather and forecast

OPENWEA_FL <- "/dev/shm/WHEATHER/Current_OpenWeather.Rds"
DARC_CUR   <- "/dev/shm/WHEATHER/Current_DarkSky.Rds"
FORECAS_FL <- "/dev/shm/WHEATHER/Forecast_OpenWeather.Rds"
DARKSKY_FL <- "/dev/shm/WHEATHER/Forecast_hourly_DarkSky.Rds"
METEOBL_FL <- "/dev/shm/WHEATHER/Forecast_meteoblue.Rds"
DAILY_FL   <- "/dev/shm/WHEATHER/Forecast_daily_DarkSky.Rds"
OUTPUT_01  <- "/dev/shm/WHEATHER/Loc_Weather3.png"
LAPDAV_FL  <- "/home/athan/LOGs/LAP_AUTH_davis.csv"


open_meteo_fl <- "/dev/shm/WHEATHER/open_meteo_dump.Rds"
outdir        <- "~/LOGs/Weather"

dir.create(outdir, showWarnings = F)


col_other <- alpha("grey",    0.9  )
col_dark  <- alpha("green",   0.6  )
col_curen <- alpha("magenta", 0.8  )
col_open  <- alpha("blue",    0.6  )
col_grid  <- alpha("grey",    0.2  )
col_rain1 <- alpha("#002EFF", 0.6  )
col_rain2 <- alpha("#CC29DD", 0.8  )
col_sun   <- alpha("#E0DC35", 0.08 )
col_cloud <- alpha("grey",    0.10 )
col_font  <- "grey"

## plot time range
dt_start <- as.POSIXlt(paste(format(Sys.time() - TIME_BACK,  format = "%F"), "00:00"), tz = "Europe/Athens" )
dt_end   <- as.POSIXlt(paste(format(Sys.time() + TIME_FRONT, format = "%F"), "00:00"), tz = "Europe/Athens" )


## load data
if (file.exists(open_meteo_fl)) {
    load(open_meteo_fl)
} else {
    cat("Missing file ", open_meteo_fl)
}

fore <- readRDS(FORECAS_FL)
curr <- readRDS(OPENWEA_FL)
lapd <- read.csv(LAPDAV_FL)

fore[is.na(fore)] <- 0



WAPI_hourly$dt <- as.POSIXct(strptime(WAPI_hourly$time, format = "%FT%R", tz = WAPI_metadata$timezone))
WAPI_hourly$source <- "OpenMeteo"


## fix data
wecare <- grep("time|source|dt", names(WAPI_hourly), invert = T, value = T )
for (av in wecare) {

    if (is.null(unlist( WAPI_hourly[[av]] ))) {
        WAPI_hourly[[av]] <- NULL
        next
    }

    if ( is.list( WAPI_hourly[[av]] ) ) {
        res <- unlist( WAPI_hourly[[av]] )
        res <- c(res, rep(NA, nrow(WAPI_hourly) - length(res)))
        WAPI_hourly[[av]] <- res
    }

    if ( all( unique(WAPI_hourly[[av]]) %in% c(NA,0))) {
        cat("remove non info",av,"\n")
        WAPI_hourly[[av]] <- NULL
        next()
    }
}



## remove stale files anyway
outfiles <- list.files(outdir, "*.pdf", full.names = T)
file.remove(outfiles[file.mtime(outfiles) < Sys.time() -  5*24*3600])



#### Prepare daily value from meteo blue ####
WAPI_daily$sunrise <- as.POSIXct(strptime(WAPI_daily$sunrise, "%FT%R" , tz = WAPI_metadata$timezone ))
WAPI_daily$sunset  <- as.POSIXct(strptime(WAPI_daily$sunset,  "%FT%R" , tz = WAPI_metadata$timezone ))

WAPI_daily$From  <- as.POSIXct(strptime( paste(WAPI_daily$time, "00:00"), "%F %R" ), tz = WAPI_metadata$timezone)
WAPI_daily$Until <- as.POSIXct(strptime( paste(WAPI_daily$time, "23:59"), "%F %R" ), tz = WAPI_metadata$timezone)


####  Plot all open meteo variables ####

pdffile <- paste0(outdir,"/Open_Meteo_Variables_",tail(curr$name,1),"_",WAPI_metadata$City, ".pdf")

if (!interactive() && (!file.exists(pdffile) || WAPI_metadata$Data_time > file.mtime(pdffile) + 3600)) {
    cat("Create new ", pdffile,"\n")
    pdf(pdffile, width = 9, height = 5)
}

WAPI_hourly <- WAPI_hourly[ WAPI_hourly$dt > dt_start, ]

#### all models together  ####
models   <- sub("temperature_2m_", "", grep("temperature_2m_", names(WAPI_hourly), value = T))
varab    <- grep(paste0(models,collapse = "|") ,names(WAPI_hourly), value = T)
uvarab   <- unique(sub("_$", "", sub(pattern = paste0(models,collapse = "|"), "", varab)))
str_date <- strftime( WAPI_metadata$Data_time, tz = "Europe/Athens", format = "%F %R" )


#### as lines ####
for (av in uvarab) {

    wecare <- names(WAPI_hourly)[names(WAPI_hourly) %in% paste0(av, "_", models)]
    wecare <- sort(wecare,decreasing = T)
    ylim   <- range(unlist( WAPI_hourly[wecare]), na.rm = T )
    xlim   <- range(WAPI_hourly$dt)

    # cat(wecare,sep = "\n", "\n\n")
    par(mar = c(2,3,2,0.5))

    plot(1, type = "n", axes = F,
         xlab = "", ylab = "",
         # yaxs = "i",
         xlim = xlim,
         ylim = ylim )

    ## plot sun
    rect(WAPI_daily$sunrise, ylim[1] - 100,
         WAPI_daily$sunset,  ylim[2] + 100,
         col = alpha("#E0DC35", 0.2 ), border = NA, lwd = 1 )

    box()

    ## x axis below
    axis.POSIXct( side = 1, at = seq( xlim[1], xlim[2], by = "day"), format = "%m-%d",
                  lwd.ticks = 1,  font = 2 )
    axis.POSIXct( side = 1, at = seq( xlim[1], xlim[2], by = "3 hour"), labels = F ,
                  lwd.ticks = 1, tcl = -0.2 )

    ## y axis
    axis(side = 2, at = pretty(unlist( WAPI_hourly[wecare])))

    abline(h = pretty(unlist( WAPI_hourly[wecare])), lty = 3, col = "lightgrey")
    abline(v = seq( xlim[1], xlim[2], by = "day"),   lty = 3, col = "lightgrey")
    ## now line
    abline(v = Sys.time(), lty = 2 , col = "green" )
    ## data parsed line
    # abline(v = WAPI_metadata$Data_time, lty = 2 , col = "grey" )
    ## model update every 1, 3, 6 hours
    abline(v = WAPI_metadata$Data_time - as.numeric(WAPI_metadata$Data_time) %%      3600,  lty = 2 , col = "grey" )
    abline(v = WAPI_metadata$Data_time - as.numeric(WAPI_metadata$Data_time) %% (3 * 3600), lty = 2 , col = "grey")
    abline(v = WAPI_metadata$Data_time - as.numeric(WAPI_metadata$Data_time) %% (6 * 3600), lty = 2 , col = "grey")

    cc <- 0
    mm <- c()
    for (mv in wecare) {
        cc <- cc + 1
        if (is.null(unlist( WAPI_hourly[[mv]] ))) { next }
        if (mv == tail(wecare,1)) { asi = 3 } else { asi = 2 }
        mm <- c(mm, sub("^_", "", sub(av, "", mv)))
        lines(WAPI_hourly$dt, WAPI_hourly[[mv]], col = cc, lwd = asi )
    }

    legend("top",
           legend = mm,
           lty = 1,
           col = 1:length(mm),
           ncol = 3,
           bty = "n")

    title(paste(WAPI_metadata$City, "  ", str_date, "  ", av), cex.main = 1.2 )
}



#### as points ####
for (av in uvarab) {

    wecare <- names(WAPI_hourly)[names(WAPI_hourly) %in% paste0(av, "_", models)]
    wecare <- sort(wecare,decreasing = T)
    ylim   <- range(unlist( WAPI_hourly[wecare]), na.rm = T )
    xlim   <- range(WAPI_hourly$dt)

    # cat(wecare,sep = "\n", "\n\n")
    par(mar = c(2,3,2,1))

    plot(1, type = "n", axes = F,
         xlab = "", ylab = "",
         # yaxs = "i",
         xlim = xlim,
         ylim = ylim )

    ## plot sun
    rect(WAPI_daily$sunrise, ylim[1] - 100,
         WAPI_daily$sunset,  ylim[2] + 100,
         col = alpha("#E0DC35", 0.2 ), border = NA, lwd = 1 )

    box()

    ## x axis below
    axis.POSIXct( side = 1, at = seq( xlim[1], xlim[2], by = "day"), format = "%m-%d",
                  lwd.ticks = 1,  font = 2 )
    axis.POSIXct( side = 1, at = seq( xlim[1], xlim[2], by = "3 hour"), labels = F ,
                  lwd.ticks = 1, tcl = -0.2 )

    ## y axis
    axis(side = 2, at = pretty(unlist( WAPI_hourly[wecare])))

    abline(h = pretty(unlist( WAPI_hourly[wecare])), lty = 3, col = "lightgrey")
    abline(v = seq( xlim[1], xlim[2], by = "day"),   lty = 3, col = "lightgrey")
    ## now line
    abline(v = Sys.time(), lty = 2 , col = "green" )
    ## data parsed line
    # abline(v = WAPI_metadata$Data_time, lty = 2 , col = "grey" )
    ## model update every 1, 3, 6 hours
    abline(v = WAPI_metadata$Data_time - as.numeric(WAPI_metadata$Data_time) %%      3600,  lty = 2 , col = "grey" )
    abline(v = WAPI_metadata$Data_time - as.numeric(WAPI_metadata$Data_time) %% (3 * 3600), lty = 2 , col = "grey")
    abline(v = WAPI_metadata$Data_time - as.numeric(WAPI_metadata$Data_time) %% (6 * 3600), lty = 2 , col = "grey")

    cc <- 0
    pp <- 0
    mm <- c()
    for (mv in wecare) {
        cc <- cc + 1
        pp <- pp + 1
        if (is.null(unlist( WAPI_hourly[[mv]] ))) { next }
        if (mv == tail(wecare,1)) { asi = 2 } else { asi = 1 }
        mm <- c(mm, sub("^_", "", sub(av, "", mv)))
        points(WAPI_hourly$dt, WAPI_hourly[[mv]], col = cc , pch = pp, cex = asi)
    }

    legend("top",
           legend = mm,
           col = 1:length(mm),
           pch = 1:length(mm),
           ncol = 3,
           bty = "n")

    title(paste(WAPI_metadata$City, "  ", str_date, "  ", av), cex.main = 1.2,  )

}



#### plot each variable ####
wecare  <- sort(grep("time|source|dt", names(WAPI_hourly), invert = T, value = T ))
for (av in wecare) {

    par(mar = c(3,3,2,1))

    ylim <- range(WAPI_hourly[[av]], na.rm = T)

    plot(WAPI_hourly$dt, WAPI_hourly[[av]], xlab = "", ylab = "", "l", lwd = 3)

    abline(v = Sys.time(), col = "green", lty = 3, lwd = 3)

    title(paste(WAPI_metadata$City, str_date, av), cex.main = 0.8,  )

    drange <- range( dt_start,  WAPI_hourly$dt,                         na.rm = T )
    abline( v = seq( drange[1], drange[2], by = "day"), lwd = 2 , lty = 2, col = "grey" )
    abline( v = seq( drange[1], drange[2], by = "day") + 12 * 3600, lty = 3, col = "grey" )
    abline( h = pretty(WAPI_hourly[[av]], min.n = 1), lty = 2, col = "grey" )
}






if (!interactive()) { dev.off() }



####  Plot all Open Weather variables  ####

pdffile <- paste0(outdir,"/Open_Weather_Variables_",tail(fore$name,1),"_",WAPI_metadata$City, ".pdf")

if (!interactive() && (!file.exists(pdffile) || fore$Data_time > file.mtime(pdffile) + 3600)) {
    cat("Create new ", pdffile,"\n")
    pdf(pdffile, width = 9, height = 4)
}

wecare      <- sort(grep("time|source|dt", names(fore), invert = T, value = T ))
for (av in wecare) {

    par(mar = c(3,3,2,1))

    if (is.character( fore[[av]]) ) {
        cat("Skip character column", av, "\n")
        next()
    }

    if (is.null(unlist( fore[[av]] ))) { next }

    if ( all( unique(fore[[av]]) %in% c(NA,0))) {
        cat("skip",av,"\n")
        next()
    }

    plot(fore$dt, fore[[av]], xlab = "", ylab = "", "l", lwd = 3)

    abline(v = Sys.time(), col = "green", lty = 3, lwd = 3)

    str_date <- strftime( fore$dt[1], tz = "Europe/Athens", format = "%F %R" )

    title(paste(fore$name[1], str_date, av), cex.main = 0.8,  )

    drange <- range( dt_start,  fore$dt,                         na.rm = T )
    abline( v = seq( drange[1], drange[2], by = "day"), lwd = 2 , lty = 2, col = "grey" )
    abline( v = seq( drange[1], drange[2], by = "day") + 12 * 3600, lty = 3, col = "grey" )
    abline( h = pretty(fore[[av]], min.n = 1), lty = 2, col = "grey" )
}

if (!interactive()) { dev.off() }


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
fore$dt     <- as.POSIXlt(fore$dt,     tz = "Europe/Athens")
curr$dt     <- as.POSIXlt(curr$dt,     tz = "Europe/Athens")
fake_rec$dt <- as.POSIXlt(fake_rec$dt, tz = "Europe/Athens")




## subset date we want to see
fore <- fore[ fore$dt > dt_start, ]
curr <- curr[ curr$dt > dt_start, ]


fore <- fore[ fore$dt < dt_end, ]
curr <- curr[ curr$dt < dt_end, ]
WAPI_hourly <- WAPI_hourly[ WAPI_hourly$dt < dt_end, ]




#### Prepare Temperature ####
temp01 <- fore[ , grep( "dt$|temp|source|feels", names(fore), value = T)]
temp02 <- WAPI_hourly[ , grep( "dt$|emperature|source", names(WAPI_hourly), value = T)]



## unify names
names(temp01)[names(temp01) == "temp"    ] <- "Temp"
names(temp01)[names(temp01) == "temp_min"] <- "Temp_min"
names(temp01)[names(temp01) == "temp_max"] <- "Temp_max"

names(temp02)[names(temp02) == "temperature_2m_best_match" ]       <- "Temp"
names(temp02)[names(temp02) == "apparent_temperature_best_match" ] <- "Temp_feel"

Temp <- merge( temp01, temp02, all = T )
Temp <- Temp[order(Temp$dt),]
rm(temp01, temp02)


#### Prepare Rain ####

rain01 <- fore[ , grep( "dt$|rain|source",   names(fore), value = T)]
rain02 <- WAPI_hourly[ , grep( "dt$|precip|rain|source|snow|shower", names(WAPI_hourly), value = T)]


names(rain01)[names(rain01) == "rain_3h" ] <- "Rain.3h"
names(rain02)[names(rain02) == "precipitation_best_match"   ] <- "Rain.1h"


Rain <- merge( rain01, rain02, all = T )
## why?
# Rain$Rain.1h <- Rain$Rain.1h * 10
rm(rain01, rain02)

#### Prepare Wind ####
wind01 <- fore[ , grep( "dt$|wind|source", names(fore), value = T)]
## convert to km/h ?
wind01$wind_speed <- wind01$wind_speed / (10/36)
wind_gust         <- wind01$wind_gust / (10/36)

wind02 <- WAPI_hourly[ , grep( "dt$|wind|source", names(WAPI_hourly), value = T)]


Wind <- merge( wind01, wind02, all = T )
# rm(wind01, wind02)

## conver to km/h
# Wind$wind_speed <- Wind$wind_speed * (10/36)
# Wind$wind_gust  <- Wind$wind_gust  * (10/36)
# Wind$windGust   <- Wind$windGust * (10/36)


#### Prepare Cloud ####
cloud1 <- fore[ , grep( "dt$|cloud|source", names(fore), value = T)]
cloud1$clouds_all <- cloud1$clouds_all / 100
cloud2 <- WAPI_hourly[ , grep( "dt$|cloud|source", names(WAPI_hourly), value = T)]
wecare <- grep("cloud",names(cloud2), value = T )
cloud2[wecare] <- cloud2[wecare] / 100


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



WAPI_daily       <- WAPI_daily[ WAPI_daily$From <= dt_end, ]


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

# plot( testa$dt, testa$appTemp,   "l")
# lines(testa$dt, testa$outTemp,   col = 2)
# lines(testa$dt, testa$heatindex, col = 3)
# lines(testa$dt, testa$humidex, col = 3)


#### Start plotting ####
 # x11()
Sys.setlocale(locale = "el_GR.utf8")

if (!interactive()) {
png( OUTPUT_01, bg = "transparent", family = "Liberation Sans",
     width = 540, height = 255, units = "px", pointsize = 15, type = "cairo")
}

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
    wrange <- range( Wind$wind_speed, Wind$windspeed_10m_best_match  , na.rm = T )
    name   <- as.character(tail(curr$name[!is.na(curr$name)],1))

    ## set colors
    par(bg = "transparent")
    # par(bg = "black")


    ## adjust clouds to rain
    upcloud <- rrange[2]
    dncloud <- rrange[2] - (rrange[2] - rrange[1]) * CLOUD_PLOT
    ## height of cloud to plot in rain units
    Cloud$cloud_cover <- (upcloud - dncloud) * Cloud$clouds_all
    Cloud$cloudCover  <- (upcloud - dncloud) * Cloud$cloudcover_best_match


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
    rect(WAPI_daily$sunrise, trange[1] - 10,
         WAPI_daily$sunset,  trange[2] + 10,
         col = col_sun, border = NA, lwd = 1 )

    ## plot lap davis
    lines(lapd$dt, lapd$appTemp,   col = "red", lty = 1 )
    lines(lapd$dt, lapd$outTemp,   col = "red", lty = 2 )
    lines(lapd$dt, lapd$heatindex, col = "red", lty = 3 )


    ## plot daily extremes
    # segments(x0 = WAPI_daily$From, x1 = WAPI_daily$Until,
    #          y0 = WAPI_daily$temperature_2m_max_best_match,     col = "green", lwd = 2 )
    # segments(x0 = WAPI_daily$From, x1 = WAPI_daily$Until,
    #          y0 = WAPI_daily$temperature_2m_min_best_match,     col = "cyan", lwd = 2 )
    # segments(x0 = WAPI_daily$From, x1 = WAPI_daily$Until,
    #          y0 = WAPI_daily$apparent_temperature_max_best_match, col = "green", lwd = 2, lty = 2 )
    # segments(x0 = WAPI_daily$From, x1 = WAPI_daily$Until,
    #          y0 = WAPI_daily$apparent_temperature_min_best_match, col = "cyan", lwd = 2, lty = 2 )




    ## plot temperature lines
    lines(Temp$dt[Temp$source == "OpenWeatherMAP"], Temp$Temp[      Temp$source == "OpenWeatherMAP"], lwd = 3, col = col_open)
    lines(Temp$dt[Temp$source == "OpenWeatherMAP"], Temp$feels_like[Temp$source == "OpenWeatherMAP"], lwd = 3, col = col_open, lty = 3)
    lines(Temp$dt[Temp$source == "OpenMeteo"],      Temp$Temp[      Temp$source == "OpenMeteo"],      lwd = 3, col = col_dark)
    lines(Temp$dt[Temp$source == "OpenMeteo"],      Temp$Temp_feel[ Temp$source == "OpenMeteo"],      lwd = 3, col = col_dark, lty = 3)
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
        rect(WAPI_daily$sunrise, trange[1] - 10,
             WAPI_daily$sunset,  trange[2] + 10,
             col = col_sun, border = NA, lwd = 1 )

        ## add decoration
        abline( v = seq( drange[1], drange[2], by = "day"), lwd = 2 , lty = 2, col = col_grid )
        abline( v = seq( drange[1], drange[2], by = "day") + 12*3600, lty = 3, col = col_grid )
        abline( h = pretty(drange, min.n = 1), lty = 2, col = col_grid )
        abline( v = Sys.time(), lwd = 2, lty = 2, col = col_font )

        ## Precipitation probability
        pp    <- data.table(Precip_Proba = fore$Precip_Proba)
        pp$dt <- as.POSIXct(fore$dt)
        pp <- pp[, 100*max(Precip_Proba), by = as.Date(dt)]
        pp$dt <- as.POSIXct(strptime(paste( pp$as.Date, "00:00" ), "%F %H:%M", tz = "Europe/Athens"))

        text(x = pp$dt,
             y = rrange[2],
             labels = paste0(pp$V1,"%"),
             adj = c(0,1.1),
             cex = 1.3, font = 2, col = "magenta")

        Rain$Rain.1h[Rain$Rain.1h == 0] <- NA
        Rain$Rain.3h[Rain$Rain.3h == 0] <- NA

        rect(Cloud$dt[Cloud$source == "OpenMeteo"],            upcloud,
             Cloud$dt[Cloud$source == "OpenMeteo"] - 1 * 3600, upcloud - Cloud$cloudCover[Cloud$source == "OpenMeteo"],
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

        lines(Wind$dt[Wind$source == "OpenWeatherMAP"], Wind$wind_speed[Wind$source == "OpenWeatherMAP"],
              lwd = 2, col = col_open)
        lines(Wind$dt[Wind$source == "OpenMeteo"], Wind$windspeed_10m_best_match[Wind$source == "OpenMeteo"],
              lwd = 2, col = col_dark)


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

if (!interactive()) {dev.off()}
Sys.setlocale(locale = "en_US.utf8")

## copy conky image to log
if (Sys.info()["nodename"] == "tyler") {
    file.copy(OUTPUT_01, outdir, overwrite = TRUE )
}

