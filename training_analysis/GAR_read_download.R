# /* #!/usr/bin/env Rscript  */
#' ---
#' title: "Parse of Garmin data dump"
#' date:  "`r format(Sys.time(), '%F')`"
#'
#' documentclass:   article
#' classoption:     a4paper,oneside
#' fontsize:        10pt
#' geometry:        "left=0.5in,right=0.5in,top=0.5in,bottom=0.5in"
#'
#' link-citations:  yes
#' colorlinks:      yes
#'
#' header-includes:
#' - \usepackage{caption}
#' - \usepackage{placeins}
#' - \captionsetup{font=small}
#'
#' output:
#'   bookdown::pdf_document2:
#'     number_sections:  no
#'     fig_caption:      no
#'     keep_tex:         yes
#'     keep_md:          yes
#'     latex_engine:     xelatex
#'     toc:              yes
#'     fig_width:        8
#'     fig_height:       3
#'   html_document:
#'     toc:              true
#'     fig_width:        8
#'     fig_height:       4
#' ---
#+ echo=F, include=T

#### Read data from Garmin Connect data dump



####_ Set environment _####
# closeAllConnections()
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

#+ echo=F, include=T
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
rm(GData_RunRacePredictions)




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
    par(mar = c(3,2,2,1))
    plot(GData_FitnessAgeData$asOfDateGmt.date, GData_FitnessAgeData[[av]],
         ylab = "", xlab = "", cex = 0.6, type = "o")
    title(av)
}
write_RDS(object = GData_FitnessAgeData,
          file   = paste0(outbase, "/", "Garmin_Fitness_Age_Data"))
rm(GData_FitnessAgeData)




#'
#' ## Metrics Acute Training Load
#'
#+ include=T, echo=F
GData_MetricsAcuteTrainingLoad[, Date   := as.POSIXct(timestamp/1000, origin = "1970-01-01")]
GData_MetricsAcuteTrainingLoad[, Date_2 := as.POSIXct(calendarDate/1000, origin = "1970-01-01")]

stopifnot(length(unique(GData_MetricsAcuteTrainingLoad$acwrStatus)) == 4)
GData_MetricsAcuteTrainingLoad$acwrStatus <- factor(GData_MetricsAcuteTrainingLoad$acwrStatus,
                                                    levels  = c("LOW", "OPTIMAL", "HIGH", "VERY_HIGH" ),
                                                    ordered = TRUE)

wecare <- grep("Date|time" , names(GData_MetricsAcuteTrainingLoad), value = T, invert = T, ignore.case = T)
for (av in wecare) {
    par(mar = c(3,2,2,1))
    if (is.character(GData_MetricsAcuteTrainingLoad[[av]])) {
        GData_MetricsAcuteTrainingLoad[[av]] <- factor(GData_MetricsAcuteTrainingLoad[[av]])
    }
    plot(GData_MetricsAcuteTrainingLoad$Date, GData_MetricsAcuteTrainingLoad[[av]],
         ylab = "", xlab = "", cex = 0.6, type = "o", col = GData_MetricsAcuteTrainingLoad$acwrStatus)
    title(av)
    legend("top", pch = 1, cex = 0.7, bty = "n", ncol = 2,
           legend = levels(GData_MetricsAcuteTrainingLoad$acwrStatus),
           col    = 1:4 )
}
write_RDS(object = GData_MetricsAcuteTrainingLoad,
          file   = paste0(outbase, "/", "Garmin_Metrics_Acute_Training_Load"))
rm(GData_MetricsAcuteTrainingLoad)



#'
#' ## Hydration Log
#'
#+ include=T, echo=F
GData_HydrationLogFile <- GData_HydrationLogFile[ duration != 0 ]
GData_HydrationLogFile <- rm.cols.NA.DT(GData_HydrationLogFile)
GData_HydrationLogFile[, calendarDate.date := NULL ]
GData_HydrationLogFile[, uuid.id           := NULL ]
GData_HydrationLogFile$Date       <- as.POSIXct(strptime(GData_HydrationLogFile$persistedTimestampGMT.date, "%b %d, %Y %r"), tz = "UTC")
GData_HydrationLogFile$Date_local <- as.POSIXct(strptime(GData_HydrationLogFile$timestampLocal.date,        "%b %d, %Y %r", tz = "Europe/Athens"), tz = "Europe/Athens")
GData_HydrationLogFile[, persistedTimestampGMT.date := NULL ]
GData_HydrationLogFile[, timestampLocal.date := NULL ]


wecare <- grep("Date|time" , names(GData_HydrationLogFile), value = T, invert = T, ignore.case = T)
for (av in wecare) {
    par(mar = c(3,2,2,1))
    plot(GData_HydrationLogFile$Date, GData_HydrationLogFile[[av]],
         ylab = "", xlab = "", cex = 0.6, type = "o")
    title(av)
}
write_RDS(object = GData_HydrationLogFile,
          file   = paste0(outbase, "/", "Garmin_Hydration_Log_File"))
# rm(GData_MetricsAcuteTrainingLoad)





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

plot(GData_UDSFile$calendarDate.date, GData_UDSFile$restingHeartRate  )

plot(GData_UDSFile$calendarDate.date, GData_UDSFile$minAvgHeartRate  )
plot(GData_UDSFile$calendarDate.date, GData_UDSFile$maxAvgHeartRate  )



#'
#' **END**
#+ include=T, echo=F
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n",Sys.time(),Sys.info()["login"],Sys.info()["nodename"],Script.Name,difftime(tac,tic,units="mins")))
