#!/usr/bin/env Rscript

#### Golden Cheetah plots
## This is incorporated to conky


####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()

inputdata <- "~/LOGs/GCmetrics.Rds"
outputpdf <- paste0("~/LOGs/car_logs/",  basename(sub("\\.R$",".pdf", Script.Name)))

if(!interactive()) {
    ## check if we have to run
    if (!file.exists(outputpdf) |
        file.mtime(inputdata) > file.mtime(outputpdf) |
        file.mtime(outputpdf) < Sys.time() - 12 * 3600 ) {
        cat(paste("will run"))
    } else {stop("Don't have to run")}
    pdf(outputpdf, width = 9, height = 5)
}


## load outside goldencheetah
metrics <- readRDS(inputdata)
source("~/FUNCTIONS/R/data.R")


metrics <- metrics[metrics$date > Sys.Date() - 1000,]
metrics <- rm.cols.dups.df(metrics)

library(data.table)
library(scales)


metrics <- data.table(metrics)
setorder(metrics,date)

metrics[,color := NULL]
metrics[,Data  := NULL]


wecare <- names(metrics)
wecare <- grep("date|notes|time|sport|workout_code|bike|shoes|workout_title|device|Calendar_text|Elevation_Gain_Carrying|heartbeats|Max_Core_Temperature|Checksum|Right_Balance|Percent_in_Zone|Percent_in_Pace_Zone|Best_|Distance_Swim|Equipment_Weight|Average_Core_Temperature|Average_Temp|Max_Cadence|Max_Temp|min_Peak_Pace|_Peak_Pace|_Peak_Pace_HR|_Peak_Power|_Peak_Power_HR|min_Peak_Hr|_Peak_WPK|Min_temp|Average_Cadence|Average_Running_Cadence|Max_Running_Cadence",
               wecare, ignore.case = T,value = T,invert = T)

for (avar in wecare) {
    ## ignore no data
    if (all(as.numeric(metrics[[avar]]) %in% c(0,NA))) {
        metrics[[avar]] <- NULL
        next()
    }

    plot(metrics$time, metrics[[avar]],
         type = "l", xlab = "")
    title(avar)
}
cat(paste(wecare),"\n")



fATL1 = 1/7
fATL2 = 1-exp(-fATL1)
fCTL1 = 1/42
fCTL2 = 1-exp(-fCTL1)

## select metrics for pdf
wecare <- c("Work","TRIMP_Points","TRIMP_Zonal_Points","TriScore","GOVSS","Aerobic_TISS","Anaerobic_TISS","Calories","Distance")
extend <- 15
pdays  <- c(700, 180, 90)

for (days in pdays) {
    for (avar in wecare) {

        par("mar" = c(2,2,4,1), xpd = TRUE)

        pp <- data.table(time  = metrics$time,
                         value = metrics[[avar]] )
        pp <- pp[, .(value = sum(value)), by = .(date=as.Date(time))]
        pp <- merge(
            data.table(date = seq.Date(from = min(pp$date), to = max(pp$date)+extend, by = "day")),
            pp, all = T)
        pp[is.na(value),value:=0]

        pp <- pp[ date >= max(date)-days, ]

        pp[, ATL1 := pp$value[1]]
        pp[, ATL2 := pp$value[1]]
        pp[, CTL1 := pp$value[1]]
        pp[, CTL2 := pp$value[1]]

        for (nr in 2:nrow(pp)) {
            pp$ATL1[nr] = fATL1 * pp$value[nr] + (1-fATL1) * pp$ATL1[nr-1]
            pp$ATL2[nr] = fATL2 * pp$value[nr] + (1-fATL2) * pp$ATL2[nr-1]
            pp$CTL1[nr] = fCTL1 * pp$value[nr] + (1-fCTL1) * pp$CTL1[nr-1]
            pp$CTL2[nr] = fCTL2 * pp$value[nr] + (1-fCTL2) * pp$CTL2[nr-1]
        }
        pp[, TSB1 := CTL1 - ATL1]
        pp[, TSB2 := CTL2 - ATL2]

        plot(pp$date,pp$value, col = "grey",lwd=0.7,
             type = "l", ylab = "", xlab = "")
        par(new = T)
        plot(pp$date,pp$ATL1, col = 2, lwd = 1.5,"l")

        abline(v=Sys.Date(),col="green",lty=2)
        lines(pp$date,pp$ATL1, col = 2, lwd = 1.5 )
        lines(pp$date,pp$ATL2, col = 3, lwd = 1.5 )
        lines(pp$date,pp$CTL1, col = 4, lwd = 1.5 )
        lines(pp$date,pp$CTL2, col = 5, lwd = 1.5 )

        legend("top",bty = "n",ncol = 3,lty=1, inset=c(0,-0.1), cex = 0.7,
               legend = c("ATL1","ATL2","CTL1","CTL2","TSB1","TSB2"),
               col    = c(    2 ,    3 ,    4 ,    5 ,    6 ,    7 ) )

        par(new = T)
        plot( pp$date, pp$TSB1, "l", col = 6, lwd = 1.5,
              xlab = "", ylab = "",yaxt="n", xaxt="n")
        lines(pp$date, pp$TSB2, "l", col = 7, lwd = 1.5)
        title(paste0(days,"days ", avar),line = 3)
    }
}





## select metrics for png
wecare <- c("TRIMP_Points","TriScore")
extend <- 15
pdays  <- c(500, 100)

for (days in pdays) {
    for (avar in wecare) {
        png(paste0("/dev/shm/CONKY/",avar,"_",days,".png"), width = 470, height = 200, units = "px", bg = "transparent")

        par("mar" = c(2,0,0,0), col = "white",
            col.axis = "white",
            col.lab  = "white")

        pp <- data.table(time  = metrics$time,
                         value = metrics[[avar]] )
        pp <- pp[, .(value = sum(value)), by = .(date=as.Date(time))]
        pp <- merge(
            data.table(date = seq.Date(from = min(pp$date), to = max(pp$date)+extend, by = "day")),
            pp, all = T)
        pp[is.na(value),value:=0]

        pp <- pp[ date >= max(date)-days, ]

        pp[, ATL1 := pp$value[1]]
        pp[, ATL2 := pp$value[1]]
        pp[, CTL1 := pp$value[1]]
        pp[, CTL2 := pp$value[1]]

        for (nr in 2:nrow(pp)) {
            pp$ATL1[nr] = fATL1 * pp$value[nr] + (1-fATL1) * pp$ATL1[nr-1]
            pp$ATL2[nr] = fATL2 * pp$value[nr] + (1-fATL2) * pp$ATL2[nr-1]
            pp$CTL1[nr] = fCTL1 * pp$value[nr] + (1-fCTL1) * pp$CTL1[nr-1]
            pp$CTL2[nr] = fCTL2 * pp$value[nr] + (1-fCTL2) * pp$CTL2[nr-1]
        }
        pp[, TSB1 := CTL1 - ATL1]
        pp[, TSB2 := CTL2 - ATL2]

        plot(pp$date,pp$value, col = "grey",lwd=0.7,
             type = "l", ylab = "", xlab = "")
        box(col="white")
        par(new = T)
        plot(pp$date,pp$ATL1, col = 2, lwd = 1.5,"l")
        box(col="white")

        abline(v=Sys.Date(),col="green",lty=2)
        lines(pp$date,pp$ATL1, col = 2, lwd = 2 )
        lines(pp$date,pp$ATL2, col = 3, lwd = 2 )
        lines(pp$date,pp$CTL1, col = 4, lwd = 2 )
        lines(pp$date,pp$CTL2, col = 5, lwd = 2 )

        # legend("top",bty = "n",ncol = 3,lty=1, inset=c(0,-0.1), cex = 0.7,
        #        legend = c("ATL1","ATL2","CTL1","CTL2","TSB1","TSB2"),
        #        col    = c(    2 ,    3 ,    4 ,    5 ,    6 ,    7 ) )

        par(new = T)
        plot( pp$date, pp$TSB1, "l", col = 6, lwd = 2,
              xlab = "", ylab = "",yaxt="n", xaxt="n")
        lines(pp$date, pp$TSB2, "l", col = 7, lwd = 2)
        # title(paste0(days,"days ", avar),line = 3)
        legend("topleft",bty = "n",title = paste(avar,days),legend = c(""))

        dev.off()
    }
}





####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
