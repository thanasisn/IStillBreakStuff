#!/usr/bin/env Rscript

#### Golden Cheetah plots
## This is incorporated to conky


####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "GC_plots_2.R"


moredata    <- "~/DATA/Other/GC_json_data.Rds"
outputpdf   <- paste0("~/LOGs/car_logs/", basename(sub("\\.R$",".pdf", Script.Name)))
datascript  <- "~/CODE/training_analysis/GC_read_activities.R"
daysback    <- 360*3


library(data.table)
source(datascript)
metrics <- readRDS("~/DATA/Other/Train_metrics.Rds")
metrics <- metrics[date > Sys.Date() - daysback, ]

epoc_extra <- fread("~/CODE/training_analysis/epoc.next", col.names = "value")





fATL1 <- 1 / 7
fATL2 <- 1 - exp(-fATL1)
fCTL1 <- 1 / 42
fCTL2 <- 1 - exp(-fCTL1)

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



if (!interactive()) pdf(outputpdf, width = 9, height = 4)



## select metrics for pdf
wecare <- c("TRIMP_Points", "TRIMP_Zonal_Points", "EPOC", "Session_RPE")
shortn <- c(          "TP",                 "TZ",   "EP",          "RP")
extend <- 30
pdays  <- c(100, 400, 1000, 100)

if (interactive()) pdays <- c(100)

### create metrics for all models
gather <- data.table()
for (ii in 1:length(wecare)) {
    avar <- wecare[ii]
    snam <- shortn[ii]


    ## get each variable
    pp   <- data.table(time            = metrics$time,
                       value           = metrics[[avar]],
                       VO2max_detected = metrics$VO2max_detected)
    pp   <- pp[, .(value             = sum(value, na.rm = TRUE),
                   VO2max_detected = mean(VO2max_detected, na.rm = TRUE)),
               by = .(date = as.Date(time))]
    last <- pp[ date == max(date), ]
    pp   <- merge(
        data.table(date = seq.Date(from = min(pp$date),
                                   to   = max(pp$date) + extend,
                                   by   = "day")),
        pp, all = T)
    pp[is.na(value), value := 0]

    ## test future program
    if (avar == "EPOC") {
        epoc_extra$date <- Sys.Date()
        epoc_extra$date <- epoc_extra$date + 1:nrow(epoc_extra)
        ## assuming everything is sorted witout gaps
        pp[ date %in% epoc_extra$date, value := epoc_extra$value ]
    }

    names(pp)[names(pp) == "value"]  <- paste0(snam,".","VAL")

    pp[[paste0(snam,".","PMC_FAT")]] <- pp[[paste0(snam,".","VAL")]][1]
    pp[[paste0(snam,".","PMC_FIT")]] <- pp[[paste0(snam,".","VAL")]][1]
    pp[[paste0(snam,".","PMC_PER")]] <- 0

    pp[[paste0(snam,".","BAN_FAT")]] <- 0
    pp[[paste0(snam,".","BAN_FIT")]] <- 0
    pp[[paste0(snam,".","BAN_PER")]] <- 0

    pp[[paste0(snam,".","BUS_FAT")]] <- 0
    pp[[paste0(snam,".","BUS_FIT")]] <- 0
    pp[[paste0(snam,".","BUS_PER")]] <- 0
    pp[[paste0(snam,".","BUS_pr2")]] <- 1

    for (nr in 2:nrow(pp)) {
        ## calculate impulse
        pp[[paste0(snam,".","PMC_FAT")]][nr] <-
            fATL1 * pp[[paste0(snam,".","VAL")]][nr] + (1 - fATL1) * pp[[paste0(snam,".","PMC_FAT")]][nr - 1]
        pp[[paste0(snam,".","PMC_FIT")]][nr] <-
            fCTL1 * pp[[paste0(snam,".","VAL")]][nr] + (1 - fCTL1) * pp[[paste0(snam,".","PMC_FIT")]][nr - 1]
        ## calculate banister
        res <- banister(fitness = pp[[paste0(snam,".","BAN_FIT")]][nr-1],
                        fatigue = pp[[paste0(snam,".","BAN_FAT")]][nr-1],
                        trimp   = pp[[paste0(snam,".","VAL")]][nr] )
        pp[[paste0(snam,".","BAN_FAT")]][nr] <- res$fatigue
        pp[[paste0(snam,".","BAN_FIT")]][nr] <- res$fitness
        pp[[paste0(snam,".","BAN_PER")]][nr] <- res$performance
        ## calculate busso
        res <- busso(fitness = pp[[paste0(snam,".","BUS_FIT")]][nr-1],
                     fatigue = pp[[paste0(snam,".","BUS_FAT")]][nr-1],
                     par2    = pp[[paste0(snam,".","BUS_pr2")]][nr-1],
                     trimp   = pp[[paste0(snam,".","VAL")]][nr] )
        pp[[paste0(snam,".","BUS_FAT")]][nr] <- res$fatigue
        pp[[paste0(snam,".","BUS_FIT")]][nr] <- res$fitness
        pp[[paste0(snam,".","BUS_PER")]][nr] <- res$performance
        pp[[paste0(snam,".","BUS_pr2")]][nr] <- res$par2
    }

    pp[[paste0(snam,".","BAN_VAL")]] <- pp[[paste0(snam,".","VAL")]]
    pp[[paste0(snam,".","BUS_VAL")]] <- pp[[paste0(snam,".","VAL")]]
    pp[[paste0(snam,".","PMC_VAL")]] <- pp[[paste0(snam,".","VAL")]]
    pp[[paste0(snam,".","VAL")]]     <- NULL

    pp[[paste0(snam,".","BUS_pr2")]] <- NULL
    pp[[paste0(snam,".","PMC_PER")]] <- pp[[paste0(snam,".","PMC_FIT")]] -
                                        pp[[paste0(snam,".","PMC_FAT")]]


    if (ii == 1) {
        gather <- pp
    } else {
        gather <- merge(pp, gather, by = c("date","VO2max_detected") )
    }

}



# days <- pdays[1]
for (days in pdays) {

    ## limit graph to last days
    pppppp <- gather[ date >= max(date) - days - extend, ]
    pppppp <- data.table(pppppp)
    models <- c("PMC", "BAN", "BUS")

    for (va in shortn) {
        for (mo in models) {
            wp <- c(grep(paste0(va,".",mo), names(pppppp), value = TRUE),
                    "date", "VO2max_detected")
            pp <- pppppp[, ..wp]
            ## easy names
            vfit <- grep("FIT",wp,value = T)
            vfat <- grep("FAT",wp,value = T)
            vper <- grep("PER",wp,value = T)
            vval <- grep("VAL",wp,value = T)

            #### Training Impulse model plot ####
            par("mar" = c(2,0,2,0), xpd = TRUE)

            pp[[vval]][pp[[vval]] == 0] <- NA
            plot(pp$date, pp[[vval]]/4, ylim = range(0, pp[[vval]], na.rm = T), type = "h", bty = "n", lwd = 2, col = "#71717171" )
            pp[[vval]][is.na(pp[[vval]])] <- 0
            lines(pp$date, caTools::runmean(pp[[vval]], k = 9, align = "right")/2, col = "#71717171", lwd = 1.1)
            par(new = T)
            ylim <-range( 45,53, pp$VO2max_detected, na.rm = T)
            plot( pp$date, pp$VO2max_detected, ylim = ylim, col = "pink", pch = "-", cex = 2 )
            par(new = T)
            ylim    <- range(pp[[vfit]], pp[[vfat]], pp[[vper]], na.rm = T)
            ylim[2] <- ylim[2] * 1.09
            plot(pp$date, pp[[vfat]], col = 3, lwd = 1.1, "l", yaxt = "n", ylim = ylim)
            abline(v=Sys.Date(),col="green",lty=2)
            par(new = T)
            plot(pp$date, pp[[vfit]], col = 5, lwd = 2.5, "l", yaxt = "n", ylim = ylim)
            par(new = T)
            plot(pp$date, pp[[vper]], col = 6, lwd = 2.5, "l", yaxt = "n", ylim = ylim)

            legend("top", bty = "n", ncol = 3, lty = 1, inset = c(0, -0.01),
                   cex = 0.7, text.col = "grey",
                   legend = c("Fatigue", "Fitness","Performance"),
                   col    = c(    3 ,     5 ,    6 ) )


            prediction <- pp[ date > last$date, ]
            best       <- prediction[ which.max(prediction[[vper]]) ]
            abline(v = best$date, col = "yellow", lty = 2)
            abline(h = best[[vper]], col = "yellow", lty = 2)

            abline(h = pp[[vper]][ pp$date == Sys.Date() ], col = 6, lty = 2)
            text(pp[ which.max(pp[[vper]]), date ], pp[[vper]][which.max(pp[[vper]])],
                 labels = round(pp[[vper]][which.max(pp[[vper]])]), col = 6, pos = 3 )
            text(Sys.Date(), pp[[vper]][pp$date == Sys.Date()],
                 labels = round(pp[[vper]][pp$date == Sys.Date()]), col = 6, pos = 4 )

            abline(h = pp[[vfit]][ pp$date == Sys.Date() ], col = 5, lty = 2)
            text(pp[ which.max(pp[[vfit]]), date ], pp[[vfit]][which.max(pp[[vfit]])],
                 labels = round(pp[[vfit]][which.max(pp[[vfit]])]), col = 5, pos = 3 )
            text(Sys.Date(), pp[[vfit]][pp$date == Sys.Date()],
                 labels = round(pp[[vfit]][pp$date == Sys.Date()]), col = 5, pos = 4 )

            # abline(h = pp[[vfat]][ pp$date == Sys.Date() ], col = 3, lty = 2)
            text(pp[ which.max(pp[[vfat]]), date ], pp[[vfat]][which.max(pp[[vfat]])],
                 labels = round(pp[[vfat]][which.max(pp[[vfat]])]), col = 3, pos = 3 )
            text(Sys.Date(), pp[[vfat]][pp$date == Sys.Date()],
                 labels = round(pp[[vfat]][pp$date == Sys.Date()]), col = 3, pos = 4 )

            axis(1, at = pp[wday(date) == 2, date ], labels = F, col = "black", col.ticks = "black")
            axis(1, at = pp[mday(date) == 1, date ], labels = format(pp[mday(date) == 1, date ], "%b"), col = "black", col.ticks = "black", lwd.ticks = 3)


            title(paste(days,"d ", va, " ", mo, "  best:", best$date), cex = .7)

        }
    }
}
if (!interactive()) dev.off()


####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))

