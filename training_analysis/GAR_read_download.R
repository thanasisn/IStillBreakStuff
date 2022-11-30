#!/usr/bin/env Rscript
#' ---
#' title: "Study of Global radiation enhancement over Thessaloniki"
#' date: "`r format(Sys.time(), '%F')`"
#'
#' documentclass: article
#' classoption:   a4paper,oneside
#' fontsize:      11pt
#' geometry:      "left=1in,right=1in,top=1in,bottom=1in"
#'
#' header-includes:
#' - \usepackage{caption}
#' - \usepackage{placeins}
#' - \captionsetup{font=small}
#' - \usepackage{multicol}
#' - \setlength{\columnsep}{1cm}
#'
#' output:
#'   bookdown::pdf_document2:
#'     number_sections:  no
#'     fig_caption:      no
#'     keep_tex:         yes
#'     keep_md:          yes
#'     latex_engine:     xelatex
#'     toc:              yes
#' ---


#### Read data from Garmin Connect data dump

#+ include=T, echo=F


####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- tryCatch({ funr::sys.script() },
                        error = function(e) { cat(paste("\nUnresolved script name: ", e),"\n\n")
                            return("Garmin_read_dump") })

datalocation <- "~/ZHOST/ggg/6d2aff5b-0e5a-4608-9799-f5e304c02b77_1/"


library(data.table)
library(jsonlite)
source("~/FUNCTIONS/R/data.R")
source("~/CODE/R_myRtools/myRtools/R/write_.R")

outbase <- "~/DATA/Other/Garmin/"


allfiles <- list.files(datalocation, recursive = TRUE, full.names = TRUE)
## drop empty files
allfiles <- allfiles[file.size(allfiles) > 10]

## show file types
table(sub( ".*\\.", "" , basename(allfiles)))



####  parse json  ####
jsonfls <- grep(".json$", allfiles, ignore.case = TRUE, value = TRUE)

jsonfls[file.size(jsonfls) <= 300]

## check and remove some files we don't care for
fromJSON(grep("user_profile", jsonfls, value = T), flatten = T)
jsonfls <- grep("user_profile", jsonfls, value = T, invert = T)

fromJSON(grep("social-profile", jsonfls, value = T), flatten = T)
jsonfls <- grep("social-profile", jsonfls, value = T, invert = T)

fromJSON(grep("user_contact", jsonfls, value = T), flatten = F)
jsonfls <- grep("user_contact", jsonfls, value = T, invert = T)

fromJSON(grep("UserGoal", jsonfls, value = T), flatten = F)
jsonfls <- grep("UserGoal", jsonfls, value = T, invert = T)

fromJSON(grep("_courses", jsonfls, value = T), flatten = F)
jsonfls <- grep("_courses", jsonfls, value = T, invert = T)

fromJSON(grep("_gear", jsonfls, value = T), flatten = T)
jsonfls <- grep("_gear", jsonfls, value = T, invert = T)

fromJSON(grep("_goal", jsonfls, value = T), flatten = T)
jsonfls <- grep("_goal", jsonfls, value = T, invert = T)

fromJSON(grep("_personalRecord", jsonfls, value = T), flatten = T)
jsonfls <- grep("_personalRecord", jsonfls, value = T, invert = T)

fromJSON(grep("_workout", jsonfls, value = T), flatten = T)
jsonfls <- grep("_workout", jsonfls, value = T, invert = T)

fromJSON(grep("user_settings", jsonfls, value = T), flatten = T)
jsonfls <- grep("user_settings", jsonfls, value = T, invert = T)


## groups of similar files
groups <- unique(sub("__", "", sub(".json", "", gsub( "[-[:digit:]]+", "", basename( jsonfls )))))
groups <- sub("_$","", sub("^_","", groups))
groups <- sub("dangas","", groups)


## parse all files
for (ag in groups) {
    pfiles <- agrep(ag, jsonfls, value = T)
    cat("\n\nGroup:", ag, length(pfiles),"\n")
    cat(pfiles,"\n")
    gather <- data.table()
    for (af in pfiles) {
        cat(basename(af),"\n")
        tmp    <- fromJSON(af, flatten = TRUE)
        ## unwrap lists
        while (length(tmp) == 1) {
            tmp <- tmp[[1]]
        }
        if (typeof(tmp) == "list") {
            tmp$preferredLocale <- NULL
            tmp$handedness      <- NULL
            tmp <- list2DF(tmp)
            # tmp <- as.data.frame(do.call(cbind, tmp))
            # tmp <- as.data.frame(do.call(rbind, tmp))
            # tmp <- rbindlist(tmp, fill = T)
        }
        gather <- rbind(gather, tmp, fill = TRUE)
    }
    # gather <- unique(gather)
    gather <- rm.cols.NA.DT(gather)
    gather <- rm.cols.dups.DT(gather)
    ag     <- paste0("GData_", ag)
    assign(ag, gather)
    rm(gather, tmp)
}



#'
#' ## Run Race Predictions
#'
#+ include=T, echo=F
GData_RunRacePredictions$timestamp    <- NULL
GData_RunRacePredictions              <- unique(GData_RunRacePredictions)
GData_RunRacePredictions$calendarDate <- as.Date( GData_RunRacePredictions$calendarDate )

wecare <- grep("Date" , names(GData_RunRacePredictions), value = T, invert = T)
for (av in wecare) {
    par(mar = c(2,2,2,1))
    plot(GData_RunRacePredictions$calendarDate , GData_RunRacePredictions[[av]],
    xlab = "", ylab = "", main = av, cex = 0.6 )
}
write_RDS(object = GData_RunRacePredictions,
          file   = paste0(outbase, "/", "Garmin_Run_Race_Predictions"))





#'
#' ## Fitness Age Data
#'
#+ include=T, echo=F
GData_FitnessAgeData$asOfDateGmt.date             <- as.POSIXct(strptime(GData_FitnessAgeData$asOfDateGmt.date,             "%b %d, %Y %r"))
GData_FitnessAgeData$createTimestamp.date         <- as.POSIXct(strptime(GData_FitnessAgeData$createTimestamp.date,         "%b %d, %Y %r"))
GData_FitnessAgeData$weightDataLastEntryDate.date <- as.POSIXct(strptime(GData_FitnessAgeData$weightDataLastEntryDate.date, "%b %d, %Y %r"))
GData_FitnessAgeData$rhrLastEntryDate.date        <- as.POSIXct(strptime(GData_FitnessAgeData$rhrLastEntryDate.date,        "%b %d, %Y %r"))

wecare <- names(GData_FitnessAgeData)
wecare <- grep("date", wecare, ignore.case = T, invert = T, value = T)
for (av in wecare) {
    par(mar = c(2,2,2,1))
    plot(GData_FitnessAgeData$asOfDateGmt.date, GData_FitnessAgeData[[av]],
         ylab = "", xlab = "", cex = 0.6, type = "o")
    title(av)
}
write_RDS(object = GData_FitnessAgeData,
          file   = paste0(outbase, "/", "Garmin_Fitness_Age_Data"))




as.POSIXct( GData_MetricsAcuteTrainingLoad$timestamp/1000 , origin = "1970-01-01")
as.POSIXct( GData_MetricsAcuteTrainingLoad$calendarDate/1000 , origin = "1970-01-01")



GData_MetricsAcuteTrainingLoad[ , Date := as.POSIXct(timestamp/1000, origin = "1970-01-01")]
GData_MetricsAcuteTrainingLoad[ , Date2 := as.POSIXct(calendarDate/1000, origin = "1970-01-01")]




names(GData_sleepData)

names(GData_summarizedActivities)

names(GData_TrainingHistory)

GData_TrainingHistory$timestamp <- as.POSIXct(strptime( GData_TrainingHistory$timestamp, "%FT%R" ))


ylim <- range(GData_TrainingHistory$loadTunnelMin,
              GData_TrainingHistory$loadTunnelMax,
              GData_TrainingHistory$weeklyTrainingLoadSum, na.rm = T)

plot(GData_TrainingHistory$timestamp, GData_TrainingHistory$weeklyTrainingLoadSum,
     ylim = ylim, col = "green")
lines(GData_TrainingHistory$timestamp, GData_TrainingHistory$loadTunnelMin, col = "blue")
lines(GData_TrainingHistory$timestamp, GData_TrainingHistory$loadTunnelMax, col = "red")




grep("date|time" ,names(GData_UDSFile), ignore.case = T, value = T)


table(GData_UDSFile$source,exclude = T)
## keep only garmin collected data
GData_UDSFile <- GData_UDSFile[ !is.na(source) ]



GData_UDSFile$restingHeartRateTimestamp <- as.POSIXct(strptime(GData_UDSFile$restingHeartRateTimestamp, "%b %d, %Y %r"))

GData_UDSFile$calendarDate.date <- as.POSIXct(strptime(GData_UDSFile$calendarDate.date, "%b %d, %Y %r"))


plot(GData_UDSFile$calendarDate.date, GData_UDSFile$minHeartRate  )
plot(GData_UDSFile$calendarDate.date, GData_UDSFile$maxHeartRate  )

plot(GData_FitnessAgeData$asOfDateGmt.date,  GData_FitnessAgeData$rhr )
plot(GData_UDSFile$calendarDate.date, GData_UDSFile$restingHeartRate  )

plot(GData_UDSFile$calendarDate.date, GData_UDSFile$minAvgHeartRate  )
plot(GData_UDSFile$calendarDate.date, GData_UDSFile$maxAvgHeartRate  )



####_ END _####
tac <- Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
