#!/usr/bin/env Rscript

#### Golden Cheetah read activities summary directly
## This is sourced by other files


###TODO explore this tools
# library(cycleRtools)
# GC_activity("Athan",activity = "~/TRAIN/GoldenCheetah/Athan/activities/2008_12_19_16_00_00.json")
# GC_activity("Athan")
# GC_metrics("Athan")
# read_ride(file = af)


####_ Set environment _####
# Sys.setenv(TZ = "UTC")
# Script.Name = funr::sys.script()


library(myRtools)
library(data.table)
library(jsonlite)
source("~/CODE/FUNCTIONS/R/data.R")


## data paths
storagefl <- "~/DATA/Other/GC_json_data.Rds"
gcfolder  <- "~/TRAIN/GoldenCheetah/Athan/activities/"



####  Read data from json files  ####
file       <- list.files( path       = gcfolder,
                          pattern    = "*.json",
                          full.names = TRUE)
filesmtime <- file.mtime(file)
check      <- data.table(file, filesmtime)

## start with read data
if (file.exists(storagefl)) {
    gather <- readRDS(storagefl)
    ## find files to read
    test  <- gather[, file, filemtime]
    test2 <- merge(test, check , by = "file", all = T)
    files <- test2[ filemtime != filesmtime | is.na(filemtime) , file ]
    ## drop preexisting files
    gather <- gather[ ! file %in% files ]
} else {
    gather <- data.table()
    files  <- check$file
}


####  Parse chosen files  ####
if (length(files)!=0) {
    cat(paste("\nSomething to do\n"))
    ## read files
    for (af in files) {
        ## get file
        ride <- fromJSON(af)
        ride <- ride$RIDE
        cat(paste(basename(af)),"\n")

        stopifnot(
            all(names(ride) %in%
                    c("STARTTIME",
                      "OVERRIDES",
                      "RECINTSECS",
                      "DEVICETYPE",
                      "IDENTIFIER",
                      "TAGS",
                      "SAMPLES",
                      "XDATA",
                      "INTERVALS"))
        )

        temp <- data.frame(
            file       = af,
            filemtime  = file.mtime(af),
            time       = as.POSIXct(ride$STARTTIME),
            RECINTSECS = ride$RECINTSECS,
            DEVICETYPE = ride$DEVICETYPE,
            IDENTIFIER = ride$IDENTIFIER,
            data.frame(ride$TAGS)
        )

        if (!is.null( ride$OVERRIDES )) {
            ss        <- data.frame(t(diag(as.matrix(ride$OVERRIDES))))
            names(ss) <- paste0("OVRD_", names(ride$OVERRIDES))
            temp      <- cbind(temp,ss)
            rm(ss)
        }

        ## covert type
        for (avar in names(temp)) {
            if (is.character(temp[[avar]])) {
                ## find empty and replace
                temp[[avar]] <- sub("[ ]*$",        "", temp[[avar]])
                temp[[avar]] <- sub("^[ ]*",        "", temp[[avar]])
                temp[[avar]] <- sub("^[ ]*$",       NA, temp[[avar]])
                temp[[avar]] <- sub("^[ ]*NA[ ]*$", NA, temp[[avar]])
                if (!all(is.na((as.numeric(temp[[avar]]))))) {
                    temp[[avar]] <- as.numeric(temp[[avar]])
                }
            }
        }

        gather <- rbind(gather, temp, fill = T)
        rm(temp)
    }

    gather <- rm.cols.dups.DT(gather)
    gather <- rm.cols.NA.DT(gather)
    ## for testing
    for (avar in names(gather)) {
        if (is.numeric(gather[[avar]])) {
            hist(gather[[avar]], breaks = 50, main = avar )
        }
    }

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
    wecare <- names(gather)[names(gather)%in%wecare]
    for (avar in wecare) {
        gather[[avar]][gather[[avar]] == 0] <- NA
    }

    gather <- rm.cols.dups.DT(gather)
    gather <- rm.cols.NA.DT(gather)

    gather <- unique(gather)

    ## write data
    write_RDS(gather, storagefl)

} else {
    cat(paste("\nNothing to do\n"))
}


####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
