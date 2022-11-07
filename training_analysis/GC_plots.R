#!/usr/bin/env Rscript

#### Golden Cheetah plots
## This is incorporated to conky


####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- funr::sys.script()

inputdata   <- "~/LOGs/GCmetrics.Rds"
moredata    <- "~/DATA/Other/GC_json_data.Rds"
outputpdf   <- paste0("~/LOGs/car_logs/", basename(sub("\\.R$",".pdf", Script.Name)))
datascript  <- "~/CODE/training_analysis/GC_read_activities.R"
daysback    <- 360*3
hourstriger <- 4

if (!interactive()) {
    ## check if we have to run
    if (!file.exists(outputpdf) |
        !file.exists("/dev/shm/CONKY/banister_EPOC_400.png") |
        file.mtime(inputdata) > file.mtime(outputpdf) |
        file.mtime(outputpdf) < Sys.time() - hourstriger * 3600) {
        cat(paste("will run"))
    } else {
        stop("Don't have to run")
    }
    pdf(outputpdf, width = 9, height = 5)
}


library(data.table)
source("~/FUNCTIONS/R/data.R")

## run other data gather
source(datascript)
metrics <- readRDS("~/DATA/Other/Train_metrics.Rds")
metrics <- metrics[date > Sys.Date() - daysback, ]




fATL1 <- 1 / 7
fATL2 <- 1 - exp(-fATL1)
fCTL1 <- 1 / 42
fCTL2 <- 1 - exp(-fCTL1)

## select metrics for pdf
wecare <- c("TRIMP_Points", "TRIMP_Zonal_Points", "EPOC")
## work, calories
extend <- 30
pdays  <- c(400, 100)

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

for (days in pdays) {
    for (avar in wecare) {

        pp <- data.table(time            = metrics$time,
                         value           = metrics[[avar]],
                         VO2max_detected = metrics$VO2max_detected)
        pp <- pp[, .(value           = sum(value, na.rm = TRUE),
                     VO2max_detected = mean(VO2max_detected, na.rm = TRUE)),
                 by = .(date = as.Date(time))]
        last <- pp[ date == max(date), ]
        pp <- merge(
            data.table(date = seq.Date(from = min(pp$date),
                                       to   = max(pp$date) + extend,
                                       by   = "day")),
            pp, all = T)
        pp[is.na(value), value := 0]

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
            ## calculate impulse
            pp$ATL1[nr] <- fATL1 * pp$value[nr] + (1 - fATL1) * pp$ATL1[nr - 1]
            pp$ATL2[nr] <- fATL2 * pp$value[nr] + (1 - fATL2) * pp$ATL2[nr - 1]
            pp$CTL1[nr] <- fCTL1 * pp$value[nr] + (1 - fCTL1) * pp$CTL1[nr - 1]
            pp$CTL2[nr] <- fCTL2 * pp$value[nr] + (1 - fCTL2) * pp$CTL2[nr - 1]
            ## calculate banister
            res <- banister(fitness = pp$ban.fitness[nr-1],
                            fatigue = pp$ban.fatigue[nr-1],
                            trimp   = pp$value[nr] )
            pp$ban.fatigue[nr] <- res$fatigue
            pp$ban.fitness[nr] <- res$fitness
            pp$ban.perform[nr] <- res$performance
            ## calculate busso
            res <- busso(fitness = pp$bus.fitness[nr-1],
                         fatigue = pp$bus.fatigue[nr-1],
                         par2    = pp$bus.par2[nr-1],
                         trimp   = pp$value[nr] )
            pp$bus.fatigue[nr] <- res$fatigue
            pp$bus.fitness[nr] <- res$fitness
            pp$bus.perform[nr] <- res$performance
            pp$bus.par2[nr]    <- res$par2
        }
        pp[, TSB1 := CTL1 - ATL1]
        pp[, TSB2 := CTL2 - ATL2]





        ## limit graph to last days
        pp <- pp[ date >= max(date) - days, ]

        #### Training Impulse model plot ####
        par("mar" = c(2,0,3,0), xpd = TRUE)

        pp[ value == 0, value := NA ]
        plot(pp$value/4, ylim = range(0, pp$value, na.rm = T), type = "h", bty = "n", lwd = 2, col = "#71717171" )
        pp[ is.na(value), value := 0 ]
        lines(caTools::runmean(pp$value, k = 8, align = "right")/2, col = "#71717171", lwd = 1.1)
        par(new = T)
        ylim <-range( 45,53, pp$VO2max_detected, na.rm = T)
        plot( pp$date, pp$VO2max_detected, ylim = ylim, col = "pink", pch = "-", cex = 2 )
        par(new = T)
        ylim <- range(pp$ATL2, pp$CTL2, pp$TSB2, na.rm = T)
        ylim[2] <- ylim[2] * 1.09
        plot(pp$date, pp$ATL2, col = 3, lwd = 1.1, "l", yaxt = "n", ylim = ylim)
        abline(v=Sys.Date(),col="green",lty=2)
        par(new = T)
        plot(pp$date, pp$CTL2, col = 5, lwd = 2.5, "l", yaxt = "n", ylim = ylim)
        par(new = T)
        plot(pp$date, pp$TSB2, col = 6, lwd = 2.5, "l", yaxt = "n", ylim = ylim)

        legend("top",bty = "n",ncol = 3, lty = 1, inset = c(0, -0.05), cex = 0.7,
               legend = c("ATL2", "CTL2","TSB2"),
               col    = c(    3 ,     5 ,    6 ) )

        prediction <- pp[ date > last$date, ]
        best       <- prediction[which.max(TSB2)]
        abline(v=best$date, col = "yellow", lty = 2)
        abline(h=best$TSB2, col = "yellow", lty = 2)

        abline(h = pp[ date == Sys.Date(), TSB2 ], col = 6, lty = 2)
        text(pp[ which.max(pp$TSB2), date ], pp[ which.max(pp$TSB2), TSB2 ],
             labels = round(pp[ which.max(pp$TSB2), TSB2]), col = 6, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), TSB2 ],
             labels = round(pp[ date == Sys.Date(), TSB2 ]), col = 6, pos = 4 )
        abline(h = pp[ date == Sys.Date(), CTL2 ], col = 5, lty = 2)
        text(pp[ which.max(pp$CTL2), date ], pp[ which.max(pp$CTL2), CTL2 ],
             labels = round(pp[ which.max(pp$CTL2), CTL2]), col = 5, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), CTL2 ],
             labels = round(pp[ date == Sys.Date(), CTL2 ]), col = 5, pos = 4 )
        # abline(h = max(pp$ATL2, na.rm = T), col = 3, lty = 2)
        text(pp[ which.max(pp$ATL2), date ], pp[ which.max(pp$ATL2), ATL2 ],
             labels = round(pp[ which.max(pp$ATL2), ATL2]), col = 3, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), ATL2 ],
             labels = round(pp[ date == Sys.Date(), ATL2 ]), col = 3, pos = 4 )

        title(paste(days,"days", avar,"best:", best$date),line = 2)


        #### Banister model plot ####
        par("mar" = c(2,0,3,0), xpd = TRUE)

        pp[ value == 0, value := NA ]
        plot(pp$value/4, ylim = range(0, pp$value, na.rm = T), type = "h", bty = "n", lwd = 2, col = "#71717171" )
        pp[ is.na(value), value := 0 ]
        lines(caTools::runmean(pp$value, k = 8, align = "right")/2, col = "#71717171", lwd = 1.1)
        par(new = T)
        ylim <-range( 45,55, pp$VO2max_detected, na.rm = T)
        plot( pp$date, pp$VO2max_detected, ylim = ylim, col = "pink",pch = "-", cex = 2 )
        par(new = T)
        ylim <- range(pp$ban.fatigue, pp$ban.fitness, pp$ban.perform, na.rm = T)
        ylim[2] <- ylim[2] * 1.09
        plot( pp$date, pp$ban.fatigue, lwd = 1.1, "l", col = 3, yaxt = "n", ylim = ylim)
        par(new = T)
        plot( pp$date, pp$ban.fitness, lwd = 2.5, "l", col = 5, yaxt = "n", ylim = ylim)
        par(new = T)
        plot( pp$date, pp$ban.perform, lwd = 2.5, "l", col = 6, yaxt = "n", ylim = ylim)

        legend("top",bty = "n",ncol = 3,lty=1, inset=c(0,-0.05), cex = 0.7,
               legend = c("Fatigue","Fitness","Performance"),
               col    = c(       3 ,       5 ,           6 ) )
        abline(v=Sys.Date(),col="green",lty=2)

        prediction <- pp[ date > last$date, ]
        best       <- prediction[which.max(ban.perform)]
        abline(v=best$date, col = "yellow",lty=2)
        abline(h=best$ban.perform, col = "yellow",lty=2)

        abline(h = pp[ date == Sys.Date(), ban.perform ], col = 6, lty = 2)
        text(pp[ which.max(pp$ban.perform), date ], pp[ which.max(pp$ban.perform), ban.perform ],
             labels = round(pp[ which.max(pp$ban.perform), ban.perform]), col = 6, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), ban.perform ],
             labels = round(pp[ date == Sys.Date(), ban.perform ]), col = 6, pos = 4 )
        abline(h = pp[ date == Sys.Date(), ban.fitness ], col = 5, lty = 2)
        text(pp[ which.max(pp$ban.fitness), date ], pp[ which.max(pp$ban.fitness), ban.fitness ],
             labels = round(pp[ which.max(pp$ban.fitness), ban.fitness]), col = 5, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), ban.fitness ],
             labels = round(pp[ date == Sys.Date(), ban.fitness ]), col = 5, pos = 4 )
        # abline(h = max(pp$ban.fatigue, na.rm = T), col = 3, lty = 2)
        text(pp[ which.max(pp$ban.fatigue), date ], pp[ which.max(pp$ban.fatigue), ban.fatigue ],
             labels = round(pp[ which.max(pp$ban.fatigue), ban.fatigue]), col = 3, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), ban.fatigue ],
             labels = round(pp[ date == Sys.Date(), ban.fatigue ]), col = 3, pos = 4 )

        title(paste("Banister",days,"days", avar,"best:", best$date),line = 2)



        #### Busson model plot ####
        par("mar" = c(2,0,3,0), xpd = TRUE)

        pp[ value == 0, value:=NA ]
        plot(pp$value/4, ylim = range(0, pp$value, na.rm = T), type = "h", bty = "n", lwd = 2, col = "#71717171" )
        pp[ is.na(value), value := 0 ]
        lines(caTools::runmean(pp$value, k = 8, align = "right")/2, col = "#71717171", lwd = 1.1)
        par(new = T)
        ylim <-range( 45,65, pp$VO2max_detected, na.rm = T)
        plot( pp$date, pp$VO2max_detected, ylim = ylim, col = "pink",pch = "-", cex = 2 )
        par(new = T)

        plot( pp$date, pp$bus.fatigue, lwd = 1.1, "l", col = 3, yaxt="n")
        # abline(h = max(pp$bus.fatigue, na.rm = T), col = 3, lty = 2)
        text(pp[ which.max(pp$bus.fatigue), date ], pp[ which.max(pp$bus.fatigue), bus.fatigue ],
             labels = round(pp[ which.max(pp$bus.fatigue), bus.fatigue]), col = 3, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), bus.fatigue ],
             labels = round(pp[ date == Sys.Date(), bus.fatigue ]), col = 3, pos = 4 )
        par(new = T)
        plot( pp$date, pp$bus.fitness, lwd = 2.5, "l", col = 5, yaxt="n")
        abline(h = pp[ date == Sys.Date(), bus.fitness ], col = 5, lty = 2)
        text(pp[ which.max(pp$bus.fitness), date ], pp[ which.max(pp$bus.fitness), bus.fitness ],
             labels = round(pp[ which.max(pp$bus.fitness), bus.fitness]), col = 5, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), bus.fitness ],
             labels = round(pp[ date == Sys.Date(), bus.fitness ]), col = 5, pos = 4 )
        par(new = T)
        plot( pp$date, pp$bus.perform, lwd = 2.5, "l", col = 6, yaxt="n")
        abline(h = pp[ date == Sys.Date(), bus.perform ], col = 6, lty = 2)
        text(pp[ which.max(pp$bus.perform), date ], pp[ which.max(pp$bus.perform), bus.perform ],
             labels = round(pp[ which.max(pp$bus.perform), bus.perform]), col = 6, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), bus.perform ],
             labels = round(pp[ date == Sys.Date(), bus.perform ]), col = 6, pos = 4 )
        legend("top",bty = "n",ncol = 3,lty=1, inset=c(0,-0.05), cex = 0.7,
               legend = c("Fatigue","Fitness","Performance"),
               col    = c(       3 ,       5 ,           6 ) )
        abline(v=Sys.Date(),col="green",lty=2)

        prediction <- pp[ date > last$date, ]
        best       <- prediction[which.max(bus.perform)]
        abline(v=best$date, col = "yellow",lty=2)
        abline(h=best$bus.perform, col = "yellow",lty=2)

        title(paste("Busson", days,"days", avar,"best:", best$date),line = 2)
    }
}




## select metrics for png
wecare <- c("TRIMP_Points","TRIMP_Zonal_Points","EPOC")
extend <- 30
pdays  <- c(400, 100)

for (days in pdays) {
    for (avar in wecare) {

        pp <- data.table(time            = metrics$time,
                         value           = metrics[[avar]],
                         VO2max_detected = metrics$VO2max_detected)
        pp <- pp[, .(value           = sum(value, na.rm = T),
                     VO2max_detected = mean(VO2max_detected, na.rm = T) ),
                 by = .(date = as.Date(time))]
        last <- pp[ date == max(date),]

        datesseq <- data.table(date = seq.Date(from = min(pp$date),
                                               to = max(pp$date) + extend,
                                               by = "day"))
        pp       <- merge(datesseq, pp, all = T, by = "date")

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
        pp <- pp[ date >= max(date) - days, ]

        #### Training Impulse model plot ####
        png(paste0("/dev/shm/CONKY/trimp_",avar,"_",days,".png"),
            width = 470, height = 200, units = "px", bg = "transparent")

        par("mar"    = c(2,0,0,0),
            col      = "white",
            col.axis = "white",
            col.lab  = "white",
            yaxt     = "n")

        pp[ value == 0, value := NA ]
        plot(pp$date, pp$value/4, ylim = range(0, pp$value, na.rm = T), xaxt = "n", type = "h", lwd = 2, col = "#71717171" )
        pp[ is.na(value), value := 0 ]
        lines(pp$date, caTools::runmean(pp$value, k = 8, align = "right")/2, col = "#71717171", lwd = 1.1)
        box(col="white")
        par(new = T)
        ylim <-range( 45,65, pp$VO2max_detected, na.rm = T)
        plot( pp$date, pp$VO2max_detected, ylim = ylim, xaxt = "n", col = "pink", pch = "-", cex = 2 )
        box(col="white")
        par(new = T)
        ylim <- range(pp$ATL2, pp$CTL2, pp$TSB2, na.rm = T)
        ylim[2] <- ylim[2] * 1.09
        plot(pp$date, pp$ATL2, col = 3, lwd = 1.0, "l", ylim = ylim, xaxt = "n")
        box(col="white")
        abline(v = Sys.Date(), col = "green", lty = 2)
        par(new = T)
        plot(pp$date, pp$CTL2, col = 5, lwd = 2.5, "l", ylim = ylim, xaxt = "n")
        box(col="white")
        par(new = T)
        plot(pp$date, pp$TSB2, col = 6, lwd =   3, "l", ylim = ylim, xaxt = "n")
        box(col="white")

        legend("top", bty = "n", ncol = 3, lty=1, inset=c(0,-0.05), cex = 0.7,
               legend = c("ATL2", "CTL2", "TSB2"),
               col    = c(    3 ,     5 ,     6 ) )

        prediction <- pp[ date > last$date, ]
        best       <- prediction[which.max(TSB2)]
        abline(v = best$date, col = "yellow", lty = 2)
        abline(h = best$TSB2, col = "yellow", lty = 2)

        abline(h = pp[ date == Sys.Date(), TSB2 ], col = 6, lty = 2)
        text(pp[ which.max(pp$TSB2), date ], pp[ which.max(pp$TSB2), TSB2 ],
             labels = round(pp[ which.max(pp$TSB2), TSB2]), col = 6, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), TSB2 ],
             labels = round(pp[ date == Sys.Date(), TSB2 ]), col = 6, pos = 4 )
        abline(h = pp[ date == Sys.Date(), CTL2 ], col = 5, lty = 2)
        text(pp[ which.max(pp$CTL2), date ], pp[ which.max(pp$CTL2), CTL2 ],
             labels = round(pp[ which.max(pp$CTL2), CTL2]), col = 5, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), CTL2 ],
             labels = round(pp[ date == Sys.Date(), CTL2 ]), col = 5, pos = 4 )
        text(pp[ which.max(pp$ATL2), date ], pp[ which.max(pp$ATL2), ATL2 ],
             labels = round(pp[ which.max(pp$ATL2), ATL2]), col = 3, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), ATL2 ],
             labels = round(pp[ date == Sys.Date(), ATL2 ]), col = 3, pos = 4 )

        legend("topleft",bty = "n",title = paste(avar, best$date),legend = c(""))

        axis(1, at = pp[wday(date) == 2, date ], labels = F, col = "white", col.ticks = "white")
        axis(1, at = pp[mday(date) == 1, date ], labels = format(pp[mday(date) == 1, date ], "%b" ), col = "white", col.ticks = "white", lwd.ticks = 3)

        dev.off()



        #### Banister model plot ####
        png(paste0("/dev/shm/CONKY/banister_",avar,"_",days,".png"), width = 470, height = 200, units = "px", bg = "transparent")

        par("mar"    = c(2,0,0,0),
            col      = "white",
            col.axis = "white",
            col.lab  = "white",
            yaxt     = "n")

        plot(pp$value/4, ylim = range(0, pp$value, na.rm = T), yaxt = "n", xaxt = "n", type = "h", bty = "n", lwd = 2, col = "#71717171" )
        pp[ is.na(value), value := 0 ]
        lines(caTools::runmean(pp$value, k = 8, align = "right")/2, col = "#71717171", lwd = 1.1)
        box(col="white")
        par(new = T)
        ylim <-range( 45,55, pp$VO2max_detected, na.rm = T)
        plot( pp$date, pp$VO2max_detected, ylim = ylim, col = "pink", yaxt = "n", xaxt = "n", pch = "-", cex = 2 )
        box(col="white")
        par(new = T)
        ylim <- range(pp$ban.fatigue, pp$ban.fitness, pp$ban.perform, na.rm = T)
        ylim[2] <- ylim[2] * 1.09
        plot( pp$date, pp$ban.fatigue, lwd = 1.0, "l", col = 3, yaxt = "n", xaxt = "n", ylim = ylim)
        box(col="white")
        par(new = T)
        plot( pp$date, pp$ban.fitness, lwd = 2.5, "l", col = 5, yaxt = "n", xaxt = "n", ylim = ylim)
        box(col="white")
        par(new = T)
        plot( pp$date, pp$ban.perform, lwd =   3, "l", col = 6, yaxt = "n", xaxt = "n", ylim = ylim)
        box(col="white")

        legend("top",bty = "n",ncol = 3,lty=1, inset=c(0,-0.05), cex = 0.7,
               legend = c("Fatigue","Fitness","Performance"),
               col    = c(       3 ,       5 ,           6 ) )
        abline(v=Sys.Date(),col="green",lty=2)

        prediction <- pp[ date > last$date, ]
        best       <- prediction[which.max(ban.perform)]
        abline(v=best$date, col = "yellow",lty=2)
        abline(h=best$ban.perform, col = "yellow",lty=2)

        abline(h = pp[ date == Sys.Date(), ban.perform ], col = 6, lty = 2)
        text(pp[ which.max(pp$ban.perform), date ], pp[ which.max(pp$ban.perform), ban.perform ],
             labels = round(pp[ which.max(pp$ban.perform), ban.perform]), col = 6, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), ban.perform ],
             labels = round(pp[ date == Sys.Date(), ban.perform ]), col = 6, pos = 4 )
        abline(h = pp[ date == Sys.Date(), ban.fitness ], col = 5, lty = 2)
        text(pp[ which.max(pp$ban.fitness), date ], pp[ which.max(pp$ban.fitness), ban.fitness ],
             labels = round(pp[ which.max(pp$ban.fitness), ban.fitness]), col = 5, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), ban.fitness ],
             labels = round(pp[ date == Sys.Date(), ban.fitness ]), col = 5, pos = 4 )
        # abline(h = max(pp$ban.fatigue, na.rm = T), col = 3, lty = 2)
        text(pp[ which.max(pp$ban.fatigue), date ], pp[ which.max(pp$ban.fatigue), ban.fatigue ],
             labels = round(pp[ which.max(pp$ban.fatigue), ban.fatigue]), col = 3, pos = 3 )
        text(Sys.Date(), pp[ date == Sys.Date(), ban.fatigue ],
             labels = round(pp[ date == Sys.Date(), ban.fatigue ]), col = 3, pos = 4 )

        legend("topleft",bty = "n",title = paste(avar, best$date),legend = c(""))

        axis(1, at = pp[wday(date) == 2, date ], labels = F, col = "white", col.ticks = "white")
        axis(1, at = pp[mday(date) == 1, date ], labels = format(pp[mday(date) == 1, date ], "%b" ), col = "white", col.ticks = "white", lwd.ticks = 3)


        dev.off()



        #### Busson model plot ####
        png(paste0("/dev/shm/CONKY/busson_",avar,"_",days,".png"), width = 470, height = 200, units = "px", bg = "transparent")

        par("mar"    = c(2,0,0,0),
            col      = "white",
            col.axis = "white",
            col.lab  = "white",
            yaxt     = "n")

        plot(pp$value/4, ylim = range(0,pp$value, na.rm = T), xaxt = "n", type = "h", bty = "n", lwd = 2, col = "#71717171" )
        pp[ is.na(value), value := 0 ]
        lines(caTools::runmean(pp$value, k = 8, align = "right")/2, col = "#71717171", lwd = 1.1)
        box(col="white")
        par(new = T)
        ylim <-range( 45,55, pp$VO2max_detected, na.rm = T)
        plot( pp$date, pp$VO2max_detected, ylim = ylim, col = "pink", xaxt = "n", pch = "-", cex = 2 )
        box(col="white")
        par(new = TRUE)
        plot( pp$date, pp$bus.fatigue, lwd = 1.0, "l", col = 3, xaxt = "n")
        box(col="white")
        par(new = T)
        plot( pp$date, pp$bus.fitness, lwd = 2.5, "l", col = 5, xaxt = "n")
        box(col="white")
        par(new = T)
        plot( pp$date, pp$bus.perform, lwd =   3, "l", col = 6, xaxt = "n")
        box(col="white")

        legend("top", bty = "n", ncol = 3, lty = 1, inset = c(0,-0.05), cex = 0.7,
               legend = c("Fatigue","Fitness","Performance"),
               col    = c(       3 ,       5 ,           6 ) )
        abline(v = Sys.Date(), col = "green", lty = 2)

        prediction <- pp[ date > last$date, ]
        best       <- prediction[which.max(bus.perform)]
        abline(v = best$date, col = "yellow", lty = 2)
        abline(h = best$bus.perform, col = "yellow", lty = 2)

        legend("topleft",bty = "n",title = paste(avar, best$date),legend = c(""))

        axis(1, at = pp[wday(date) == 2, date ], labels = F, col = "white", col.ticks = "white")
        axis(1, at = pp[mday(date) == 1, date ], labels = format(pp[mday(date) == 1, date ], "%b" ), col = "white", col.ticks = "white", lwd.ticks = 3)

        dev.off()
    }
}




####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))

