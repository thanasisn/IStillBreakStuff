#!/usr/bin/env Rscript

#### Golden Cheetah plots
## This is incorporated to conky


####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()

inputdata  <- "~/LOGs/GCmetrics.Rds"
moredata   <- "~/DATA/Other/GC_json_data.Rds"
outputpdf  <- paste0("~/LOGs/car_logs/",  basename(sub("\\.R$",".pdf", Script.Name)))
datascript <- "~/CODE/training_analysis/GC_read_activities.R"
daysback   <- 1500


if(!interactive()) {
    ## check if we have to run
    if (!file.exists(outputpdf) |
        file.mtime(inputdata) > file.mtime(outputpdf) |
        file.mtime(outputpdf) < Sys.time() - 12 * 3600 ) {
        cat(paste("will run"))
    } else {stop("Don't have to run")}
    pdf(outputpdf, width = 9, height = 5)
}


library(data.table)
# library(scales)
source("~/FUNCTIONS/R/data.R")

## run other data gather
source(datascript)



## load outside Goldencheetah
metrics <- readRDS(inputdata)
metrics <- data.table(metrics)
## get this from direct read
metrics[ , VO2max_detected := NULL ]
## drop zeros on some columns
wecare <- c(
    "Aerobic.Training.Effect",
    "Anaerobic.Training.Effect",
    "Average.Heart.Rate",
    "Average.Speed",
    "CP",
    "Calories",
    "Daniels.Points",
    "Distance",
    "Duration",
    "Equipment.Weight",
    "OVRD_time_riding",
    "OVRD_total_distance",
    "RPE",
    "Recovery.Time",
    "Time.Moving",
    "V02max.detected",
    "V02max_detected",
    "VO2max.detected",
    "VO2max_detected",
    "Work",
    NULL)
wecare <- names(metrics)[names(metrics)%in%wecare]
for (avar in wecare) {
    metrics[[avar]][metrics[[avar]] == 0] <- NA
}
metrics <- rm.cols.dups.DT(metrics)
metrics <- rm.cols.NA.DT(metrics)
metrics[, Notes := NULL]
metrics[, color := NULL]
metrics[, Data  := NULL]




## covert types
for (avar in names(metrics)) {
    if (is.character(metrics[[avar]])) {
        ## find empty and replace
        metrics[[avar]] <- sub("^[ ]*$",       NA, metrics[[avar]])
        metrics[[avar]] <- sub("^[ ]*NA[ ]*$", NA, metrics[[avar]])
        if (!all(is.na((as.numeric(metrics[[avar]]))))) {
            metrics[[avar]] <- as.numeric(metrics[[avar]])
        }
    }
}


gather  <- readRDS(moredata)
gather[, Data  := NULL ]
gather[, color := NULL ]
gather[, Year  := NULL ]


## limit data back
metrics <- metrics[ date > Sys.Date() - daysback,]
gather  <- gather[  time > Sys.time() - daysback*24*3600,]

metrics <- rm.cols.dups.DT(metrics)
metrics <- rm.cols.NA.DT(metrics)
gather  <- rm.cols.dups.DT(gather)
gather  <- rm.cols.NA.DT(gather)

##FIXME
tocheck <- grep("time",intersect(names(gather),names(metrics)),invert = T,ignore.case = T, value = T)
metrics <- unique(merge(gather,metrics,by = "time"))

for (avar in tocheck) {
    getit <- grep(paste0(avar,"\\.[xy]"),names(metrics), value = T)
    # hist(metrics[[getit[1]]])
    # hist(metrics[[getit[2]]])
    if (all(metrics[[getit[1]]] == metrics[[getit[2]]])) {
        metrics[[getit[2]]] <- NULL
        names(metrics)[names(metrics) == getit[1]] <- avar
    }
}


tessss  <- grep("Calories",names(metrics), value = T)
metrics[, ..tessss ]


hist(metrics$Calories.x, breaks = 100)

metrics[ !is.na(Calories.x), ..tessss ]
metrics[ !is.na(Calories.x),  ]


setorder(metrics,date)



wecare <- names(metrics)
wecare <- grep("date|notes|time|sport|workout_code|_Fatigue|bike|shoes|workout_title|device|Calendar_text|Elevation_Gain_Carrying|heartbeats|Max_Core_Temperature|Checksum|Right_Balance|Percent_in_Zone|Percent_in_Pace_Zone|Best_|Distance_Swim|Equipment_Weight|Average_Core_Temperature|Average_Temp|Max_Cadence|Max_Temp|min_Peak_Pace|_Peak_Pace|_Peak_Pace_HR|_Peak_Power|_Peak_Power_HR|min_Peak_Hr|_Peak_WPK|Min_temp|Average_Cadence|Average_Running_Cadence|Max_Running_Cadence",
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
wecare <- c("TRIMP_Points","TRIMP_Zonal_Points","EPOC","TriScore","Aerobic_TISS")
## work, calories
extend <- 30
pdays  <- c(400, 100)

# fitness = 0;
# for(i=0, i < count(TRIMP); i++)
# {
#     fitness = fitness * exp(-1/r1) + TRIMP[i];
#     fatigue = fatigue * exp(-1/r2) + TRIMP[i];
#     performance = fitness * k1 - fatigue * k2;
# }
# k1=1.0, k2=1.8-2.0, r1=49-50, r2=11.
banister <- function(fitness, fatigue, trimp, k1 = 1.0, k2 = 1.8, r1 = 49, r2 = 11) {
    fitness     <- fitness * exp(-1/r1) + trimp
    fatigue     <- fatigue * exp(-1/r2) + trimp
    performance <- fitness * k1 - fatigue * k2

    list(fitness     = fitness,
         fatigue     = fatigue,
         performance = performance)
}

busso <- function(fitness, fatigue, trimp, par2 , k1 = 0.031, k3 = 0.000035, r1 = 30.8, r2 = 16.8, r3 = 2.3) {
    fitness     <- fitness * exp(-1/r1) + trimp
    fatigue     <- fatigue * exp(-1/r2) + trimp
    par2        <- fatigue * exp(-1/r3) + par2
    k2          <- k3      * par2
    performance <- fitness * k1 - fatigue * k2

    list(fitness     = fitness,
         fatigue     = fatigue,
         performance = performance,
         par2        = par2)
}

for (days in pdays) {
    for (avar in wecare) {


        pp <- data.table(time  = metrics$time,
                         value = metrics[[avar]] )
        pp <- pp[, .(value = sum(value)), by = .(date=as.Date(time))]
        last <- pp[ date == max(date),]
        pp <- merge(
            data.table(date = seq.Date(from = min(pp$date), to = max(pp$date)+extend, by = "day")),
            pp, all = T)
        pp[is.na(value),value:=0]

        pp <- pp[ date >= max(date)-days, ]

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
            pp$ATL1[nr] = fATL1 * pp$value[nr] + (1-fATL1) * pp$ATL1[nr-1]
            pp$ATL2[nr] = fATL2 * pp$value[nr] + (1-fATL2) * pp$ATL2[nr-1]
            pp$CTL1[nr] = fCTL1 * pp$value[nr] + (1-fCTL1) * pp$CTL1[nr-1]
            pp$CTL2[nr] = fCTL2 * pp$value[nr] + (1-fCTL2) * pp$CTL2[nr-1]
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

        #### Training Impulse model plot ####
        par("mar" = c(2,0,3,0), xpd = TRUE)

        plot(pp$date, pp$ATL2, col = 3, lwd = 1.1, "l", yaxt="n")
        abline(v=Sys.Date(),col="green",lty=2)
        par(new = T)
        plot(pp$date, pp$CTL2, col = 5, lwd = 1.1, "l", yaxt="n")
        par(new = T)
        plot(pp$date, pp$TSB2, col = 6, lwd =   2, "l", yaxt="n")

        legend("top",bty = "n",ncol = 3,lty=1, inset=c(0,-0.05), cex = 0.7,
               legend = c("ATL2", "CTL2","TSB2"),
               col    = c(    3 ,     5 ,    6 ) )

        prediction <- pp[ date > last$date, ]
        best       <- prediction[which.max(TSB2)]
        abline(v=best$date, col = "yellow",lty=2)
        abline(h=best$TSB2, col = "yellow",lty=2)
        title(paste(days,"days", avar,"best:", best$date),line = 2)



        #### Banister model plot ####
        par("mar" = c(2,0,3,0), xpd = TRUE)

        plot( pp$date, pp$ban.fatigue, lwd = 1.1, "l", col = 3, yaxt="n")
        par(new = T)
        plot( pp$date, pp$ban.fitness, lwd = 1.1, "l", col = 5, yaxt="n")
        par(new = T)
        plot( pp$date, pp$ban.perform, lwd =   2, "l", col = 6, yaxt="n")

        legend("top",bty = "n",ncol = 3,lty=1, inset=c(0,-0.05), cex = 0.7,
               legend = c("Fatigue","Fitness","Performance"),
               col    = c(       3 ,       5 ,           6 ) )
        abline(v=Sys.Date(),col="green",lty=2)

        prediction <- pp[ date > last$date, ]
        best       <- prediction[which.max(ban.perform)]
        abline(v=best$date, col = "yellow",lty=2)
        abline(h=best$ban.perform, col = "yellow",lty=2)
        title(paste("Banister",days,"days", avar,"best:", best$date),line = 2)

        #### Busson model plot ####
        par("mar" = c(2,0,3,0), xpd = TRUE)

        plot( pp$date, pp$bus.fatigue, lwd = 1.1, "l", col = 3, yaxt="n")
        par(new = T)
        plot( pp$date, pp$bus.fitness, lwd = 1.1, "l", col = 5, yaxt="n")
        par(new = T)
        plot( pp$date, pp$bus.perform, lwd =   2, "l", col = 6, yaxt="n")
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

        pp <- data.table(time  = metrics$time,
                         value = metrics[[avar]] )
        pp <- pp[, .(value = sum(value)), by = .(date=as.Date(time))]
        last <- pp[ date == max(date),]
        pp <- merge(
            data.table(date = seq.Date(from = min(pp$date), to = max(pp$date)+extend, by = "day")),
            pp, all = T)
        pp[is.na(value),value:=0]

        pp <- pp[ date >= max(date)-days, ]

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
            pp$ATL1[nr] = fATL1 * pp$value[nr] + (1-fATL1) * pp$ATL1[nr-1]
            pp$ATL2[nr] = fATL2 * pp$value[nr] + (1-fATL2) * pp$ATL2[nr-1]
            pp$CTL1[nr] = fCTL1 * pp$value[nr] + (1-fCTL1) * pp$CTL1[nr-1]
            pp$CTL2[nr] = fCTL2 * pp$value[nr] + (1-fCTL2) * pp$CTL2[nr-1]
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

        #### Training Impulse model plot ####
        png(paste0("/dev/shm/CONKY/trimp_",avar,"_",days,".png"), width = 470, height = 200, units = "px", bg = "transparent")

        par("mar" = c(2,0,0,0), col = "white",
            col.axis = "white",
            col.lab  = "white")

        plot(pp$date, pp$ATL2, col = 3, lwd = 1.5, "l", yaxt="n")
        box(col="white")
        abline(v=Sys.Date(),col="green",lty=2)
        par(new = T)
        plot(pp$date, pp$CTL2, col = 5, lwd = 1.5, "l", yaxt="n")
        box(col="white")
        par(new = T)
        plot(pp$date, pp$TSB2, col = 6, lwd =   3, "l", yaxt="n")
        box(col="white")

        legend("top",bty = "n",ncol = 3,lty=1, inset=c(0,-0.05), cex = 0.7,
               legend = c("ATL2", "CTL2","TSB2"),
               col    = c(    3 ,     5 ,    6 ) )

        prediction <- pp[ date > last$date, ]
        best       <- prediction[which.max(TSB2)]
        abline(v=best$date, col = "yellow",lty=2)
        abline(h=best$TSB2, col = "yellow",lty=2)

        legend("topleft",bty = "n",title = paste(avar, best$date),legend = c(""))

        dev.off()




        #### Banister model plot ####
        png(paste0("/dev/shm/CONKY/banister_",avar,"_",days,".png"), width = 470, height = 200, units = "px", bg = "transparent")

        par("mar" = c(2,0,0,0), col = "white",
            col.axis = "white",
            col.lab  = "white")

        plot( pp$date, pp$ban.fatigue, lwd = 1.1, "l", col = 3, yaxt="n")
        box(col="white")
        par(new = T)
        plot( pp$date, pp$ban.fitness, lwd = 1.1, "l", col = 5, yaxt="n")
        box(col="white")
        par(new = T)
        plot( pp$date, pp$ban.perform, lwd =   2, "l", col = 6, yaxt="n")
        box(col="white")

        legend("top",bty = "n",ncol = 3,lty=1, inset=c(0,-0.05), cex = 0.7,
               legend = c("Fatigue","Fitness","Performance"),
               col    = c(       3 ,       5 ,           6 ) )
        abline(v=Sys.Date(),col="green",lty=2)

        prediction <- pp[ date > last$date, ]
        best       <- prediction[which.max(ban.perform)]
        abline(v=best$date, col = "yellow",lty=2)
        abline(h=best$ban.perform, col = "yellow",lty=2)

        legend("topleft",bty = "n",title = paste(avar, best$date),legend = c(""))

        dev.off()



        #### Busson model plot ####
        png(paste0("/dev/shm/CONKY/busson_",avar,"_",days,".png"), width = 470, height = 200, units = "px", bg = "transparent")

        par("mar" = c(2,0,0,0), col = "white",
            col.axis = "white",
            col.lab  = "white")

        plot( pp$date, pp$bus.fatigue, lwd = 1.1, "l", col = 3, yaxt="n")
        box(col="white")
        par(new = T)
        plot( pp$date, pp$bus.fitness, lwd = 1.1, "l", col = 5, yaxt="n")
        box(col="white")
        par(new = T)
        plot( pp$date, pp$bus.perform, lwd =   2, "l", col = 6, yaxt="n")
        box(col="white")

        legend("top",bty = "n",ncol = 3,lty=1, inset=c(0,-0.05), cex = 0.7,
               legend = c("Fatigue","Fitness","Performance"),
               col    = c(       3 ,       5 ,           6 ) )
        abline(v=Sys.Date(),col="green",lty=2)

        prediction <- pp[ date > last$date, ]
        best       <- prediction[which.max(bus.perform)]
        abline(v=best$date, col = "yellow",lty=2)
        abline(h=best$bus.perform, col = "yellow",lty=2)

        legend("topleft",bty = "n",title = paste(avar, best$date),legend = c(""))

        dev.off()
    }
}


pp <- metrics[,VO2max.detected,time]






####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
