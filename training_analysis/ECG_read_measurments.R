#!/usr/bin/env Rscript

#### Read dubug files from ecg4everyone

####_ Set environment _####
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name = funr::sys.script()

library(myRtools)
library(data.table)
source("~/CODE/FUNCTIONS/R/data.R")


## data paths
ecgfolder  <- "~/LOGs/ecg4everyone_mbl/smp/"

filelist <- list.files(path = ecgfolder,
                       pattern = "*.tsv",
                       full.names = TRUE)
filelist <- filelist[order(file.mtime(filelist))]

gather      <- data.table()
gatherstats <- data.table()

for (af in filelist) {
    lines     <- readLines(af)
    breaks    <- grep("timestamp", lines)
    stopifnot(length(breaks) == 2)
    ## read first table
    ppg       <- lines[1:(breaks[2] - 2)]
    ppg       <- read.delim(textConnection(ppg), header = T , skip = 1)
    names(ppg)[names(ppg) == "value"] <- "ppg"
    ## read second table
    htb       <- lines[breaks[2]:length(lines)]
    htb       <- read.delim(textConnection(htb), header = T )


    ## TODO dont merge
    ## some computations have to be done before merge
    ## merge tables
    data      <- merge(ppg, htb, all = T)
    data$date <- as.POSIXct( data$timestamp / 1000 , origin = "1970-01-01" )
    data      <- data.table(data)

    ## clean
    data[RR * 6/100 > 200 , RR := NA ]


    hist(data[, abs( RR-mean(RR, na.rm = T) ) / mean(RR, na.rm = T)  ], breaks = 100)

    data[abs(RR-mean(RR,na.rm=T))/mean(RR,na.rm=T) > 1 , RR := NA ]


    data[ ppg == 0, ppg := NA]
    data[ RR  == 0, RR  := NA]
    data <- data[ !(is.na(ppg) & is.na(RR)), ]
    data[, HR := RR * 6 / 100]


    gather <- rbind(gather, data)

    ## computations
    hr        <- data[ !is.na(RR), .N/(diff(as.numeric(range(date)))/60) ]
    RR_avg    <- data[ !is.na(RR), mean(RR) ]
    hr_mean   <- mean(data$HR, na.rm = T)
    hr_median <- median(data$HR, na.rm = T)
    SDNN      <- sd(data$RR, na.rm = T)

    rMSSD  <- data[ !is.na(RR), sqrt(sum(diff(RR)^2)/(.N-1)) ]

    stats <- data.table(file      = basename(af),
                        DateMin   = min(data$date),
                        DateMax   = max(data$date),
                        hr        = hr,
                        hr_mean   = hr_mean,
                        hr_median = hr_median,
                        RR_avg    = RR_avg,
                        rMSSD     = rMSSD,
                        SDNN      = SDNN
    )

    gatherstats <- rbind(gatherstats, stats)


    par(mar = c(4,4,2,4))
    plot(  data$date, data$ppg/100, "l", col = "red")
    points(data$date, data$RR, col = "blue", pch = 19, cex = 0.5)
    axis(4, at = pretty(data$RR))
    title(basename(af), cex = 0.5)

    plot(  data$date, data$ppg, "l", col = "red")
    title(basename(af), cex = 0.5)

    plot(data$date,  data$RR, col = "blue", pch = 19, cex = 0.5)
    title(basename(af), cex = 0.5)

    plot(data$date,  data$HR, col = "blue", pch = 19, cex = 0.5)


    hist(data$RR, breaks = 100, main = basename(af), col = "blue")

    cat(paste(basename(af),
              as.POSIXct(range(data$date),
                         origin = "1970-01-01")),
        sep = "\n")
    cat(paste(print( diff(range(data$date)) )),"\n")
    cat("HR       :", hr,        "\n")
    cat("HR_mean  :", hr_mean,   "\n")
    cat("HR_median:", hr_median, "\n")
    cat("RR_avg   :", RR_avg,    "\n")
    cat("rMSSD?   :", rMSSD,     "\n")
    cat("\n")
}



hist(gather$RR, breaks = 100)
hist(gather$ppg, breaks = 100)

ylim = range(gatherstats[, c(hr, hr_mean, hr_median)])
plot(  gatherstats$DateMin, gatherstats$hr     , "l"     , ylim = ylim)
lines( gatherstats$DateMin, gatherstats$hr_mean,   col = 2 )
lines( gatherstats$DateMin, gatherstats$hr_median, col = 3 )

plot(  gatherstats$DateMin, gatherstats$RR_avg  , "l"     )
plot(  gatherstats$DateMin, gatherstats$rMSSD   , "l"     )
plot(  gatherstats$DateMin, gatherstats$SDNN    , "l"     )



####_ END _####
tac <- Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
