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
#'     keep_tex:         no
#'     keep_md:          no
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
Script.Name <- "~/CODE/training_analysis/GAR_read_download.R"

# Input folder
datalocation <- "~/ZHOST/ggg/6d2aff5b-0e5a-4608-9799-f5e304c02b77_1/"

system(paste0("dos2unix " ,datalocation,"**/*.json"))


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
# fromJSON(grep("user_profile", jsonfls, value = T), flatten = T)
jsonfls <- grep("user_profile", jsonfls, value = T, invert = T)

# fromJSON(grep("social-profile", jsonfls, value = T), flatten = T)
jsonfls <- grep("social-profile", jsonfls, value = T, invert = T)

# fromJSON(grep("user_contact", jsonfls, value = T), flatten = F)
jsonfls <- grep("user_contact", jsonfls, value = T, invert = T)

# fromJSON(grep("UserGoal", jsonfls, value = T), flatten = F)
jsonfls <- grep("UserGoal", jsonfls, value = T, invert = T)

# fromJSON(grep("_courses", jsonfls, value = T), flatten = F)
# jsonfls <- grep("_courses", jsonfls, value = T, invert = T)

# fromJSON(grep("_gear", jsonfls, value = T), flatten = T)
jsonfls <- grep("_gear", jsonfls, value = T, invert = T)

# fromJSON(grep("_goal", jsonfls, value = T), flatten = T)
jsonfls <- grep("_goal", jsonfls, value = T, invert = T)

# fromJSON(grep("_personalRecord", jsonfls, value = T), flatten = T)
jsonfls <- grep("_personalRecord", jsonfls, value = T, invert = T)

fromJSON(grep("_workout", jsonfls, value = T), flatten = T)
jsonfls <- grep("_workout", jsonfls, value = T, invert = T)

# fromJSON(grep("user_settings", jsonfls, value = T), flatten = T)
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
    ## skip non info
    if (length(unique(na.omit(GData_RunRacePredictions[[av]]))) <= 1) next()

    plot(GData_RunRacePredictions$calendarDate , GData_RunRacePredictions[[av]],
    xlab = "", ylab = "", main = av, cex = 0.6 )
}
write_RDS(object = GData_RunRacePredictions,
          file   = paste0(outbase, "/", "Garmin_Run_Race_Predictions"))
# rm(GData_RunRacePredictions)




#'
#' ## Fitness Age Data
#'
#+ include=T, echo=F
GData_fitnessAgeData$asOfDateGmt             <- as.POSIXct(strptime(GData_fitnessAgeData$asOfDateGmt,             "%FT%T"))
GData_fitnessAgeData$createTimestamp         <- as.POSIXct(strptime(GData_fitnessAgeData$createTimestamp,         "%FT%T"))
GData_fitnessAgeData$weightDataLastEntryDate <- as.POSIXct(strptime(GData_fitnessAgeData$weightDataLastEntryDate, "%FT%T"))
GData_fitnessAgeData$rhrLastEntryDate        <- as.POSIXct(strptime(GData_fitnessAgeData$rhrLastEntryDate,        "%FT%T"))

wecare <- names(GData_fitnessAgeData)
wecare <- grep("date|timestamp", wecare, ignore.case = T, invert = T, value = T)
for (av in wecare) {
    par(mar = c(3,2,2,1))
    ## skip non info
    if (length(unique(na.omit(GData_fitnessAgeData[[av]]))) <= 1) next()

    plot(GData_fitnessAgeData$asOfDateGmt, GData_fitnessAgeData[[av]],
         ylab = "", xlab = "", cex = 0.6, type = "o")
    title(av)
}
write_RDS(object = GData_fitnessAgeData,
          file   = paste0(outbase, "/", "Garmin_Fitness_Age_Data"))
# rm(GData_FitnessAgeData)




#'
#' ## Metrics Acute Training Load
#'
#+ include=T, echo=F
GData_MetricsAcuteTrainingLoad[, Date   := as.POSIXct(timestamp/1000,    origin = "1970-01-01")]
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
    ## skip non info
    if (length(unique(na.omit(GData_MetricsAcuteTrainingLoad[[av]]))) <= 1) next()

    plot(GData_MetricsAcuteTrainingLoad$Date, GData_MetricsAcuteTrainingLoad[[av]],
         ylab = "", xlab = "", cex = 0.6, type = "o", col = GData_MetricsAcuteTrainingLoad$acwrStatus)
    title(av)
    legend("top", pch = 1, cex = 0.7, bty = "n", ncol = 2,
           legend = levels(GData_MetricsAcuteTrainingLoad$acwrStatus),
           col    = 1:4 )
}
write_RDS(object = GData_MetricsAcuteTrainingLoad,
          file   = paste0(outbase, "/", "Garmin_Metrics_Acute_Training_Load"))
# rm(GData_MetricsAcuteTrainingLoad)



#'
#' ## Hydration Log
#'
#+ include=T, echo=F
GData_HydrationLogFile <- GData_HydrationLogFile[ duration != 0 ]
GData_HydrationLogFile <- rm.cols.NA.DT(GData_HydrationLogFile)
GData_HydrationLogFile[, calendarDate := NULL]
GData_HydrationLogFile[, uuid.uuid    := NULL]
GData_HydrationLogFile$Date       <- as.POSIXct(strptime(GData_HydrationLogFile$persistedTimestampGMT, "%FT%T"), tz = "UTC")
GData_HydrationLogFile$Date_local <- as.POSIXct(strptime(GData_HydrationLogFile$timestampLocal,        "%FT%T", tz = "Europe/Athens"), tz = "Europe/Athens")
GData_HydrationLogFile[, persistedTimestampGMT := NULL]
GData_HydrationLogFile[, timestampLocal        := NULL]

wecare <- grep("Date|time|activityId" , names(GData_HydrationLogFile), value = T, invert = T, ignore.case = T)
for (av in wecare) {
    par(mar = c(3,2,2,1))
    ## skip non info
    if (length(unique(na.omit(GData_HydrationLogFile[[av]]))) <= 1) next()

    plot(GData_HydrationLogFile$Date, GData_HydrationLogFile[[av]],
         ylab = "", xlab = "", cex = 0.6, type = "o")
    title(av)
}
write_RDS(object = GData_HydrationLogFile,
          file   = paste0(outbase, "/", "Garmin_Hydration_Log_File"))
# rm(GData_HydrationLogFile)




#'
#' ## Metrics Max Met Data
#'
#+ include=T, echo=F
GData_MetricsMaxMetData <- rm.cols.NA.DT(GData_MetricsMaxMetData)
GData_MetricsMaxMetData$calendarDate <- NULL
GData_MetricsMaxMetData$Date       <- as.POSIXct(strptime(GData_MetricsMaxMetData$updateTimestamp, "%FT%T"))
GData_MetricsMaxMetData$fitnessAge <- as.numeric(GData_MetricsMaxMetData$fitnessAge)
GData_MetricsMaxMetData$fitnessAgeDescription <- as.numeric(GData_MetricsMaxMetData$fitnessAgeDescription)
GData_MetricsMaxMetData$sport      <- as.factor(GData_MetricsMaxMetData$sport)
GData_MetricsMaxMetData$subSport   <- as.factor(GData_MetricsMaxMetData$subSport)

wecare <- grep("Date|time" , names(GData_MetricsMaxMetData), value = T, invert = T, ignore.case = T)
for (av in wecare) {
    par(mar = c(3,2,2,1))
    ## skip non info
    if (length(unique(na.omit(GData_MetricsMaxMetData[[av]]))) <= 1) next()
    plot(GData_MetricsMaxMetData$Date, GData_MetricsMaxMetData[[av]],
         ylab = "", xlab = "", cex = 0.6, type = "o")
    title(av)
}
write_RDS(object = GData_MetricsMaxMetData,
          file   = paste0(outbase, "/", "Garmin_Metrics_Max_Met_Data"))
# rm(GData_MetricsMaxMetData)





#'
#' ## Summarized Activities Data
#'
#+ include=T, echo=F
GData_summarizedActivities <- rm.cols.NA.DT(GData_summarizedActivities)
GData_summarizedActivities[, timeZoneId := NULL ]
GData_summarizedActivities[, startTimeGmt   := as.POSIXct(startTimeGmt/1000,   origin = "1970-01-01", tz = "UTC")]
GData_summarizedActivities[, startTimeLocal := as.POSIXct(startTimeLocal/1000, origin = "1970-01-01", tz = "Europe/Athens")]
GData_summarizedActivities[, beginTimestamp := as.POSIXct(beginTimestamp/1000, origin = "1970-01-01", tz = "UTC")]

wecare <- grep("startTimeGmt", names(GData_summarizedActivities), value = T, invert = T, ignore.case = T)
for (av in wecare) {
    par(mar = c(3,2,2,1))
    if (is.character(GData_summarizedActivities[[av]])) next()
    if (is.list(GData_summarizedActivities[[av]]))      next()
    ## skip non info
    if (length(unique(na.omit(GData_summarizedActivities[[av]]))) <= 1) next()

    plot(GData_summarizedActivities$startTimeGmt, GData_summarizedActivities[[av]],
         ylab = "", xlab = "", cex = 0.6, type = "o")
    title(av)
}
write_RDS(object = GData_summarizedActivities,
          file   = paste0(outbase, "/", "Garmin_Summarized_Activities_Data"),
          clean  = TRUE)





#'
#' ## UDS File Data
#'
#+ include=T, echo=F
## keep only garmin collected data
GData_UDSFile <- GData_UDSFile[ !is.na(source) ]
GData_UDSFile[, restingHeartRateTimestamp := as.POSIXct(strptime(restingHeartRateTimestamp, "%b %d, %Y %r")) ]
GData_UDSFile[, calendarDate.date         := as.POSIXct(strptime(calendarDate.date, "%b %d, %Y %r")) ]

grep("date|time" ,names(GData_UDSFile), ignore.case = T, value = T)

wecare <- grep("calendarDate.date", names(GData_UDSFile), value = T, invert = T, ignore.case = T)
for (av in wecare) {
    par(mar = c(3,2,2,1))
    if (is.character(GData_UDSFile[[av]])) next()
    if (is.list(GData_UDSFile[[av]]))      next()
    ## skip non info
    if (length(unique(na.omit(GData_UDSFile[[av]]))) <= 1) next()

    plot(GData_UDSFile$calendarDate.date, GData_UDSFile[[av]],
         ylab = "", xlab = "", cex = 0.6, type = "o")
    title(av)
}
write_RDS(object = GData_UDSFile,
          file   = paste0(outbase, "/", "Garmin_UDS_File_Data"))






## TODO


names(GData_sleepData)

names(GData_TrainingHistory)

GData_TrainingHistory$timestamp <- as.POSIXct(strptime( GData_TrainingHistory$timestamp, "%FT%R" ))


ylim <- range(GData_TrainingHistory$loadTunnelMin,
              GData_TrainingHistory$loadTunnelMax,
              GData_TrainingHistory$weeklyTrainingLoadSum, na.rm = T)

plot(GData_TrainingHistory$timestamp, GData_TrainingHistory$weeklyTrainingLoadSum,
     ylim = ylim, col = "green")
lines(GData_TrainingHistory$timestamp, GData_TrainingHistory$loadTunnelMin, col = "blue")
lines(GData_TrainingHistory$timestamp, GData_TrainingHistory$loadTunnelMax, col = "red")










plot(GData_UDSFile$calendarDate.date, GData_UDSFile$minHeartRate  )
plot(GData_UDSFile$calendarDate.date, GData_UDSFile$maxHeartRate  )

plot(GData_UDSFile$calendarDate.date, GData_UDSFile$maxHeartRate  )

ylim <- range(GData_UDSFile$restingHeartRate, GData_UDSFile$currentDayRestingHeartRate, na.rm = T)
plot(GData_UDSFile$calendarDate.date, GData_UDSFile$restingHeartRate , ylim = ylim )
points(GData_UDSFile$calendarDate.date, GData_UDSFile$currentDayRestingHeartRate , col = "blue"  )




plot(GData_UDSFile$calendarDate.date, GData_UDSFile$minAvgHeartRate  )
plot(GData_UDSFile$calendarDate.date, GData_UDSFile$maxAvgHeartRate  )

grep( "Heart" ,names(GData_UDSFile), value = T)


## combine some for export

export <- GData_FitnessAgeData[, asOfDateGmt.date, rhr ]
part   <- GData_summarizedActivities[, .(startTimeGmt ,avgHr, maxHr)]
export <- merge(export, part, by.x = "asOfDateGmt.date", by.y = "startTimeGmt", all = T)
part   <- GData_UDSFile[!is.na(restingHeartRate), .(restingHeartRate, restingHeartRateTimestamp)]
export <- merge(export, part, by.x = "asOfDateGmt.date", by.y = "restingHeartRateTimestamp", all = T)

wecare <- grep("Date", names(export), value = T, invert = T)

export <- export[rowSums(!is.na(export[, ..wecare]))>0, ]



exporte <-
export[, .(avgHr            = mean(avgHr, na.rm = T),
           rhr              = mean(rhr,   na.rm = T),
           restingHeartRate = mean(restingHeartRate,   na.rm = T),
           maxHr            = mean(maxHr, na.rm = T)),
       by = .(Date = as.Date(asOfDateGmt.date)-1)]

xlim <- range(exporte[!is.na(rhr), Date], exporte[!is.na(restingHeartRate), Date] )
ylim <- range(exporte[, rhr, restingHeartRate], na.rm = T)

plot(exporte$Date,  exporte$rhr, "l", xlim = xlim, col = "blue", ylim = ylim)
lines(exporte$Date, exporte$restingHeartRate, col = "green")

write.csv( exporte,
           "resting_heartrate.csv")



plot(GData_UDSFile[, minHeartRate])
plot(GData_UDSFile[, minAvgHeartRate])
plot(GData_UDSFile[, maxHeartRate])
plot(GData_UDSFile[, maxAvgHeartRate])
plot(GData_UDSFile[, restingHeartRate])



plot(GData_user_biometrics[, functionalThresholdPower])


#'
#' **END**
#+ include=T, echo=F
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n",Sys.time(),Sys.info()["login"],Sys.info()["nodename"],Script.Name,difftime(tac,tic,units="mins")))
