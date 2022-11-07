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
inputdata <- "~/LOGs/GCmetrics.Rds"

## we may read the actual GC database sameday?

####  Read data from json activities files  ####################################
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
if (length(files) != 0) {
    cat(paste("\nNew activities to parse\n"))
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

        ## convert types
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
        "RECINTSECS",
        "RPE",
        "Recovery.Time",
        "Time.Moving",
        "V02max.detected",
        "V02max_detected",
        "VO2max.detected",
        "VO2max_detected",
        "Work",
        "cc",
        "xPower",
        NULL)
    wecare <- names(gather)[names(gather)%in%wecare]
    for (avar in wecare) {
        gather[[avar]][gather[[avar]] == 0] <- NA
    }

    ## drop columns with zero or NA only
    for (avar in names(gather)) {
        if (all(gather[[avar]] %in% c(NA, 0))) {
            gather[[avar]] <- NULL
        }
    }
    gather[, Year := NULL ]
    gather[, Data  := NULL]
    gather[, color := NULL]

    gather <- rm.cols.dups.DT(gather)
    gather <- rm.cols.NA.DT(gather)
    gather <- unique(gather)
    setorder(gather,time)

    ## write data
    write_RDS(gather, storagefl)
} else {
    cat(paste("\nNo new activities\n"))
}


####  Read data from GC exports  ###############################################

## load outside Goldencheetah
metrics <- readRDS(inputdata)
metrics <- data.frame(metrics)
setorder(metrics,time)
## get this from direct read

## covert types
for (avar in names(metrics)) {
    if (is.character(metrics[[avar]])) {
        ## find empty and replace
        metrics[[avar]] <- sub("[ ]*$",        "", metrics[[avar]])
        metrics[[avar]] <- sub("^[ ]*",        "", metrics[[avar]])
        metrics[[avar]] <- sub("^[ ]*$",       NA, metrics[[avar]])
        metrics[[avar]] <- sub("^[ ]*NA[ ]*$", NA, metrics[[avar]])
        if (!all(is.na((as.numeric(metrics[[avar]]))))) {
            metrics[[avar]] <- as.numeric(metrics[[avar]])
        }
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
    "RECINTSECS",
    "RPE",
    "Recovery.Time",
    "Time.Moving",
    "V02max.detected",
    "V02max_detected",
    "VO2max.detected",
    "VO2max_detected",
    "Work",
    "cc",
    "xPower",
    NULL)
wecare <- names(metrics)[names(metrics) %in% wecare]
for (avar in wecare) {
    metrics[[avar]][metrics[[avar]] == 0] <- NA
}
metrics <- data.table(metrics)
metrics[, Notes := NULL]
metrics[, color := NULL]
metrics[, Data  := NULL]
metrics <- rm.cols.dups.DT(metrics)
metrics <- rm.cols.NA.DT(metrics)







### homogenize data


## find duplicate names to check
setorder(gather,  time)
setorder(metrics, time)
tocheck <- grep("time",
                intersect(names(gather), names(metrics)),
                invert = TRUE, ignore.case = TRUE, value = TRUE)

for (avar in tocheck) {
    if (all(metrics[[avar]] == gather[[avar]], na.rm = TRUE)) {
        metrics[[avar]] <- NULL
    }
}


## gather$Calories has old problematic replacement values probably
# ee <- data.frame(metrics$Calories, gather$Calories)
# gather[!is.na(gather$Calories),time,Calories]
gather$Calories <- NULL

## we don't need that
# gather[ Device == "unknown", Device := NA ]
# ee <- data.frame(metrics$Device, gather$Device)
gather$Device  <- NULL
metrics$Device <- NULL






stop()
metrics <- unique(merge(gather, metrics, by = "time"))

## duplicate name columns check

for (avar in tocheck) {
    getit <- grep(paste0(avar, "\\.[xy]"), names(metrics), value = TRUE)
    if (all(metrics[[getit[1]]] == metrics[[getit[2]]], na.rm = TRUE)) {
        metrics[[getit[2]]] <- NULL
        names(metrics)[names(metrics) == getit[1]] <- avar
    }
}
metrics <- rm.cols.dups.DT(metrics)
metrics <- rm.cols.NA.DT(metrics)

## drop columns with zero or NA only
for (avar in names(metrics)) {
    if (all(metrics[[avar]] %in% c(NA, 0))) {
        metrics[[avar]] <- NULL
    }
}



## get duplicate columns
dup.vec <- which(duplicated(t(metrics)))
dup.vec <- names(metrics)[dup.vec]

# create a vector with the checksum for each column (and keep the column names as row names)
col.checksums <- sapply(metrics, function(x) digest::digest(x, "md5"), USE.NAMES = T)
dup.cols      <- data.table(col.name = names(col.checksums), hash.value = col.checksums)
dup.cols      <- dup.cols[dup.cols, on = "hash.value"][col.name != i.col.name,]

##TODO
## remove manual
metrics[, DEVICETYPE        := NULL]
metrics[, Device.Info       := NULL]
metrics[, VO2max.detected   := NULL]
metrics[, Workout.Title     := NULL]
metrics[, X1_sec_Peak_Power := NULL]
metrics[, NP                := NULL]
metrics[, IF                := NULL]




####_ END _####
