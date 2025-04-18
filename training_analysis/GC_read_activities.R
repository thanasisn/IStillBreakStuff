#!/usr/bin/env Rscript

#### Golden Cheetah read activities summary directly

## Not usually used, we favor reading the whole Ridedb.json
## More detail's in individual files
## Should have the same output with Ridedb

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


warning("time variable is different between data")

## data paths
storagefl <- "~/DATA/Other/GC_json_data.Rds"
gcfolder  <- "~/TRAIN/GoldenCheetah/Athan/activities/"
inputdata <- "~/LOGs/GCmetrics.Rds"
pdfout1   <- "~/LOGs/training_status/GC_all_plots.pdf"
pdfout2   <- "~/LOGs/training_status/GC_all_plots_last.pdf"
export    <- "~/DATA/Other/Train_metrics.Rds"


## we may read the actual GC database same-day?

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
    test   <- gather[, file, filemtime]
    test2  <- merge(test, check , by = "file", all = T)
    files  <- test2[ filemtime != filesmtime | is.na(filemtime) , file ]
    ## drop preexisting files
    gather <- gather[ ! file %in% files ]
} else {
    gather <- data.table()
    files  <- check$file
}

files <- sort(files,decreasing = T)

####  Parse chosen files  ####
if (length(files) != 0) {
    cat(paste("\nNew activities to parse\n"))
    ## read files
    for (af in files) {
        ## get file

        ## filterout bad json character
        # ridejson <- fromJSON(
        #     paste(
        #         system(
        #             paste("sed '1 s/^\xef\xbb\xbf//'", af),
        #             ignore.stdout = F, intern = T ),
        #         collapse = "\n")
        # )

        ride <- fromJSON(af)
        ride <- ride$RIDE
        cat(paste(basename(af)),"\n")

        ## check data structure
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
            ## get general meta data
            file       = af,
            filemtime  = file.mtime(af),
            time       = as.POSIXct(ride$STARTTIME),
            RECINTSECS = ride$RECINTSECS,
            DEVICETYPE = ride$DEVICETYPE,
            IDENTIFIER = ride$IDENTIFIER,
            ## get metrics
            data.frame(ride$TAGS)
        )

        ## read manual edited values
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

        ## we ignore intervals for now
        # ride$INTERVALS

        ## recorded data
        # ride$SAMPLES
        # ride$XDATA

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
    wecare <- c()
    wecare <- c(
        "Average.Heart.Rate",
        "CP",
        "Calories",
        "Daniels.Points",
        "Duration",
        "OVRD_time_riding",
        "RECINTSECS",
        "RPE",
        "Recovery.Time",
        "Time.Moving",
        "RPE",
        "Feel",
        "Work",
        "cc",
        "xPower",
        NULL)
    wecare <- names(gather)[names(gather) %in% wecare]

    wecare <- unique(wecare, grep("detected", names(gather), value = TRUE, ignore.case = TRUE))
    wecare <- unique(wecare, grep("speed",    names(gather), value = TRUE, ignore.case = TRUE))
    wecare <- unique(wecare, grep("effect",   names(gather), value = TRUE, ignore.case = TRUE))
    wecare <- unique(wecare, grep("distance", names(gather), value = TRUE, ignore.case = TRUE))
    wecare <- unique(wecare, grep("weight",   names(gather), value = TRUE, ignore.case = TRUE))
    wecare <- unique(wecare, grep("cadence",  names(gather), value = TRUE, ignore.case = TRUE))
    wecare <- unique(wecare, grep("cadence",  names(gather), value = TRUE, ignore.case = TRUE))

    for (avar in wecare) {
        gather[[avar]][gather[[avar]] == 0] <- NA
    }

    ## drop columns with zero or NA only
    for (avar in names(gather)) {
        if (all(gather[[avar]] %in% c(NA, 0))) {
            gather[[avar]] <- NULL
        }
    }
    gather[, Year  := NULL]
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
wecare <- c()
wecare <- c(
    "Average.Heart.Rate",
    "CP",
    "Calories",
    "Daniels.Points",
    "Distance",
    "Duration",
    "OVRD_time_riding",
    "OVRD_total_distance",
    "RECINTSECS",
    "RPE",
    "Recovery.Time",
    "Time.Moving",
    "Work",
    "RPE",
    "Feel",
    "cc",
    "xPower",
    NULL)
wecare <- names(metrics)[names(metrics) %in% wecare]

wecare <- unique(wecare, grep("detected", names(gather), value = TRUE, ignore.case = TRUE))
wecare <- unique(wecare, grep("speed",    names(gather), value = TRUE, ignore.case = TRUE))
wecare <- unique(wecare, grep("effect",   names(gather), value = TRUE, ignore.case = TRUE))
wecare <- unique(wecare, grep("distance", names(gather), value = TRUE, ignore.case = TRUE))
wecare <- unique(wecare, grep("weight",   names(gather), value = TRUE, ignore.case = TRUE))
wecare <- unique(wecare, grep("cadence",  names(gather), value = TRUE, ignore.case = TRUE))


for (avar in wecare) {
    if (!is.character(metrics[[avar]])) {
        metrics[[avar]][metrics[[avar]] == 0] <- NA
    }
}
metrics <- data.table(metrics)
metrics[, Notes := NULL]
metrics[, color := NULL]
metrics[, Data  := NULL]
metrics <- rm.cols.dups.DT(metrics)
metrics <- rm.cols.NA.DT(metrics)



### homogenize data ####


####  Calories ####
## gather$Calories has old problematic replacement values probably
# ee <- data.frame(metrics$Calories, gather$Calories)
# gather[!is.na(gather$Calories),time,Calories]
gather$Calories <- NULL

#### Device:  we don't need that ####
# gather[ Device == "unknown", Device := NA ]
# ee <- data.frame(metrics$Device, gather$Device)
gather$Device  <- NULL
metrics$Device <- NULL

#### Route ####
# ee <- data.frame(metrics$Route, gather$Route)
# table(ee)
gather$Route  <- NULL
metrics$Route <- NULL

#### Bike ####
gather$Bike <- NULL


## find duplicate names to check
setorder(gather,  time)
setorder(metrics, time)
tocheck <- grep("time",
                intersect(names(gather), names(metrics)),
                invert = TRUE, ignore.case = TRUE, value = TRUE)

for (avar in tocheck) {
    if (all(metrics[[avar]] == gather[[avar]], na.rm = TRUE)) {
        cat(paste(avar, "equal on both"),"\n")
    }
}


gather$Sport
metrics$Sport

## more problems
metrics$Distance
gather$Distance
test <- cbind(gather[, time, Distance],metrics[, time, Distance])





###  merge and hope for the best!!!  ####
warning("Not the same time!!")
## due to local time and summer time differences
metrics <- unique(merge(metrics, gather, by = "time", all = T))
setorder(metrics,time)

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
setorder(metrics, time)

## get duplicate columns
dup.vec <- which(duplicated(t(metrics)))
dup.vec <- names(metrics)[dup.vec]

# create a vector with the checksum for each column keeps the column names as row names
col.checksums <- sapply(metrics, function(x) digest::digest(x, "md5"), USE.NAMES = T)
dup.cols      <- data.table(col.name = names(col.checksums), hash.value = col.checksums)
dup.cols      <- dup.cols[dup.cols, on = "hash.value"][col.name != i.col.name,]



## remove manual
metrics[, DEVICETYPE        := NULL]
metrics[, RECINTSECS        := NULL]
metrics[, Device.Info       := NULL]
metrics[, VO2max.detected   := NULL]
metrics[, Workout.Title     := NULL]
metrics[, X1_sec_Peak_Power := NULL]
metrics[, NP                := NULL]
metrics[, IF                := NULL]
metrics[, filemtime         := NULL]
metrics[, file              := NULL]
metrics[, Checksum          := NULL]
metrics[, Calendar_Text     := NULL]
metrics[, Athlete           := NULL]
metrics[, Weekday           := NULL]

## drop zeros on some columns

wecare <- grep("temp", names(metrics), value = TRUE, ignore.case = TRUE)
for (avar in wecare) {
    metrics[[avar]][metrics[[avar]] < -200] <- NA
}

wecare <- c(
    grep("EOA",              names(metrics), value = TRUE, ignore.case = TRUE),
    grep("Feel",             names(metrics), value = TRUE, ignore.case = TRUE),
    grep("Heart",            names(metrics), value = TRUE, ignore.case = TRUE),
    grep("IF",               names(metrics), value = TRUE, ignore.case = TRUE),
    grep("LNP",              names(metrics), value = TRUE, ignore.case = TRUE),
    grep("RPE",              names(metrics), value = TRUE, ignore.case = TRUE),
    grep("RTP",              names(metrics), value = TRUE, ignore.case = TRUE),
    grep("TISS",             names(metrics), value = TRUE, ignore.case = TRUE),
    grep("VI$",              names(metrics), value = TRUE, ignore.case = TRUE),
    grep("Weight",           names(metrics), value = TRUE, ignore.case = TRUE),
    grep("_HRV$",            names(metrics), value = TRUE, ignore.case = TRUE),
    grep("_Peak_Hr$",        names(metrics), value = TRUE, ignore.case = TRUE),
    grep("_Peak_Pace$",      names(metrics), value = TRUE, ignore.case = TRUE),
    grep("_Peak_Power_HR$",  names(metrics), value = TRUE, ignore.case = TRUE),
    grep("_Peak_WPK$",       names(metrics), value = TRUE, ignore.case = TRUE),
    grep("_Sustained_Time$", names(metrics), value = TRUE, ignore.case = TRUE),
    grep("_W_bal_",          names(metrics), value = TRUE, ignore.case = TRUE),
    grep("_core_temperatur", names(metrics), value = TRUE, ignore.case = TRUE),
    grep("_in_Zone$",        names(metrics), value = TRUE, ignore.case = TRUE),
    grep("_in_zone$",        names(metrics), value = TRUE, ignore.case = TRUE),
    grep("_ratio",           names(metrics), value = TRUE, ignore.case = TRUE),
    grep("balance",          names(metrics), value = TRUE, ignore.case = TRUE),
    grep("best",             names(metrics), value = TRUE, ignore.case = TRUE),
    grep("bikeintensity",    names(metrics), value = TRUE, ignore.case = TRUE),
    grep("bikescore",        names(metrics), value = TRUE, ignore.case = TRUE),
    grep("bikestress",       names(metrics), value = TRUE, ignore.case = TRUE),
    grep("cadence",          names(metrics), value = TRUE, ignore.case = TRUE),
    grep("carrying",         names(metrics), value = TRUE, ignore.case = TRUE),
    grep("daniels",          names(metrics), value = TRUE, ignore.case = TRUE),
    grep("detected",         names(metrics), value = TRUE, ignore.case = TRUE),
    grep("distance",         names(metrics), value = TRUE, ignore.case = TRUE),
    grep("effect",           names(metrics), value = TRUE, ignore.case = TRUE),
    grep("efficiency",       names(metrics), value = TRUE, ignore.case = TRUE),
    grep("estimated",        names(metrics), value = TRUE, ignore.case = TRUE),
    grep("fatigue_index",    names(metrics), value = TRUE, ignore.case = TRUE),
    grep("govss",            names(metrics), value = TRUE, ignore.case = TRUE),
    grep("iwf",              names(metrics), value = TRUE, ignore.case = TRUE),
    grep("length",           names(metrics), value = TRUE, ignore.case = TRUE),
    grep("pace",             names(metrics), value = TRUE, ignore.case = TRUE),
    grep("pacing_index",     names(metrics), value = TRUE, ignore.case = TRUE),
    grep("power",            names(metrics), value = TRUE, ignore.case = TRUE),
    grep("relative",         names(metrics), value = TRUE, ignore.case = TRUE),
    grep("response",         names(metrics), value = TRUE, ignore.case = TRUE),
    grep("skiba",            names(metrics), value = TRUE, ignore.case = TRUE),
    grep("speed",            names(metrics), value = TRUE, ignore.case = TRUE),
    grep("time",             names(metrics), value = TRUE, ignore.case = TRUE),
    grep("vdot",             names(metrics), value = TRUE, ignore.case = TRUE),
    grep("watts",            names(metrics), value = TRUE, ignore.case = TRUE),
    grep("_W_",              names(metrics), value = TRUE, ignore.case = TRUE),
    grep("work",             names(metrics), value = TRUE, ignore.case = TRUE),
    NULL)

wecare <- names(metrics)[names(metrics) %in% wecare]
for (avar in wecare) {
    metrics[[avar]][metrics[[avar]] == 0] <- NA
}
metrics <- rm.cols.dups.DT(metrics)
metrics <- rm.cols.NA.DT(metrics)






## get duplicate columns
dup.vec <- which(duplicated(t(metrics)))
dup.vec <- names(metrics)[dup.vec]
if (length(dup.vec) > 0) {
    cat("\n\nDuplicate columns exist\n\n")
}

# create a vector with the checksum for each column keeps the column names as row names
col.checksums <- sapply(metrics, function(x) digest::digest(x, "md5"), USE.NAMES = T)
dup.cols      <- data.table(col.name = names(col.checksums), hash.value = col.checksums)
dup.cols      <- dup.cols[dup.cols, on = "hash.value"][col.name != i.col.name,]
dup.cols

metrics[, Weight                    := NULL ]
metrics[, Equipment.Weight          := NULL ]
metrics[, Aerobic.Training.Effect   := NULL ]
metrics[, Anaerobic.Training.Effect := NULL ]
metrics[, Recovery.Time             := NULL ]
metrics[, Performance.Condition     := NULL ]
metrics[, Duration.y                := NULL ]
metrics[, OVRD_workout_time         := NULL ]
# metrics[, Workout.Code              := NULL ]
metrics[, Workout_Title             := NULL ]
metrics[, Activities                := NULL ]


if (all(metrics$Sport.x == metrics$Sport.y, na.rm = T)) {
    metrics$Sport <- metrics$Sport.x
    metrics$Sport.x <- NULL
    metrics$Sport.y <- NULL
}


## set color and symbol for each activity type

table( metrics$Sport )
table( metrics$Workout_Code)

metrics[ Sport == "Bike", Col := "red"  ]
metrics[ Sport == "Run",  Col := "blue" ]
table(metrics$Col)

metrics[,  Pch :=  1 ]

metrics[ Sport == "Bike", Pch := 1 ]
metrics[ Sport == "Run",  Pch := 1 ]

metrics[ Workout_Code == "Bike Road",       Pch :=  6 ]
metrics[ Workout_Code == "Bike Dirt",       Pch :=  1 ]
metrics[ Workout_Code == "Bike Static",     Pch :=  4 ]
metrics[ Workout_Code == "Bike Elliptical", Pch :=  4 ]
metrics[ Workout_Code == "Run Hills",       Pch :=  1 ]
metrics[ Workout_Code == "Run Track",       Pch :=  6 ]
metrics[ Workout_Code == "Run Trail",       Pch :=  8 ]
metrics[ Workout_Code == "Run Race",        Pch :=  9 ]
metrics[ Workout_Code == "Walk",            Pch :=  0 ]
metrics[ Workout_Code == "Walk Hike Heavy", Pch :=  7 ]
metrics[ Workout_Code == "Walk Hike",       Pch := 12 ]

table(metrics$Pch)

grep("Run|Walk", unique(metrics$Workout_Code), ignore.case = T , value = T)

grep("Bike", unique(metrics$Workout_Code), ignore.case = T , value = T)

## create some new metrics
metrics$Intensity_TRIMP       <- metrics$TRIMP_Points       / metrics$Duration.x
metrics$Intensity_TRIMP_Zonal <- metrics$TRIMP_Zonal_Points / metrics$Duration.x
metrics$Intensity_EPOC        <- metrics$EPOC               / metrics$Duration.x
metrics$Intensity_Calories    <- metrics$Calories           / metrics$Duration.x


## TODO
## Hear rate at rest
## MAx heart rate
grep("heart|hr" ,names(metrics), value = T, ignore.case = T)




for (an in names(metrics)) {
    uni <- unique(metrics[[an]])
    uni <- uni[!is.na(uni)]
    if (length(uni) == 1) {
        metrics[[an]] <- NULL
    }
}


for (an in names(metrics)) {
    uni <- unique(metrics[[an]])
    uni <- uni[!is.na(uni)]
    if (length(uni) < 3 ) {
        cat(an,"\n")
        cat(uni,"\n\n")
    }
}







####  Export for others  ####
write_RDS(metrics, file = export, clean = TRUE)


# #### compare all columns ####
# relations <- data.table()
# comb <- names(metrics)
# for (ii in 1:(length(comb) - 1)) {
#     for (jj in (ii + 1):length(comb)) {
#         cat(ii, jj, comb[ii], comb[jj], "\n")
#         mean   = mean(  as.numeric(metrics[[comb[ii]]]) / as.numeric(metrics[[comb[jj]]]), na.rm = T)
#         median = median(as.numeric(metrics[[comb[ii]]]) / as.numeric(metrics[[comb[jj]]]), na.rm = T)
#         cov    = cov(x = as.numeric(metrics[[comb[ii]]]), y = as.numeric(metrics[[comb[jj]]]), use = "pairwise.complete.obs")
#         cor    = cor(x = as.numeric(metrics[[comb[ii]]]), y = as.numeric(metrics[[comb[jj]]]), use = "pairwise.complete.obs")
#
#         relations <- rbind(relations,
#                            data.table(Acol = comb[ii],
#                                       Bcol = comb[jj],
#                                       mean = mean,
#                                       median = median,
#                                       cov = cov,
#                                       cor = cor))
#     }
# }
# relations <- relations[ !(is.na(mean) & is.na(median) & is.na(cor) & is.na(cov)) ]
#
# relations[ abs(median - 1) < 0.001, ]
# relations[ abs(mean   - 1) < 0.001, ]
# relations[ abs(cor    - 1) < 0.001, ]
# relations[ abs(cov    - 1) < 0.005, ]





####  Plot all #####
wecare <- names(metrics)
wecare <- grep("date|time|notes|time|Col|Pch|sport|bike|shoes|CP_setting|filemtime|workout_code",
            wecare, ignore.case = T, value = T, invert = T)

if (!interactive()) {
    pdf(file = pdfout1, width = 8, height = 4)
}


## investigate load metrics
par(mar = c(4,4,1,1))

plot(metrics$EPOC, metrics$TRIMP_Points,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,
     xlab = "EPOC", ylab = "TRIMP")

plot(metrics$EPOC, metrics$TRIMP_Zonal_Points,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,
     xlab = "EPOC", ylab = "TRIMP Zonal")

plot(metrics$TRIMP_Points, metrics$TRIMP_Zonal_Points,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,
     xlab = "TRIMP", ylab = "TRIMP Zonal")

plot(metrics$Calories, metrics$TRIMP_Points,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)
plot(metrics$Calories, metrics$TRIMP_Zonal_Points,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)
plot(metrics$Calories, metrics$EPOC,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)

plot(metrics$Duration.x, metrics$TRIMP_Points/metrics$EPOC,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)

plot(metrics$Distance.x, metrics$TRIMP_Points/metrics$EPOC,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)

plot(metrics$Distance.x, metrics$Distance.y,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)
plot(metrics$Duration.x, metrics$Time_Recording,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)
plot(metrics$Duration.x, metrics$Time_Carrying,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)
plot(metrics$Duration.x, metrics$Time_Moving,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)
plot(metrics$Duration.x, metrics$Time.Moving,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)



for (avar in wecare) {
    ## ignore no data
    if (all(as.numeric(metrics[[avar]]) %in% c(0, NA))) {
        cat(paste("Skip plot", avar),"\n")
        next()
    }

    par(mar = c(2,2,1,1))
    plot(metrics$time, metrics[[avar]],
         col  = metrics$Col,
         pch  = metrics$Pch,
         cex  = 0.6,
         xlab = "", ylab = "")
    title(avar)
}

dev.off()


metrics <- metrics[ as.Date(time) > (Sys.Date() - 400)  ]
if (!interactive()) {
    pdf(file = pdfout2, width = 8, height = 4)
}


## investigate load metrics
par(mar = c(4,4,1,1))

plot(metrics$EPOC, metrics$TRIMP_Points,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,
     xlab = "EPOC", ylab = "TRIMP")

plot(metrics$EPOC, metrics$TRIMP_Zonal_Points,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,
     xlab = "EPOC", ylab = "TRIMP Zonal")

plot(metrics$TRIMP_Points, metrics$TRIMP_Zonal_Points,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,
     xlab = "TRIMP", ylab = "TRIMP Zonal")

plot(metrics$Calories, metrics$TRIMP_Points,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)
plot(metrics$Calories, metrics$TRIMP_Zonal_Points,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)
plot(metrics$Calories, metrics$EPOC,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)

plot(metrics$Duration.x, metrics$TRIMP_Points/metrics$EPOC,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)

plot(metrics$Distance.x, metrics$TRIMP_Points/metrics$EPOC,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)

plot(metrics$Distance.x, metrics$Distance.y,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)
plot(metrics$Duration.x, metrics$Time_Recording,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)
plot(metrics$Duration.x, metrics$Time_Carrying,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)
plot(metrics$Duration.x, metrics$Time_Moving,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)
plot(metrics$Duration.x, metrics$Time.Moving,
     col  = metrics$Col, pch  = metrics$Pch, cex  = 0.6,)



for (avar in wecare) {
    ## ignore no data
    if (all(as.numeric(metrics[[avar]]) %in% c(0, NA))) {
        cat(paste("Skip plot", avar),"\n")
        next()
    }

    par(mar = c(2,2,1,1))
    plot(metrics$time, metrics[[avar]],
         col  = metrics$Col,
         pch  = metrics$Pch,
         cex  = 0.6,
         xlab = "", ylab = "")
    title(avar)
}

dev.off()










####_ END _####
