#!/usr/bin/env Rscript

#### Golden Cheetah plots for desktop with conky

## read data from json files
## Create conky plots


####_ Set environment _####
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- funr::sys.script()


storagefl   <- "~/DATA/Other/GC_json_ride_data_2.Rds"
datascript  <- "~/CODE/training_analysis/GC_read_rides_db_json.R"
outputpdf   <- paste0("~/LOGs/training_status/", basename(sub("\\.R$",".pdf", Script.Name)))
daysback    <- 365*3
hourstriger <- 4

checkfile   <- "/dev/shm/CONKY/PMC_EPOC_400.png"

if (!interactive()) {
    ## check if we have to run
    if (!file.exists(checkfile) |
        # file.mtime(inputdata) > file.mtime(outputpdf) |
        file.mtime(checkfile) < Sys.time() - hourstriger * 3600) {
        cat(paste("will run"))
    } else {
        stop("Don't have to run")
    }
}

library(data.table)
source("~/FUNCTIONS/R/data.R")

#### Load last data to plot ----------------------------------------------------
source(datascript)
metrics <- readRDS(storagefl)
metrics <- metrics[as.Date(Date) > Sys.Date() - daysback, ]
metrics <- metrics[Sport %in% c("Run", "Bike")]


#### Models parameters ---------------------------------------------------------
fATL1 <- 1 / 7             ## Short term days variable
fATL2 <- 1 - exp(-fATL1)
fCTL1 <- 1 / 42            ## Long term days variable
fCTL2 <- 1 - exp(-fCTL1)
extend <- 30               ## future projection
pdays  <- c(400, 100)      ## Plot ranges


#### Select metrics for output
wecare <- c("Trimp_Points",
            "Trimp_Zonal_Points",
            "EPOC",
            "Load_2",
            "TrimpModWeighed")

names(metrics)[names(metrics) %in% wecare]

#### Define models -------------------------------------------------------------

# fitness = 0;
# for(i=0, i < count(TRIMP); i++) {
#     fitness = fitness * exp(-1/r1) + TRIMP[i];
#     fatigue = fatigue * exp(-1/r2) + TRIMP[i];
#     performance = fitness * k1 - fatigue * k2;
# }
# k1=1.0, k2=1.8-2.0, r1=49-50, r2=11.
banister <- function(fitness, fatigue, trimp, k1 = 1.0, k2 = 1.8, r1 = 49, r2 = 11) {
    fitness     <- fitness * exp(-1 / r1) + trimp
    fatigue     <- fatigue * exp(-1 / r2) + trimp
    performance <- fitness * k1 - fatigue * k2

    list(fitness     = fitness,
         fatigue     = fatigue,
         performance = performance)
}

busso <- function(fitness, fatigue, trimp, par2 , k1 = 0.031, k3 = 0.000035, r1 = 30.8, r2 = 16.8, r3 = 2.3) {
    fitness     <- fitness * exp(-1 / r1) + trimp
    fatigue     <- fatigue * exp(-1 / r2) + trimp
    par2        <- fatigue * exp(-1 / r3) + par2
    k2          <- k3      * par2
    performance <- fitness * k1 - fatigue * k2

    list(fitness     = fitness,
         fatigue     = fatigue,
         performance = performance,
         par2        = par2)
}





#### Plot all pngs -------------------------------------------------------------

for (days in pdays) {
    for (avar in wecare) {

        pp <- data.table(time            = metrics$Date,
                         value           = metrics[[avar]],
                         VO2max_Detected = metrics$VO2max_Detected)
        pp <- pp[, .(value           = sum(value, na.rm = T),
                     VO2max_detected = mean(VO2max_Detected, na.rm = T) ),
                 by = .(Date = as.Date(time))]
        last <- pp[ Date == max(Date),]

        datesseq <- data.table(Date = seq.Date(from = min(pp$Date),
                                               to = max(pp$Date) + extend,
                                               by = "day"))
        pp       <- merge(datesseq, pp, all = T, by = "Date")

        pp[ is.na(value), value := 0]

        pp[, ATL1 := pp$value[1]]
        pp[, ATL2 := pp$value[1]]
        pp[, CTL1 := pp$value[1]]
        pp[, CTL2 := pp$value[1]]
        pp[, ban.fatigue := 0 ]
        pp[, ban.fitness := 0 ]
        pp[, ban.perform := 0 ]
        pp[, bus.fatigue := 0 ]
        pp[, bus.fitness := 0 ]
        pp[, bus.perform := 0 ]
        pp[, bus.par2    := 1 ]

        for (nr in 2:nrow(pp)) {
            pp$ATL1[nr] = fATL1 * pp$value[nr] + (1 - fATL1) * pp$ATL1[nr - 1]
            pp$ATL2[nr] = fATL2 * pp$value[nr] + (1 - fATL2) * pp$ATL2[nr - 1]
            pp$CTL1[nr] = fCTL1 * pp$value[nr] + (1 - fCTL1) * pp$CTL1[nr - 1]
            pp$CTL2[nr] = fCTL2 * pp$value[nr] + (1 - fCTL2) * pp$CTL2[nr - 1]
            ## calculate banister
            res <- banister(fitness = pp$ban.fitness[nr - 1],
                            fatigue = pp$ban.fatigue[nr - 1],
                            trimp   = pp$value[nr] )
            pp$ban.fatigue[nr] <- res$fatigue
            pp$ban.fitness[nr] <- res$fitness
            pp$ban.perform[nr] <- res$performance
            ## calculate busso
            res <- busso(fitness = pp$bus.fitness[nr - 1],
                         fatigue = pp$bus.fatigue[nr - 1],
                         par2    = pp$bus.par2[nr - 1],
                         trimp   = pp$value[nr])
            pp$bus.fatigue[nr] <- res$fatigue
            pp$bus.fitness[nr] <- res$fitness
            pp$bus.perform[nr] <- res$performance
            pp$bus.par2[nr]    <- res$par2
        }
        pp[, TSB1 := CTL1 - ATL1]
        pp[, TSB2 := CTL2 - ATL2]


        ## limit graph to last days
        pp <- pp[ Date >= max(Date) - days, ]

        #### Training Impulse model plot ####
        png(paste0("/dev/shm/CONKY/PMC_",avar,"_",days,".png"),
            width = 470, height = 200, units = "px", bg = "transparent")

        par("mar"    = c(2,0,0,0),
            col      = "white",
            col.axis = "white",
            col.lab  = "white",
            yaxt     = "n")

        pp[ value == 0, value := NA ]
        plot(pp$Date, pp$value/4, ylim = range(0, pp$value, na.rm = T), xaxt = "n", type = "h", lwd = 3, col = "#71717171" )
        pp[ is.na(value), value := 0 ]
        lines(pp$Date, caTools::runmean(pp$value, k = 8, align = "right")/2, col = "#71717171", lwd = 1.1)
        box(col="white")
        par(new = T)
        ylim <-range( 45,65, pp$VO2max_detected, na.rm = T)
        plot( pp$Date, pp$VO2max_detected, ylim = ylim, xaxt = "n", col = "pink", pch = "-", cex = 2 )
        box(col="white")
        par(new = T)
        ylim <- range(pp$ATL2, pp$CTL2, pp$TSB2, na.rm = T)
        ylim[2] <- ylim[2] * 1.1
        plot(pp$Date, pp$ATL2, col = 3, lwd = 1.0, "l", ylim = ylim, xaxt = "n")
        box(col="white")
        abline(v = Sys.Date(), col = "green", lty = 2)
        par(new = T)
        plot(pp$Date, pp$CTL2, col = 5, lwd = 2.5, "l", ylim = ylim, xaxt = "n")
        box(col="white")
        par(new = T)
        plot(pp$Date, pp$TSB2, col = 6, lwd =   3, "l", ylim = ylim, xaxt = "n")
        box(col="white")

        legend("top", bty = "n", ncol = 3, lty=1, inset = c(0,-0.04),
               cex = 0.7,  text.col = "grey",
               legend = c("ATL2", "CTL2", "TSB2"),
               col    = c(    3 ,     5 ,     6 ) )

        prediction <- pp[ Date > last$Date, ]
        best       <- prediction[which.max(TSB2)]
        abline(v = best$Date, col = "yellow", lty = 2)
        abline(h = best$TSB2, col = "yellow", lty = 2)

        abline(h = pp[ Date == Sys.Date(), TSB2 ], col = 6, lty = 2)
        text(pp[ which.max(pp$TSB2), Date ], pp[ which.max(pp$TSB2), TSB2 ],
             labels = round(pp[ which.max(pp$TSB2), TSB2]), col = 6, pos = 3 )
        text(Sys.Date(), pp[ Date == Sys.Date(), TSB2 ],
             labels = round(pp[ Date == Sys.Date(), TSB2 ]), col = 6, pos = 4 )
        abline(h = pp[ Date == Sys.Date(), CTL2 ], col = 5, lty = 2)
        text(pp[ which.max(pp$CTL2), Date ], pp[ which.max(pp$CTL2), CTL2 ],
             labels = round(pp[ which.max(pp$CTL2), CTL2]), col = 5, pos = 3 )
        text(Sys.Date(), pp[ Date == Sys.Date(), CTL2 ],
             labels = round(pp[ Date == Sys.Date(), CTL2 ]), col = 5, pos = 4 )
        text(pp[ which.max(pp$ATL2), Date ], pp[ which.max(pp$ATL2), ATL2 ],
             labels = round(pp[ which.max(pp$ATL2), ATL2]), col = 3, pos = 3 )
        text(Sys.Date(), pp[ Date == Sys.Date(), ATL2 ],
             labels = round(pp[ Date == Sys.Date(), ATL2 ]), col = 3, pos = 4 )

        legend("topleft",bty = "n",title = paste(avar, best$Date),legend = c(""))

        axis(1, at = pp[wday(Date) == 2, Date ], labels = F, col = "white", col.ticks = "white")
        axis(1, at = pp[mday(Date) == 1, Date ], labels = format(pp[mday(Date) == 1, Date ], "%b" ), col = "white", col.ticks = "white", lwd.ticks = 3)

        dev.off()



        #### Banister model plot ####
        png(paste0("/dev/shm/CONKY/BANISTER_",avar,"_",days,".png"), width = 470, height = 200, units = "px", bg = "transparent")

        par("mar"    = c(2,0,0,0),
            col      = "white",
            col.axis = "white",
            col.lab  = "white",
            yaxt     = "n")

        plot(pp$Date, pp$value/4, ylim = range(0, pp$value, na.rm = T), yaxt = "n", xaxt = "n", type = "h", bty = "n", lwd = 3, col = "#71717171" )
        pp[ is.na(value), value := 0 ]
        lines(caTools::runmean(pp$value, k = 8, align = "right")/2, col = "#71717171", lwd = 1.1)
        box(col="white")
        par(new = T)
        ylim <-range( 45,55, pp$VO2max_detected, na.rm = T)
        plot( pp$Date, pp$VO2max_detected, ylim = ylim, col = "pink", yaxt = "n", xaxt = "n", pch = "-", cex = 2 )
        box(col="white")
        par(new = T)
        ylim <- range(pp$ban.fatigue, pp$ban.fitness, pp$ban.perform, na.rm = T)
        ylim[2] <- ylim[2] * 1.1
        plot( pp$Date, pp$ban.fatigue, lwd = 1.0, "l", col = 3, yaxt = "n", xaxt = "n", ylim = ylim)
        box(col="white")
        par(new = T)
        plot( pp$Date, pp$ban.fitness, lwd = 2.5, "l", col = 5, yaxt = "n", xaxt = "n", ylim = ylim)
        box(col="white")
        par(new = T)
        plot( pp$Date, pp$ban.perform, lwd =   3, "l", col = 6, yaxt = "n", xaxt = "n", ylim = ylim)
        box(col="white")

        legend("top",bty = "n",ncol = 3,lty=1, inset=c(0,-0.04),
               cex = 0.7,  text.col = "grey",
               legend = c("Fatigue","Fitness","Performance"),
               col    = c(       3 ,       5 ,           6 ) )
        abline(v=Sys.Date(),col="green",lty=2)

        prediction <- pp[ Date > last$Date, ]
        best       <- prediction[which.max(ban.perform)]
        abline(v=best$Date, col = "yellow",lty=2)
        abline(h=best$ban.perform, col = "yellow",lty=2)

        abline(h = pp[ Date == Sys.Date(), ban.perform ], col = 6, lty = 2)
        text(pp[ which.max(pp$ban.perform), Date ], pp[ which.max(pp$ban.perform), ban.perform ],
             labels = round(pp[ which.max(pp$ban.perform), ban.perform]), col = 6, pos = 3 )
        text(Sys.Date(), pp[ Date == Sys.Date(), ban.perform ],
             labels = round(pp[ Date == Sys.Date(), ban.perform ]), col = 6, pos = 4 )
        abline(h = pp[ Date == Sys.Date(), ban.fitness ], col = 5, lty = 2)
        text(pp[ which.max(pp$ban.fitness), Date ], pp[ which.max(pp$ban.fitness), ban.fitness ],
             labels = round(pp[ which.max(pp$ban.fitness), ban.fitness]), col = 5, pos = 3 )
        text(Sys.Date(), pp[ Date == Sys.Date(), ban.fitness ],
             labels = round(pp[ Date == Sys.Date(), ban.fitness ]), col = 5, pos = 4 )
        # abline(h = max(pp$ban.fatigue, na.rm = T), col = 3, lty = 2)
        text(pp[ which.max(pp$ban.fatigue), Date ], pp[ which.max(pp$ban.fatigue), ban.fatigue ],
             labels = round(pp[ which.max(pp$ban.fatigue), ban.fatigue]), col = 3, pos = 3 )
        text(Sys.Date(), pp[ Date == Sys.Date(), ban.fatigue ],
             labels = round(pp[ Date == Sys.Date(), ban.fatigue ]), col = 3, pos = 4 )

        legend("topleft",bty = "n",title = paste(avar, best$Date),legend = c(""))

        axis(1, at = pp[wday(Date) == 2, Date ], labels = F, col = "white", col.ticks = "white")
        axis(1, at = pp[mday(Date) == 1, Date ], labels = format(pp[mday(Date) == 1, Date ], "%b" ), col = "white", col.ticks = "white", lwd.ticks = 3)


        dev.off()



        #### Busson model plot ####
        png(paste0("/dev/shm/CONKY/BUSSON_",avar,"_",days,".png"), width = 470, height = 200, units = "px", bg = "transparent")

        par("mar"    = c(2,0,0,0),
            col      = "white",
            col.axis = "white",
            col.lab  = "white",
            yaxt     = "n")

        plot(pp$Date, pp$value/4, ylim = range(0,pp$value, na.rm = T), yaxt = "n", xaxt = "n", type = "h", bty = "n", lwd = 3, col = "#71717171" )
        pp[ is.na(value), value := 0 ]
        lines(caTools::runmean(pp$value, k = 8, align = "right")/2, col = "#71717171", lwd = 1.1)
        box(col="white")
        par(new = T)
        ylim <- range( 45, 55, pp$VO2max_detected, na.rm = T)
        plot( pp$Date, pp$VO2max_detected, ylim = ylim, col = "pink", xaxt = "n", pch = "-", cex = 2 )
        box(col="white")
        par(new = TRUE)
        plot( pp$Date, pp$bus.fatigue, lwd = 1.0, "l", col = 3, xaxt = "n")
        box(col="white")
        par(new = T)
        plot( pp$Date, pp$bus.fitness, lwd = 2.5, "l", col = 5, xaxt = "n")
        box(col="white")
        par(new = T)
        plot( pp$Date, pp$bus.perform, lwd =   3, "l", col = 6, xaxt = "n")
        box(col="white")

        legend("top", bty = "n", ncol = 3, lty = 1, inset = c(0,-0.04),
               cex = 0.7, text.col = "grey",
               legend = c("Fatigue","Fitness","Performance"),
               col    = c(       3 ,       5 ,           6 ) )
        abline(v = Sys.Date(), col = "green", lty = 2)

        prediction <- pp[ Date > last$Date, ]
        best       <- prediction[which.max(bus.perform)]
        abline(v = best$Date, col = "yellow", lty = 2)
        abline(h = best$bus.perform, col = "yellow", lty = 2)

        legend("topleft",bty = "n",title = paste(avar, best$Date),legend = c(""))

        axis(1, at = pp[wday(Date) == 2, Date ], labels = F, col = "white", col.ticks = "white")
        axis(1, at = pp[mday(Date) == 1, Date ], labels = format(pp[mday(Date) == 1, Date ], "%b" ), col = "white", col.ticks = "white", lwd.ticks = 3)

        dev.off()
    }
}

#### Plot more things for the phone --------------------------------------------
source("~/CODE/training_analysis/GC_more_plots_rides_db.R")


####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))

