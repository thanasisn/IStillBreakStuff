#!/usr/bin/env Rscript

#### Golden Cheetah read activities summary directly


###TODO explore this tools
# library(cycleRtools)
# GC_activity("Athan",activity = "~/TRAIN/GoldenCheetah/Athan/activities/2008_12_19_16_00_00.json")
# GC_activity("Athan")
# GC_metrics("Athan")
# read_ride(file = af)



####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()
if(!interactive()) {
    pdf(file=sub("\\.R$",".pdf",Script.Name))
    sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)
}

library(data.table)
library(jsonlite)
source("~/CODE/FUNCTIONS/R/data.R")


####  Load Goldencheetah exports  ####
metrics <- readRDS("~/LOGs/GCmetrics.Rds")
metrics <- data.table(metrics)
metrics <- rm.cols.dups.DT(metrics)
metrics <- rm.cols.NA.DT(metrics)


####  Read data from json files  ####
files <- list.files("~/TRAIN/GoldenCheetah/Athan/activities/",
                    pattern = "*.json",
                    full.names = TRUE)

files <- sort(files)
# files <- tail(files,10)

gather <- data.table()

for (af in files) {
    ## get file
    ride <- fromJSON(af)
    ride <- ride$RIDE

    stopifnot(
        all(names(ride) %in%
                c("STARTTIME", "RECINTSECS", "DEVICETYPE", "IDENTIFIER", "TAGS","INTERVALS", "SAMPLES", "XDATA"))
    )

    temp <- data.frame(
        file       = af,
        filemtime  = file.mtime(af),
        time       = ride$STARTTIME,
        RECINTSECS = ride$RECINTSECS,
        DEVICETYPE = ride$DEVICETYPE,
        IDENTIFIER = ride$IDENTIFIER,
        data.frame(ride$TAGS)
    )

    gather <- rbind(gather, temp, fill = T)
}

gather[, time := as.POSIXct(time) ]


tess <- merge(gather,metrics, by = "time")









####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
