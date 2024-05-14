#!/usr/bin/env Rscript
# /* Copyright (C) 2022 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:         "Golden Cheetah read activities summary directly from individual files"
#' author:
#'   - Natsis Athanasios^[natsisphysicist@gmail.com]
#'
#' documentclass:  article
#' classoption:    a4paper,oneside
#' fontsize:       10pt
#' geometry:       "left=0.5in,right=0.5in,top=0.5in,bottom=0.5in"
#' link-citations: yes
#' colorlinks:     yes
#'
#' header-includes:
#' - \usepackage{caption}
#' - \usepackage{placeins}
#' - \captionsetup{font=small}
#'
#' output:
#'   bookdown::pdf_document2:
#'     number_sections: no
#'     fig_caption:     no
#'     keep_tex:        yes
#'     latex_engine:    xelatex
#'     toc:             yes
#'     toc_depth:       4
#'     fig_width:       7
#'     fig_height:      4.5
#'   html_document:
#'     toc:             true
#'     keep_md:         yes
#'     fig_width:       7
#'     fig_height:      4.5
#'
#' date: "`r format(Sys.time(), '%F')`"
#'
#' ---

#+ echo=F, include=T

#### Golden Cheetah read activities summary directly from individual files

## __ Document options  --------------------------------------------------------

#+ echo=FALSE, include=TRUE
knitr::opts_chunk$set(comment    = ""       )
knitr::opts_chunk$set(dev        = c("pdf")) ## expected option
# knitr::opts_chunk$set(dev        = "png"    )       ## for too much data
knitr::opts_chunk$set(out.width  = "100%"   )
knitr::opts_chunk$set(fig.align  = "center" )
knitr::opts_chunk$set(cache      =  FALSE   )  ## !! breaks calculations
knitr::opts_chunk$set(fig.pos    = '!h'     )

###TODO explore this tools
# library(cycleRtools)
# GC_activity("Athan",activity = "~/TRAIN/GoldenCheetah/Athan/activities/2008_12_19_16_00_00.json")
# GC_activity("Athan")
# GC_metrics("Athan")
# read_ride(file = af)


#+ echo=FALSE, include=TRUE
## __ Set environment  ---------------------------------------------------------
Sys.setenv(TZ = "UTC")
Script.Name <- "~/CODE/training_analysis/GC_read_activities_json.R"


if (!interactive()) {
  dir.create("./runtime/", showWarnings = F, recursive = T)
  pdf( file = paste0("./runtime/", basename(sub("\\.R$",".pdf", Script.Name))))
}

#+ echo=F, include=T
library(data.table, quietly = TRUE, warn.conflicts = FALSE)
library(arrow,      quietly = TRUE, warn.conflicts = FALSE)
library(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
library(filelock,   quietly = TRUE, warn.conflicts = FALSE)
library(jsonlite,   quietly = TRUE, warn.conflicts = FALSE)
library(lubridate,  quietly = TRUE, warn.conflicts = FALSE)


## data paths
gcfolder <- "~/TRAIN/GoldenCheetah/Athan/activities"
DATASET  <- "/home/athan/DATA/Other/Activities_list"



##  List files
file <- list.files(path       = gcfolder,
                   pattern    = "*.json",
                   full.names = TRUE)

file <- data.table(file      = file,
                   filemtime = floor_date(file.mtime(file), unit = "seconds"))


##  Open dataset
if (file.exists(DATASET)) {
  DB <- open_dataset(DATASET,
                     partitioning  = c("year"),
                     unify_schemas = T)
  db_rows <- unlist(DB |> tally() |> collect())
} else {
  stop("Init DB manually!")
}



##  Check what to do
wehave <- DB |> select(file, filemtime) |> unique() |> collect() |> data.table()

##  Ignore files with the same name and mtime
file <- file[ !(file %in% wehave$file & filemtime %in% wehave$filemtime) ]



##  TODO remove changed files from DB
##  TODO remove deleted files from DB




# files <- sample(file$file, 10)

files <- unique(c(head(file$file, 366),
                  tail(file$file, 366)))


if (length(files) < 1) {
  stop("Nothing to do!")
}


data <- data.table()
for (af in files) {
  cat(af,"\n")

  jride <- fromJSON(af)$RIDE

  # jride$STARTTIME
  # jride$OVERRIDES[[1]]
  # jride$TAGS
  # jride$SAMPLES
  # jride$XDATA

  # dfs <- names(jride)
  # for (a in dfs) {
  #   cat(a, length(jride[[a]]), "\n")
  #   cat(a, class(jride[[a]]), "\n")
  # }

  act_ME <- data.table(
    ## get general meta data
    file       = af,
    filemtime  = floor_date(file.mtime(af), unit = "seconds"),
    time       = as.POSIXct(strptime(jride$STARTTIME, "%Y/%m/%d %T", tz = "UTC")),
    parsed     = Sys.time(),
    RECINTSECS = jride$RECINTSECS,
    DEVICETYPE = jride$DEVICETYPE,
    IDENTIFIER = jride$IDENTIFIER,
    ## get metrics
    data.frame(jride$TAGS)
  )

  ## drop some data
  act_ME$Month    <- NULL
  act_ME$Weekday  <- NULL
  act_ME$Year     <- NULL
  act_ME$Filename <- NULL

  ## read manual edited values
  if (!is.null(jride$OVERRIDES)) {
    ss        <- data.frame(t(diag(as.matrix(jride$OVERRIDES))))
    names(ss) <- paste0("OVRD_", names(jride$OVERRIDES))
    act_ME    <- cbind(act_ME, ss)
    rm(ss)
  }

  data <- rbind(data, act_ME, fill = TRUE)
}


## convert types if possible
for (avar in names(data)) {
  if (is.character(data[[avar]])) {
    ## find empty and replace
    data[[avar]] <- sub("[ ]*$",        "", data[[avar]])
    data[[avar]] <- sub("^[ ]*",        "", data[[avar]])
    data[[avar]] <- sub("^[ ]*$",       NA, data[[avar]])
    data[[avar]] <- sub("^[ ]*NA[ ]*$", NA, data[[avar]])
    if (!all(is.na((as.numeric(data[[avar]]))))) {
      data[[avar]] <- as.numeric(data[[avar]])
    }
  }
}

data <- data.table(data)
data[, year := as.integer(year(time)) ]

## TODO check for new variables in the db


## merge all rows
DB <- DB |> full_join(data) |> compute()

cat("\nNew rows:", nrow(DB) - db_rows, "\n")

## write only new months within gather
new <- unique(data[, year])

cat("\nUpdate:", new, "\n")

write_dataset(DB |> filter(year %in% new),
              DATASET,
              compression            = "brotli",
              compression_level      = 5,
              format                 = "parquet",
              partitioning           = c("year"),
              existing_data_behavior = "delete_matching",
              hive_style             = F)












## Init data base manually
# stop()
# write_dataset(data,
#               DATASET,
#               compression            = "brotli",
#               compression_level      = 5,
#               format       = "parquet",
#               partitioning = c("year"),
#               existing_data_behavior = "delete_matching",
#               hive_style   = F)




stop()

## read files
for (af in files) {
  ## get file

  ## drop zeros on some columns
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

}







### homogenize data ####


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




####  Export for others  ####


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
