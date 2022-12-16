#!/usr/bin/env Rscript

#### Golden Cheetah get activities from a running instance of GC

rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()

library(data.table)
library(cycleRtools)
source("~/CODE/FUNCTIONS/R/data.R")

nactivities <- length(list.files(path    = "~/TRAIN/GoldenCheetah/Athan/activities/",
                                 pattern =  "*.json"))

GCget_Metrics <- GC_metrics("Athan")

sort(names(GCget_Metrics))

## no data while buffering

if (nrow(GCget_Metrics) < nactivities) {
    stop("No data send by GoldenCheetach")
}

GCget_Metrics <- data.table(GCget_Metrics)



GCget_Metrics <- rm.cols.NA.DT(GCget_Metrics)
GCget_Metrics <- rm.cols.dups.DT(GCget_Metrics)


names(GCget_Metrics)




####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
