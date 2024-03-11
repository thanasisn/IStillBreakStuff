#!/usr/bin/env Rscript

#### Human Performance plots and data for GC data for different uses

# Data from main json
# Normal plots
# Unified plots
# Mobile phone plot
# Conky desktop plot

####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/training_analysis/GC_data_proccess/GC_more_plots_rides_db.R"


storagefl   <- "~/DATA/Other/GC_json_ride_data_2.Rds"
datascript  <- "~/CODE/training_analysis/GC_data_proccess/GC_read_rides_db_json.R"
outputpdf   <- paste0("~/LOGs/training_status/", basename(sub("\\.R$",".pdf", Script.Name)))
daysback    <- 370 * 4

allmodelspdf <- paste0("~/LOGs/training_status/", basename(sub("\\.R$","", Script.Name)), "_all_models.pdf")
unifiedpdf   <- paste0("~/LOGs/training_status/", basename(sub("\\.R$","", Script.Name)), "_unified.pdf")
loadtables   <- "~/LOGs/training_status/Load_tables.md"
lastactivit  <- "~/LOGs/training_status/Last_Activities.md"

# paste0("/home/athan/LOGs/training_status/", va, ".png")


library(data.table)
library(lubridate)
library(pander)
library(caTools)

source("~/CODE/FUNCTIONS/R/make_tools.R")
source("~/CODE/FUNCTIONS/R/data.R")

Rmk_check_dependencies(depend.source = Script.Name,
                       depend.data   = storagefl,
                       targets       = c(loadtables))


#### Load last data to plot ----------------------------------------------------
# source(datascript)

metrics <- readRDS(storagefl)
metrics <- metrics[as.Date(Date) > Sys.Date() - daysback, ]
metrics <- metrics[Sport %in% c("Run", "Bike")]


epoc_extra <- fread("~/CODE/training_analysis/epoc.next", col.names = "value")


#### Models parameters ---------------------------------------------------------
fATL1 <- 1 / 7             ## Short term days variable
fATL2 <- 1 - exp(-fATL1)
fCTL1 <- 1 / 42            ## Long term days variable
fCTL2 <- 1 - exp(-fCTL1)

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



if (!interactive()) pdf(allmodelspdf, width = 9, height = 4)

## select metrics for pdf
wecare <- c("Trimp_Points", "Trimp_Zonal_Points", "EPOC", "Load_2", "TrimpModWeighed")
shortn <- c(          "TP",                 "TZ",   "EP",     "L2",              "TW")
extend <- 30
pdays  <- c(100, 450, daysback)


if (interactive()) pdays <- c(100)

### compute metrics for all models ####
gather <- data.table()
for (ii in 1:length(wecare)) {
    avar <- wecare[ii]
    snam <- shortn[ii]

    ## get each variable
    pp   <- data.table(time            = metrics$Date,
                       value           = metrics[[avar]],
                       VO2max_Detected = metrics$VO2max_Detected,
                       Pch             = round(median(metrics$Pch)))
    pp   <- pp[, .(value           = sum(value, na.rm = TRUE),
                   VO2max_Detected = mean(VO2max_Detected, na.rm = TRUE)),
               by = .(Date = as.Date(time))]
    last <- pp[ Date == max(Date), ]
    pp   <- merge(
        data.table(Date = seq.Date(from = min(pp$Date),
                                   to   = max(pp$Date) + extend,
                                   by   = "day")),
        pp, all = T)
    pp[is.na(value), value := 0]

    ## test future program
    if (avar == "EPOC") {
        epoc_extra$Date <- Sys.Date()
        epoc_extra$Date <- epoc_extra$Date + 1:nrow(epoc_extra)
        ## assuming everything is sorted witout gaps
        pp[ Date %in% epoc_extra$Date, value := epoc_extra$value ]
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
        gather <- merge(pp, gather, by = c("Date","VO2max_Detected") )
    }
}



####  Normal plot of all vars and models  ####
for (days in pdays) {
    ## limit graphs to last days
    pppppp <- gather[ Date >= max(Date) - days - extend, ]
    pppppp <- data.table(pppppp)
    models <- c("PMC", "BAN", "BUS")

    ####  each day bar plot of metrics  ####
    wwca <- c("EP.BAN_VAL", "TZ.BAN_VAL", "TP.BAN_VAL")
    ylim <- range(pppppp[ , ..wwca ], na.rm = T)

    par("mar" = c(2,2,0.1,2), xpd = FALSE)
    plot( as.POSIXct(pppppp$Date)            , pppppp$EP.BAN_VAL, type = "h", col = 2, ylim = ylim, xlab = "", ylab = "")
    lines(as.POSIXct(pppppp$Date) +  3 * 3600, pppppp$TZ.BAN_VAL, type = "h", col = 3)
    lines(as.POSIXct(pppppp$Date) +  9 * 3600, pppppp$TP.BAN_VAL, type = "h", col = 4)
    # lines(as.POSIXct(pppppp$Date) + 12 * 3600, pppppp$RP.BAN_VAL, type = "h", col = 5)
    legend("top", bty = "n", ncol = 4, lty = 1, inset = c(0, -0.01),
           cex = 0.7, text.col = "black",
           legend = c("EPOC", "TRIMP ZN", "TRIMP"),
           col    = c(    2 ,           3 ,    4 ) )
    abline(h = pretty(ylim, n = 15), col = "grey", lty = 3)
    axis(4)

    ####  each week metrics bar plot  ####
    # weekly  <- pppppp[, .(EP.BAN_VAL = sum(EP.BAN_VAL, na.rm = TRUE),
    #                       TZ.BAN_VAL = sum(TZ.BAN_VAL, na.rm = TRUE),
    #                       TP.BAN_VAL = sum(TP.BAN_VAL, na.rm = TRUE)),
    #                    by = .(Year = year(Date), Week = isoweek(Date) )]
    # weekly[ , Date := as.Date(paste(Year, Week, 1, sep="-"), "%Y-%U-%u") ]

    weekly  <- pppppp[, .(EP.BAN_VAL = sum(EP.BAN_VAL, na.rm = TRUE),
                          TZ.BAN_VAL = sum(TZ.BAN_VAL, na.rm = TRUE),
                          TP.BAN_VAL = sum(TP.BAN_VAL, na.rm = TRUE)),
                       by = .(Date = floor_date(Date, unit = "week", week_start = 1) )]

    par("mar" = c(2,2,0.1,2), xpd = FALSE)
    ylim <- range(weekly[ , ..wwca ], na.rm = T)
    plot( weekly$Date    , weekly$EP.BAN_VAL, lwd = 2, type = "h", col = 2, ylim = ylim, xlab = "", ylab = "")
    lines(weekly$Date + 1, weekly$TZ.BAN_VAL, lwd = 2, type = "h", col = 3)
    lines(weekly$Date + 2, weekly$TP.BAN_VAL, lwd = 2, type = "h", col = 4)
    # lines(weekly$Date + 3, weekly$RP.BAN_VAL, lwd = 2, type = "h", col = 5)
    legend("top", bty = "n", ncol = 4, lty = 1, inset = c(0, -0.01),
           cex = 0.7, text.col = "black",
           legend = c("EPOC", "TRIMP ZN", "TRIMP"),
           col    = c(    2 ,         3 ,      4 ) )
    abline(h = pretty(ylim, n = 15), col = "grey", lty = 3)
    abline(v = weekly$Date - 0.5,    col = "grey", lty = 2)
    axis(4)

    #### normalize data ####
    wecare <- grep("Date|VO2max", names(pppppp), invert = T, value = T)
    for (ac in wecare) {
        pppppp[[ac]] <- 100 * scale(x      = pppppp[[ac]],
                                    center = min(pppppp[[ac]]),
                                    scale  = diff(range(pppppp[[ac]])))
    }


    ####  Plot for each metric and model  ####
    for (va in shortn) {
        for (mo in models) {
            wp <- c(grep(paste0(va,".",mo), names(pppppp), value = TRUE),
                    "Date", "VO2max_Detected")
            pp <- pppppp[, ..wp]
            ## easy names
            vfit <- grep("FIT", wp, value = T)
            vfat <- grep("FAT", wp, value = T)
            vper <- grep("PER", wp, value = T)
            vval <- grep("VAL", wp, value = T)

            ## Training Impulse model plot
            par("mar" = c(2,0,2,0), xpd = TRUE)

            pp[[vval]][pp[[vval]] == 0] <- NA
            plot(pp$Date, pp[[vval]]/4, ylim = range(0, pp[[vval]], na.rm = T), type = "h", bty = "n", lwd = 2, col = "#71717171" )
            pp[[vval]][is.na(pp[[vval]])] <- 0
            lines(pp$Date, caTools::runmean(pp[[vval]], k = 9, align = "right")/2, col = "#71717171", lwd = 1.1)
            par(new = T)
            ylim <- range(45, 53, pp$VO2max_Detected, na.rm = T)
            plot( pp$Date, pp$VO2max_Detected, ylim = ylim, col = "pink", pch = "-", cex = 2 )
            par(new = T)
            ylim    <- range(pp[[vfit]], pp[[vfat]], pp[[vper]], na.rm = T)
            ylim[2] <- ylim[2] * 1.09
            plot(pp$Date, pp[[vfat]], col = 3, lwd = 1.1, "l", yaxt = "n", ylim = ylim)
            abline(v = Sys.Date(), col = "green", lty = 2)
            par(new = T)
            plot(pp$Date, pp[[vfit]], col = 5, lwd = 2.5, "l", yaxt = "n", ylim = ylim)
            par(new = T)
            plot(pp$Date, pp[[vper]], col = 6, lwd = 2.5, "l", yaxt = "n", ylim = ylim)

            legend("top", bty = "n", ncol = 3, lty = 1, inset = c(0, -0.01),
                   cex = 0.7, text.col = "grey",
                   legend = c("Fatigue", "Fitness","Performance"),
                   col    = c(       3 ,        5 ,           6 ) )

            ## decoration on plots
            prediction <- pp[ Date > last$Date, ]
            best       <- prediction[ which.max(prediction[[vper]]) ]
            abline(v = best$Date, col = "yellow", lty = 2)
            abline(h = best[[vper]], col = "yellow", lty = 2)

            abline(h = pp[[vper]][ pp$Date == Sys.Date() ], col = 6, lty = 2)
            text(pp[ which.max(pp[[vper]]), Date ], pp[[vper]][which.max(pp[[vper]])],
                 labels = round(pp[[vper]][which.max(pp[[vper]])]), col = 6, pos = 3 )
            text(Sys.Date(), pp[[vper]][pp$Date == Sys.Date()],
                 labels = round(pp[[vper]][pp$Date == Sys.Date()]), col = 6, pos = 4 )

            abline(h = pp[[vfit]][ pp$Date == Sys.Date() ], col = 5, lty = 2)
            text(pp[ which.max(pp[[vfit]]), Date ], pp[[vfit]][which.max(pp[[vfit]])],
                 labels = round(pp[[vfit]][which.max(pp[[vfit]])]), col = 5, pos = 3 )
            text(Sys.Date(), pp[[vfit]][pp$Date == Sys.Date()],
                 labels = round(pp[[vfit]][pp$Date == Sys.Date()]), col = 5, pos = 4 )

            # abline(h = pp[[vfat]][ pp$Date == Sys.Date() ], col = 3, lty = 2)
            text(pp[ which.max(pp[[vfat]]), Date ], pp[[vfat]][which.max(pp[[vfat]])],
                 labels = round(pp[[vfat]][which.max(pp[[vfat]])]), col = 3, pos = 3 )
            text(Sys.Date(), pp[[vfat]][pp$Date == Sys.Date()],
                 labels = round(pp[[vfat]][pp$Date == Sys.Date()]), col = 3, pos = 4 )

            axis(1, at = pp[wday(Date) == 2, Date ], labels = F, col = "black", col.ticks = "black")
            axis(1, at = pp[mday(Date) == 1, Date ], labels = format(pp[mday(Date) == 1, Date ], "%b"), col = "black", col.ticks = "black", lwd.ticks = 3)

            title(paste(days,"d ", va, " ", mo, "  best:", best$Date), cex = .7)
        }
    }
}

if (!interactive()) dev.off()




if (!interactive()) pdf(unifiedpdf, width = 9, height = 4)

####  Plot of unified vars and models  ####
# days <- pdays[1]
for (days in pdays) {

    ## limit graph to last days
    pppppp <- gather[ Date >= max(Date) - days - extend, ]
    pppppp <- data.table(pppppp)
    models <- c("PMC", "BAN", "BUS")

    ## normalize data
    wecare <- grep("Date|VO2max", names(pppppp), invert = T, value = T)
    for (ac in wecare) {
        pppppp[[ac]] <- 100 * scale(x      = pppppp[[ac]],
                                    center = min(pppppp[[ac]]),
                                    scale  = diff(range(pppppp[[ac]])))
    }

    #### unified by model ####
    unifid <- pppppp[, .(Date, VO2max_Detected)]
    for (met in c("EP","TZ","TP")) {
        for (mod in c("PER","FAT","FIT")) {
            wem <- grep(paste0(met,".*",mod), names(pppppp), value = T)
            unifid[[paste0(met,"_",mod)]] <- rowMeans( pppppp[,  ..wem ] )
        }
    }

    par("mar" = c(2,2,2,0), xpd = TRUE)

    plot(unifid$Date, unifid$EP_PER,"l", col = 6, ylim = c(0,100))
    par(new = T)
    plot(unifid$Date, unifid$EP_FAT,"l", col = 3, ylim = c(0,100))
    par(new = T)
    plot(unifid$Date, unifid$EP_FIT,"l", col = 5, ylim = c(0,100))
    abline(v = Sys.Date(), col = "green", lty = 2)
    title("EPOC all models")
    axis(1, at = pp[wday(Date) == 2, Date ], labels = F, col = "black", col.ticks = "black")
    axis(1, at = pp[mday(Date) == 1, Date ], labels = format(pp[mday(Date) == 1, Date ], "%b"), col = "black", col.ticks = "black", lwd.ticks = 3)

    plot(unifid$Date, unifid$TZ_PER,"l", col = 6, ylim = c(0,100))
    par(new = T)
    plot(unifid$Date, unifid$TZ_FAT,"l", col = 3, ylim = c(0,100))
    par(new = T)
    plot(unifid$Date, unifid$TZ_FIT,"l", col = 5, ylim = c(0,100))
    abline(v = Sys.Date(), col = "green", lty = 2)
    title("TRIMP Zonal all models")
    axis(1, at = pp[wday(Date) == 2, Date ], labels = F, col = "black", col.ticks = "black")
    axis(1, at = pp[mday(Date) == 1, Date ], labels = format(pp[mday(Date) == 1, Date ], "%b"), col = "black", col.ticks = "black", lwd.ticks = 3)

    plot(unifid$Date, unifid$TP_PER,"l", col = 6, ylim = c(0,100))
    par(new = T)
    plot(unifid$Date, unifid$TP_FAT,"l", col = 3, ylim = c(0,100))
    par(new = T)
    plot(unifid$Date, unifid$TP_FIT,"l", col = 5, ylim = c(0,100))
    abline(v = Sys.Date(), col = "green", lty = 2)
    title("TRIMP all models")
    axis(1, at = pp[wday(Date) == 2, Date ], labels = F, col = "black", col.ticks = "black")
    axis(1, at = pp[mday(Date) == 1, Date ], labels = format(pp[mday(Date) == 1, Date ], "%b"), col = "black", col.ticks = "black", lwd.ticks = 3)

    #### unified by metric ####
    unifid <- pppppp[, .(Date, VO2max_Detected)]
    for (met in c("BUS","BAN","PMC")) {
        for (mod in c("PER","FAT","FIT")) {
            wem <- grep(paste0(met,"_",mod), names(pppppp), value = T)
            unifid[[paste0(met,"_",mod)]] <- rowMeans(pppppp[, ..wem])
        }
    }

    plot(unifid$Date, unifid$PMC_PER,"l", col = 6, ylim = c(0,100))
    par(new = T)
    plot(unifid$Date, unifid$PMC_FAT,"l", col = 3, ylim = c(0,100))
    par(new = T)
    plot(unifid$Date, unifid$PMC_FIT,"l", col = 5, ylim = c(0,100))
    abline(v = Sys.Date(), col = "green", lty = 2)
    title("PMC all metrics")
    axis(1, at = pp[wday(Date) == 2, Date ], labels = F, col = "black", col.ticks = "black")
    axis(1, at = pp[mday(Date) == 1, Date ], labels = format(pp[mday(Date) == 1, Date ], "%b"), col = "black", col.ticks = "black", lwd.ticks = 3)

    plot(unifid$Date, unifid$BAN_PER,"l", col = 6, ylim = c(0,100))
    par(new = T)
    plot(unifid$Date, unifid$BAN_FAT,"l", col = 3, ylim = c(0,100))
    par(new = T)
    plot(unifid$Date, unifid$BAN_FIT,"l", col = 5, ylim = c(0,100))
    abline(v = Sys.Date(), col = "green", lty = 2)
    title("Banister all metrics")
    axis(1, at = pp[wday(Date) == 2, Date ], labels = F, col = "black", col.ticks = "black")
    axis(1, at = pp[mday(Date) == 1, Date ], labels = format(pp[mday(Date) == 1, Date ], "%b"), col = "black", col.ticks = "black", lwd.ticks = 3)

    plot(unifid$Date, unifid$BUS_PER,"l", col = 6, ylim = c(0,100))
    par(new = T)
    plot(unifid$Date, unifid$BUS_FAT,"l", col = 3, ylim = c(0,100))
    par(new = T)
    plot(unifid$Date, unifid$BUS_FIT,"l", col = 5, ylim = c(0,100))
    abline(v = Sys.Date(), col = "green", lty = 2)
    title("Busson all metrics")
    axis(1, at = pp[wday(Date) == 2, Date ], labels = F, col = "black", col.ticks = "black")
    axis(1, at = pp[mday(Date) == 1, Date ], labels = format(pp[mday(Date) == 1, Date ], "%b"), col = "black", col.ticks = "black", lwd.ticks = 3)

}







##TODO Yearly

capture.output({
    metrics <- metrics[as.Date(Date) > Sys.Date() - 400, ]
    weekly  <- metrics[, .(TRIMP_Points       = round(sum(Trimp_Points,       na.rm = TRUE)),
                           TRIMP_Zonal_Points = round(sum(Trimp_Zonal_Points, na.rm = TRUE)),
                           EPOC               = round(sum(EPOC,               na.rm = TRUE)),
                           Load_2             = round(sum(Load_2,             na.rm = TRUE)),
                           TrimpModWeighed    = round(sum(TrimpModWeighed,    na.rm = TRUE)),
                           Total_Distance     = round(sum(Total_Distance,     na.rm = TRUE)),
                           Calories           = round(sum(Total_Kcalories,    na.rm = TRUE))),
                       by = .(Year = year(Date), Week = isoweek(Date) )]
    weekly[ , Date := as.Date(paste(Year, Week, 1, sep="-"), "%Y-%U-%u") ]
    setorder(weekly, Date)

    monthly <- metrics[, .(TRIMP_Points       = round(sum(Trimp_Points,       na.rm = TRUE)),
                           TRIMP_Zonal_Points = round(sum(Trimp_Zonal_Points, na.rm = TRUE)),
                           EPOC               = round(sum(EPOC,               na.rm = TRUE)),
                           Load_2             = round(sum(Load_2,             na.rm = TRUE)),
                           TrimpModWeighed    = round(sum(TrimpModWeighed,    na.rm = TRUE)),
                           Total_Distance     = round(sum(Total_Distance,     na.rm = TRUE)),
                           Calories           = round(sum(Total_Kcalories,    na.rm = TRUE))),
                       by = .(Year = year(Date), month = month(Date))]
    monthly[ , Date := as.Date(paste(Year, month, 1, sep="-"), "%Y-%m-%d") ]
    setorder(monthly, Date)

    cat("\n\n## WEEKLY SUMS\n\n")
    panderOptions("table.split.table", 200)
    panderOptions("table.style", "simple")
    pander(weekly)
    pander(weekly[1,])
    # cat(paste( names(weekly), collapse = "\t" ), "\n" )

    cat("\n\n## MONTHLY SUMS\n\n")
    pander(monthly)
    pander(monthly[1,])
    # cat(paste(  names(montly), collapse = "\t" ), "\n" )

}, file = loadtables)



par("mar" = c(3,2,2,1), xpd = FALSE)
weekly <- tail(weekly,10)
ylim   <- range(0, weekly$TRIMP_Points, weekly$TRIMP_Zonal_Points, weekly$EPOC,
                weekly$Load_2, weekly$TrimpModWeighed/100,
                weekly$Calories/1000, na.rm = T)
plot( weekly$Date,  weekly$TRIMP_Points, "l",   lwd = 2, col = 4, ylim = ylim)
lines(weekly$Date,  weekly$TRIMP_Zonal_Points,  lwd = 2, col = 3 )
lines(weekly$Date,  weekly$EPOC,                lwd = 2, col = 2 )
lines(weekly$Date,  weekly$Load_2,              lwd = 2, col = 5 )
lines(weekly$Date,  weekly$TrimpModWeighed/100, lwd = 2, col = 7 )


lines(weekly$Date,  weekly$Calories/10,        lwd = 2, col = 6 )
# abline(v = Sys.Date(), lty = 2, col = "green")

legend("topleft", bty = "n", lty = 1, lwd = 2, cex = .8,
       legend = c("TRIMP", "TRIMP Zoned", "EPOC", "Load_2", "TrimpModWeighed/100", "Calories/10"),
       col    = c(      4,             3,      2,        5,                     7,     6))


if (!interactive()) dev.off()



capture.output({
    wecare <- names(metrics)
    wecare <- grep("Average_Heart_Rate", wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Average_Temp",       wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Change_History",     wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Device",             wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Elevation_Gain",     wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Equipment_Weight",   wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Feel",               wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("File_Format",        wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Filename",           wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("GPS_errors",         wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Left_Right",         wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Month",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Notes",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Spike_Time",         wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("SubSport",           wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("RPE",                wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Swim",               wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Temperature",        wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("W_bal",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Year",               wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^Best",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^Bike",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^HI",                wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^H[0-9]",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^LI",                wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^L[0-9]",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^PI",                wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^P[0-9]",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^Pch|^Col",          wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^Spikes",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^W[0-9]",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^X[0-9]",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("^pN",                wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("_Carrying",          wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("xPower",             wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("aPower",             wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("aBike",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("parsed",             wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("critical",           wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("peak",               wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("time_in",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("in_zone",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("dropout",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("present",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("overrides",          wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Calendar_Text",      wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Weekday",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("Calories",           wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("_temp",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("pace_row",           wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("_V2$",               wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("_V3$",               wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("compatibility_",     wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("shoes",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("daniels",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
    wecare <- grep("govss",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)


    export <- metrics[, ..wecare]
    export <- rm.cols.dups.DT(export)
    export <- rm.cols.NA.DT(export)
    names(export)

    cat("\n\n## Activities\n\n")
    panderOptions("table.split.table", 2000)
    panderOptions("table.style", "simple")
    pander(export)
    pander(export[1,])

}, file = lastactivit)



#### For mobile png 720 x 1520  ------------------------------------------------
days <- 100

## limit graph to last days
pppppp <- gather[ Date >= max(Date) - days - extend, ]
pppppp <- pppppp[ Date <= Sys.Date() + 10 ]
pppppp <- data.table(pppppp)
models <- c("PMC", "BAN", "BUS")

## each day plot
shortn <- c(        "TP",         "TZ",         "EP")
wwca   <- c("EP.BAN_VAL", "TZ.BAN_VAL", "TP.BAN_VAL")
ylim   <- range(pppppp[ , ..wwca ], na.rm = T)

## normalize data
wecare <- grep("Date|VO2max", names(pppppp), invert = T, value = T)
for (ac in wecare) {
    pppppp[[ac]] <- 100 * scale(x      = pppppp[[ac]],
                                center = min(pppppp[[ac]]),
                                scale  = diff(range(pppppp[[ac]])))
}

wecc <- grep( "^RP" ,names(pppppp), invert = T, value = T)
pppppp <- pppppp[, ..wecc ]


for (va in shortn) {

    png(paste0("/home/athan/LOGs/training_status/", va, ".png"), width = 720, height = 1520, units = "px", bg = "transparent")

    layout(matrix(c(5,1,1,1,1,2,2,2,2,3,3,3,3,4,4), 15, 1, byrow = TRUE))
    # layout.show(4)

    for (mo in models) {
        wp <- c(grep(paste0(va,".",mo), names(pppppp), value = TRUE),
                "Date", "VO2max_Detected")
        pp <- pppppp[, ..wp]
        ## easy names
        vfit <- grep("FIT",wp,value = T)
        vfat <- grep("FAT",wp,value = T)
        vper <- grep("PER",wp,value = T)
        vval <- grep("VAL",wp,value = T)

        #### Training Impulse model plot ####
        par("mar" = c(2,0,1,0),
            xpd = FALSE,
            col      = "grey",
            col.axis = "grey",
            col.lab  = "grey",
            yaxt     = "n")

        pp[[vval]][pp[[vval]] == 0] <- NA
        plot(pp$Date, pp[[vval]]/4, ylim = range(0, pp[[vval]], na.rm = T), type = "h", bty = "n", lwd = 4, col = "#959595" )
        pp[[vval]][is.na(pp[[vval]])] <- 0
        lines(pp$Date, caTools::runmean(pp[[vval]], k = 9, align = "right")/2, col = "#959595", lwd = 2)
        box(col="white")
        par(new = T)
        ylim <-range( 45,53, pp$VO2max_Detected, na.rm = T)
        plot( pp$Date, pp$VO2max_Detected, ylim = ylim, col = "pink", pch = "-", cex = 4 )
        box(col="white")
        par(new = T)
        ylim    <- range(pp[[vfit]], pp[[vfat]], pp[[vper]], na.rm = T)
        ylim[2] <- ylim[2] * 1.09
        plot(pp$Date, pp[[vfat]], col = 3, lwd = 2, "l", yaxt = "n", ylim = ylim)
        abline(v=Sys.Date(),col="green",lty=2)
        box(col="white")
        par(new = T)
        plot(pp$Date, pp[[vfit]], col = 5, lwd = 4, "l", yaxt = "n", ylim = ylim)
        box(col="white")
        par(new = T)
        plot(pp$Date, pp[[vper]], col = 6, lwd = 4, "l", yaxt = "n", ylim = ylim)

        # legend("top", bty = "n", ncol = 3, lty = 1, inset = c(0, -0.01),
        #        cex = 0.7, text.col = "grey",
        #        legend = c("Fatigue", "Fitness","Performance"),
        #        col    = c(    3 ,     5 ,    6 ) )

        legend("topleft", bty = "n", title = paste(va, mo, best$Date), legend = c(""), cex = 4)

        prediction <- pp[ Date > last$Date, ]
        best       <- prediction[ which.max(prediction[[vper]]) ]
        abline(v = best$Date,    col = "yellow", lty = 2, lwd = 2)
        abline(h = best[[vper]], col = "yellow", lty = 2, lwd = 2)

        abline(h = pp[[vper]][ pp$Date == Sys.Date() ], col = 6, lty = 2, lwd = 2)
        text(pp[ which.max(pp[[vper]]), Date ], pp[[vper]][which.max(pp[[vper]])],
             labels = round(pp[[vper]][which.max(pp[[vper]])]), col = 6, pos = 3, cex = 2 )
        text(Sys.Date(), pp[[vper]][pp$Date == Sys.Date()],
             labels = round(pp[[vper]][pp$Date == Sys.Date()]), col = 6, pos = 4, cex = 2 )

        abline(h = pp[[vfit]][ pp$Date == Sys.Date() ], col = 5, lty = 2, lwd = 2)
        text(pp[ which.max(pp[[vfit]]), Date ], pp[[vfit]][which.max(pp[[vfit]])],
             labels = round(pp[[vfit]][which.max(pp[[vfit]])]), col = 5, pos = 3, cex = 2 )
        text(Sys.Date(), pp[[vfit]][pp$Date == Sys.Date()],
             labels = round(pp[[vfit]][pp$Date == Sys.Date()]), col = 5, pos = 4, cex = 2 )

        # abline(h = pp[[vfat]][ pp$Date == Sys.Date() ], col = 3, lty = 2)
        text(pp[ which.max(pp[[vfat]]), Date ], pp[[vfat]][which.max(pp[[vfat]])],
             labels = round(pp[[vfat]][which.max(pp[[vfat]])]), col = 3, pos = 3, cex = 2 )
        text(Sys.Date(), pp[[vfat]][pp$Date == Sys.Date()],
             labels = round(pp[[vfat]][pp$Date == Sys.Date()]), col = 3, pos = 4, cex = 2 )

        axis(1, at = pp[wday(Date) == 2, Date ], labels = F, col = "grey", col.ticks = "grey")
        axis(1, at = pp[mday(Date) == 1, Date ], labels = format(pp[mday(Date) == 1, Date ], "%b"), col = "grey", col.ticks = "grey", lwd.ticks = 3)

    }
    dev.off()
}



Rmk_store_dependencies()


####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
