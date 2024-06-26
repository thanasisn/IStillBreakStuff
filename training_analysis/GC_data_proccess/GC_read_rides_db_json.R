#!/usr/bin/env Rscript

#### Golden Cheetah read activities summary directly from rideDB.json

## - Runs if it is needed
## - Reads raw data
## - Applies some filtes
## - Creates some new variables
## - Stores parsed data
## - Plots almost all variables

####_ Set environment _####
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/training_analysis/GC_data_proccess/GC_read_rides_db_json.R"

library(data.table, quietly = TRUE, warn.conflicts = FALSE)
library(jsonlite,   quietly = TRUE, warn.conflicts = FALSE)
library(lubridate,  quietly = TRUE, warn.conflicts = FALSE)
library(plyr,       quietly = TRUE, warn.conflicts = FALSE)
library(fANCOVA,    quietly = TRUE, warn.conflicts = FALSE)
source("~/CODE/FUNCTIONS/R/data.R")
source("~/CODE/FUNCTIONS/R/make_tools.R")
source("~/CODE/R_myRtools/myRtools/R/write_.R")


## data paths
gccache   <- "~/TRAIN/GoldenCheetah/Athan/cache/rideDB.json"
storagefl <- "~/DATA/Other/GC_json_ride_data_2.Rds"
pdfout1   <- "~/LOGs/training_status/GC_all_variables.pdf"
pdfout2   <- "~/LOGs/training_status/GC_all_variables_last.pdf"
LASTDAYS  <- 400

DATA_PLOT_LIMIT <- 10

## choose loess criterion for span
LOESS_CRITERIO <-  c("aicc", "gcv")[1]

DEBUG     <- FALSE
# DEBUG     <- TRUE

if (DEBUG) {
    warning("Debug is active!!")
}



## Parse JSON ------------------------------------------------------------------
if (DEBUG ||
    Rmk_check_dependencies(
      depend.source = Script.Name,                   ## this script
      depend.data   = gccache,                       ## the GoldenCheetah data base
      targets       = c(storagefl, pdfout1, pdfout2) ## output of this script
    ))
{
  cat("\nHave to parse: ", gccache, "\n")

  ## remove BOM
  # system(paste("dos2unix -r ", gccache))

  ## read the whole data base
  data <- fromJSON(gccache, flatten = FALSE)
  stopifnot(length(data) == 2)
  data <- data$RIDES

  ## Basic info for activities
  wecare <- grep("METRICS|TAGS|INTERVALS|XDATA", names(data), invert = TRUE, value = TRUE)

  ## __ Activities meta data ---------------------------------------------------
  a <- data.table(data[, wecare])
  a <- rm.cols.dups.DT(a)
  a[, date := as.POSIXct(date)]
  a$fingerprint <- NULL
  a$metacrc     <- NULL
  a$color       <- NULL
  a[, parsed_on := as.POSIXct(as.numeric(timestamp), origin = "1970-01-01")]
  a$timestamp   <- NULL


  ## breakup data sets
  b <- data$METRIC
  c <- data.table(data$TAGS)
  if (!DEBUG) rm(data)

  ## __ METRICS for activities -------------------------------------------------
  for (av in names(b)) {
    if (is.list(b[[av]])) {
      cat(av, "\n")

      ## protect from null list
      b[[av]][which(sapply(b[[av]], is.null))] <- list(c(NA))

      # https://stackoverflow.com/questions/61768192/how-to-convert-a-list-into-a-dataframe-and-filling-empty-values-with-na-in-r
      # https://stackoverflow.com/questions/15201305/how-to-convert-a-list-consisting-of-vector-of-different-lengths-to-a-usable-data

      # tmp <- data.table(t(list2DF(b[[av]])))
      tmp <- data.table(ldply(b[[av]], rbind))
      tnames <- grep("^[0-9]$", names(tmp), value = T)

      for (anaa in tnames) {
        names(tmp)[names(tmp) == anaa] <- paste0("V", anaa)
      }

      for (at in names(tmp)) {
        uni1 <- unique(tmp[[at]])
        uni  <- uni1[!is.na(uni1)]
        ## remove columns without data variation
        if (length(uni) <= 1) {
          cat("Remove column from", av, at, "\n")
          cat("with only", uni1, "\n")
          tmp[[at]] <- NULL
        }
      }
      ## assume all nested lists are numeric
      for (at in names(tmp)) {
        tmp[[at]] <- as.numeric(tmp[[at]])
      }
      ## only one column to replace
      if (ncol(tmp) == 1) {
        names(tmp) <- av
        b[[av]] <- tmp[[av]]
      }
      ## multiple columns with data
      if (ncol(tmp) > 1) {
        names(tmp) <- paste0(av, "_", names(tmp))
        b <- cbind(b, tmp)
        b[[av]] <- NULL
      }
      ## assume not useful data
      if (ncol(tmp) < 1) {
        b[[av]] <- NULL
      }
    }
  }
  b <- data.table(b)
  b <- rm.cols.dups.DT(b)

  ## __ Ignore all intervals data --------------------------------------------
  # data$INTERVALS

  ## __ TAGS data ------------------------------------------------------------
  c <- rm.cols.dups.DT(c)

  ## __ combine data ---------------------------------------------------------
  stopifnot(length(intersect(names(a), names(b))) == 0)
  a <- cbind(a, b)
  rm(b)

  stopifnot(length(intersect(names(a), names(c))) == 0)
  a <- cbind(a, c)
  rm(c)

  ## Process Data ------------------------------------------------------------
  a$activity_date <- NULL
  a$activity_crc  <- NULL

  ## __ Fix multicolumn names ------------------------------------------------
  grep("_[0-9]", names(a), value = T)

  ## __ Covert to numeric ----------------------------------------------------
  for (ac in names(a)[sapply(a, is.character)]) {
    ## clean text first
    a[[ac]] <- sub("[ ]*$",        "", a[[ac]])
    a[[ac]] <- sub("^[ ]*",        "", a[[ac]])
    a[[ac]] <- sub("^[ ]*$",       NA, a[[ac]])
    a[[ac]] <- sub("^[ ]*NA[ ]*$", NA, a[[ac]])
    ## to numeric
    test <- as.numeric(a[[ac]])
    if (!all(is.na(test))) {
      a[[ac]] <- test
    }
  }


  ## __ Drop zeros on some columns -------------------------------------------
  wecare <- unique(c(
    grep("EOA",             names(a), value = TRUE, ignore.case = TRUE),
    grep("Feel",            names(a), value = TRUE, ignore.case = TRUE),
    grep("HRV",             names(a), value = TRUE, ignore.case = TRUE),
    grep("Heart",           names(a), value = TRUE, ignore.case = TRUE),
    grep("IF",              names(a), value = TRUE, ignore.case = TRUE),
    grep("LNP",             names(a), value = TRUE, ignore.case = TRUE),
    grep("RPE",             names(a), value = TRUE, ignore.case = TRUE),
    grep("RTP",             names(a), value = TRUE, ignore.case = TRUE),
    grep("Recovery_time",   names(a), value = TRUE, ignore.case = TRUE),
    grep("TISS",            names(a), value = TRUE, ignore.case = TRUE),
    grep("VI$",             names(a), value = TRUE, ignore.case = TRUE),
    grep("Weight",          names(a), value = TRUE, ignore.case = TRUE),
    grep("_sustained_Time", names(a), value = TRUE, ignore.case = TRUE),
    grep("balance",         names(a), value = TRUE, ignore.case = TRUE),
    grep("best",            names(a), value = TRUE, ignore.case = TRUE),
    grep("bikeintensity",   names(a), value = TRUE, ignore.case = TRUE),
    grep("bikescore",       names(a), value = TRUE, ignore.case = TRUE),
    grep("bikestress",      names(a), value = TRUE, ignore.case = TRUE),
    grep("cadence",         names(a), value = TRUE, ignore.case = TRUE),
    grep("cadence",         names(a), value = TRUE, ignore.case = TRUE),
    grep("calories",        names(a), value = TRUE, ignore.case = TRUE),
    grep("carrying",        names(a), value = TRUE, ignore.case = TRUE),
    grep("cc",              names(a), value = TRUE, ignore.case = TRUE),
    grep("cp",              names(a), value = TRUE, ignore.case = TRUE),
    grep("daniels",         names(a), value = TRUE, ignore.case = TRUE),
    grep("daniels_points",  names(a), value = TRUE, ignore.case = TRUE),
    grep("detected",        names(a), value = TRUE, ignore.case = TRUE),
    grep("distance",        names(a), value = TRUE, ignore.case = TRUE),
    grep("duration",        names(a), value = TRUE, ignore.case = TRUE),
    grep("effect",          names(a), value = TRUE, ignore.case = TRUE),
    grep("efficiency",      names(a), value = TRUE, ignore.case = TRUE),
    grep("estimated",       names(a), value = TRUE, ignore.case = TRUE),
    grep("fatigue_index",   names(a), value = TRUE, ignore.case = TRUE),
    grep("govss",           names(a), value = TRUE, ignore.case = TRUE),
    grep("heart_rate",      names(a), value = TRUE, ignore.case = TRUE),
    grep("in_Zone$",        names(a), value = TRUE, ignore.case = TRUE),
    grep("iwf",             names(a), value = TRUE, ignore.case = TRUE),
    grep("length",          names(a), value = TRUE, ignore.case = TRUE),
    grep("pace",            names(a), value = TRUE, ignore.case = TRUE),
    grep("pacing_index",    names(a), value = TRUE, ignore.case = TRUE),
    grep("peak_Hr$",        names(a), value = TRUE, ignore.case = TRUE),
    grep("peak_Pace",       names(a), value = TRUE, ignore.case = TRUE),
    grep("peak_Power_HR",   names(a), value = TRUE, ignore.case = TRUE),
    grep("peak_WPK$",       names(a), value = TRUE, ignore.case = TRUE),
    grep("power",           names(a), value = TRUE, ignore.case = TRUE),
    grep("ratio",           names(a), value = TRUE, ignore.case = TRUE),
    grep("relative",        names(a), value = TRUE, ignore.case = TRUE),
    grep("response",        names(a), value = TRUE, ignore.case = TRUE),
    grep("skiba",           names(a), value = TRUE, ignore.case = TRUE),
    grep("speed",           names(a), value = TRUE, ignore.case = TRUE),
    grep("temp",            names(a), value = TRUE, ignore.case = TRUE),
    grep("time.",           names(a), value = TRUE, ignore.case = TRUE),
    grep("vdot",            names(a), value = TRUE, ignore.case = TRUE),
    grep("w_bal_",          names(a), value = TRUE, ignore.case = TRUE),
    grep("watts",           names(a), value = TRUE, ignore.case = TRUE),
    grep("weight",          names(a), value = TRUE, ignore.case = TRUE),
    grep("work",            names(a), value = TRUE, ignore.case = TRUE),
    grep("xpower",          names(a), value = TRUE, ignore.case = TRUE),
    NULL))

  a <- data.table(a)
  for (avar in wecare) {
    a[[avar]][a[[avar]] == 0] <- NA
  }
  a <- rm.cols.dups.DT(a)


  ## __ Fix temperatures NA --------------------------------------------------
  wecare <- grep("_temp", names(a), value = TRUE)
  for (avar in wecare) {
    a[[avar]][a[[avar]] < -250 ] <- NA
  }


  ## __ Make uniform names ---------------------------------------------------
  # remove spaces from names
  names(a) <- gsub(" ", "_", names(a))
  # capitalize first letter
  names(a) <- sub("^(\\w?)",   "\\U\\1", names(a), perl = TRUE)
  # capitalize words after _
  names(a) <- gsub("_(\\w?)", "_\\U\\1", names(a), perl = TRUE)


  #### Fill missing data from other fields -----------------------------------

  # wecare <- c("Date","Sport",grep("heart|_hr_" ,names(a),ignore.case = T, value = T),"Overrides")
  # test <- a[ grepl("average_hr", Overrides), ..wecare]

  # wecare <- c("Date","Sport",grep("calories" ,names(a),ignore.case = T, value = T),"Overrides")
  # test <- a[ grepl("total_kcalories", Overrides), ..wecare]

  # wecare <- c("Date","Sport",grep("distance" ,names(a),ignore.case = T, value = T),"Overrides")
  # test   <- a[ grepl("total_distance", Overrides), ..wecare]
  # test2  <- a[!is.na(Distance), ..wecare]

  ## ??
  # wecare <- c("Date","Sport",grep("work" ,names(a),ignore.case = T, value = T),"Overrides")
  # test   <- a[ grepl("total_work", Overrides), ..wecare]
  # test2  <- a[!is.na(Work), ..wecare]

  ## ??
  # wecare <- c("Date","Sport",grep("_time|duration" ,names(a),ignore.case = T, value = T),"Overrides")
  # test   <- a[ grepl("workout_time", Overrides), ..wecare]
  # test2  <- a[!is.na(Duration), ..wecare]
  # plot(a$Duration, a$Workout_Time)

  # unique(unlist(strsplit(unique(a$Overrides), ",")))

  ## We assume the manual override values are always more correct
  ## I am not sure about GC logic of this field, may be is not in use in 3.6
  a[!is.na(Average_Heart_Rate) & grepl("average_hr", Overrides), Average_Hr_V1   := Average_Heart_Rate]
  a[, Average_Heart_Rate := NULL]
  a[!is.na(Calories)      & grepl("total_kcalories", Overrides), Total_Kcalories := Calories          ]
  a[, Calories           := NULL]
  a[!is.na(Distance)      & grepl("total_distance",  Overrides), Total_Distance  := Distance          ]
  a[, Distance           := NULL]

  a[, Weekday            := NULL]
  a[, Year               := NULL]
  a[, Weight             := NULL]


  ## __ Remove duplicate columns  --------------------------------------------
  col.checksums <- sapply(a, function(x) digest::digest(x, "md5"), USE.NAMES = T)
  dup.cols      <- data.table(col.name = names(col.checksums), hash.value = col.checksums)

  for (hh in unique(dup.cols$hash.value)) {
    dups <- dup.cols[hash.value == hh]
    if (nrow(dups) > 1) {
      cat("DUPS:", dups$col.name,"\n")
      dnames <- dups$col.name
      ## arrange priority to keep
      dnames <- c(grep("_V[0-9]", dnames, value = T, invert = T),
                  grep("_V[0-9]", dnames, value = T, invert = F))
      ## keep the first
      remove <- dnames[2:length(dnames)]
      ## drop the rest
      for (re in remove) { a[[re]] <- NULL }
    }
  }


  ## __ Remove columns without actual data -----------------------------------
  for (at in names(a)) {
    uni1 <- unique(a[[at]])
    uni  <- uni1[!uni1 %in% c(NA, 0)]
    ## only containing the same value except NA and 0
    if (length(uni) <= 1) {
      cat("NO VAR:", at, "\n")
      a[[at]] <- NULL
    }
  }


  ## __ Info on low variation columns  ---------------------------------------
  noplot <- c()
  for (at in names(a)) {
    uni1 <- unique(a[[at]])
    uni  <- uni1[!uni1 %in% c(NA, 0)]
    if (length(uni) < 5) {
      cat("\nColumn with low variation:", at, "\n")
      print(table(a[[at]]))
      noplot <- c(noplot, at)
    }
  }


  ## __ Create some new metrics  ---------------------------------------------
  a$Intensity_TRIMP       <- a$Trimp_Points       / a$Workout_Time
  a$Intensity_TRIMP_Zonal <- a$Trimp_Zonal_Points / a$Workout_Time
  a$Intensity_EPOC        <- a$EPOC               / a$Workout_Time
  a$Intensity_Calories    <- a$Total_Kcalories    / a$Workout_Time

  ## another load calculation
  a[, Load_2 := 0.418 * (( (Workout_Time / 3600) * Average_Hr_V1 ) + (2.5 * Average_Hr_V1)) ]


  ## __ Check sport consistency ----------------------------------------------

  a[grepl("bike", Workout_Code) & Sport == "Bike" ]

  a[Sport == "Bike", .(Date, Total_Distance, Total_Kcalories, Sport, Workout_Code)]
  a[Sport == "Run" , .(Date, Total_Distance, Total_Kcalories, Sport, Workout_Code)]

  a[Sport == "Bike" & !grepl("Bike",Workout_Code), .(Date, Total_Distance, Total_Kcalories, Sport, Workout_Code)]

  a[Sport == "Bike", table(Workout_Code, exclude = F)]
  a[Sport == "Run",  table(Workout_Code, exclude = F)]
  a[Sport == "Run",  table(Shoes,        exclude = F)]

  a[Sport == "Run" & is.na(Shoes), .(Date, Total_Distance, Shoes, Sport, Workout_Code)]
  a[Sport == "Run" & Shoes == "?", .(Date, Total_Distance, Shoes, Sport, Workout_Code)]

  table(a$Sport)
  table(a$Workout_Code)
  table(a$Workout_Title)


  ## Add graph options -------------------------------------------------------

  ## Set colors
  a[Sport == "Bike", Col := "red" ]
  a[Sport == "Run",  Col := "blue"]

  ## Set points
  a[, Pch :=  1 ]

  a[Workout_Code == "Bike Road",       Pch :=  6]
  a[Workout_Code == "Bike Dirt",       Pch :=  1]
  a[Workout_Code == "Bike Static",     Pch :=  4]
  a[Workout_Code == "Bike Elliptical", Pch :=  4]
  a[Workout_Code == "Run Hills",       Pch :=  1]
  a[Workout_Code == "Run Track",       Pch :=  6]
  a[Workout_Code == "Run Trail",       Pch :=  8]
  a[Workout_Code == "Run Race",        Pch :=  9]
  a[Workout_Code == "Walk",            Pch :=  0]
  a[Workout_Code == "Walk Hike Heavy", Pch :=  7]
  a[Workout_Code == "Walk Hike",       Pch := 12]

  table(a$Pch)

  grep("Run|Walk", unique(a$Workout_Code), ignore.case = T, value = T)
  grep("Bike",     unique(a$Workout_Code), ignore.case = T, value = T)

  ## __ Drop sort term metrics  ----------------------------------------------
  wecare <- grep("^[0-9]s_", names(a), value = T)
  for (av in wecare) {
    cat("Drop sort term column:", av, "\n")
    a[[av]] <- NULL
  }



  ##  STORE DATA  ------------------------------------------------------------
  write_RDS(a, file = storagefl, clean = TRUE)


  ## __ Don't plot some metrics  ---------------------------------------------
  wecare <- grep("^[0-9]+s_",                         names(a), value = T)
  wecare <- unique(c(wecare, grep("^[0-9]m_" ,        names(a), value = T)))
  wecare <- unique(c(wecare, grep("Best_[0-9]{2,3}m", names(a), value = T)))
  wecare <- unique(c(wecare, grep("Compatibility" ,   names(a), value = T)))
  wecare <- unique(c(wecare, grep("_V2$|_V3$",        names(a), value = T)))
  wecare <- unique(c(wecare, grep("_Temp",            names(a), value = T)))
  wecare <- unique(c(wecare, grep("Time_Riding",      names(a), value = T)))
  wecare <- unique(c(wecare, grep("Time_In_Zone",     names(a), value = T)))
  wecare <- unique(c(wecare, grep("time_In_Zone",     names(a), value = T)))
  wecare <- unique(c(wecare, grep("^10m_" ,           names(a), value = T)))
  wecare <- unique(c(wecare, grep("1000m|1500m|2000m|3000m|4000m", names(a), value = T)))
  wecare <- unique(c(wecare, grep("Zone_P",           names(a), value = T)))
  wecare <- unique(c(wecare, grep("Peak_Wpk",         names(a), value = T)))
  wecare <- unique(c(wecare, grep("work_In_Zone",     names(a), value = T)))

  for (av in sort(wecare)) {
    cat("Drop sort term column from plot:", av, "\n")
    a[[av]] <- NULL
  }

  sort(names(a)[!sapply(a, is.character)])


  ## __ PLOT ALL DATA  -------------------------------------------------------
  wecare <- names(a)[!sapply(a, is.character)]
  wecare <- grep("date|filename|parsed|Col|Pch|sport|bike|shoes|CP_setting|workout_code|Year|Duration|Time_Moving|Dropout_Time|Distance_Swim|Heartbeats",
                 wecare, ignore.case = T, value = T, invert = T)
  wecare <- unique(wecare[!wecare %in% noplot])
  wecare <- sort(wecare)

  #### find few data cases ---------------------------------------------------
  # test <- sapply(a[, ..wecare], function(x) sum(!is.na(x)) )
  # test[test < 10]

  ## __ Plot all variables ---------------------------------------------------
  if (!interactive()) {
    pdf(file = pdfout1, width = 8, height = 4)
  }

  par(mar = c(4,4,1,1))

  plot(a$EPOC, a$Trimp_Points,
       col  = a$Col, pch  = a$Pch, cex  = 0.6,
       xlab = "EPOC", ylab = "TRIMP")

  plot(a$EPOC, a$Trimp_Zonal_Points,
       col  = a$Col, pch  = a$Pch, cex  = 0.6,
       xlab = "EPOC", ylab = "TRIMP Zonal")

  plot(a$Trimp_Points, a$Trimp_Zonal_Points,
       col  = a$Col, pch  = a$Pch, cex  = 0.6,
       xlab = "TRIMP", ylab = "TRIMP Zonal")

  plot(a$Total_Kcalories, a$Trimp_Points,
       col  = a$Col, pch  = a$Pch, cex  = 0.6)
  plot(a$Total_Kcalories, a$Trimp_Zonal_Points,
       col  = a$Col, pch  = a$Pch, cex  = 0.6)
  plot(a$Total_Kcalories, a$EPOC,
       col  = a$Col, pch  = a$Pch, cex  = 0.6)

  plot(a$Workout_Time,   a$Trimp_Points / a$EPOC,
       col  = a$Col, pch  = a$Pch, cex  = 0.6)

  # plot(a$Total_Distance, a$Trimp_Points / a$EPOC,
  #      col  = a$Col, pch  = a$Pch, cex  = 0.6)



  ### how column exist?
  grep("istanc",names(a),ignore.case = T,value = T)
  # plot(a$Total_Distance, a$Distance,
  #      col  = a$Col, pch  = a$Pch, cex  = 0.6)

  # plot(a$Workout_Time, a$Time_Recording,
  #      col  = a$Col, pch  = a$Pch, cex  = 0.6,)
  # plot(a$Workout_Time, a$Time_Carrying,
  #      col  = a$Col, pch  = a$Pch, cex  = 0.6,)
  # plot(a$Workout_Time, a$Time_Riding,
  #      col  = a$Col, pch  = a$Pch, cex  = 0.6,)
  # plot(a$Workout_Time, a$Time_Moving,
  #      col  = a$Col, pch  = a$Pch, cex  = 0.6,)


  for (avar in wecare) {
    ## ignore no data
    if (all(as.numeric(a[[avar]]) %in% c(0, NA))) {
      cat(paste("Skip plot 0 or NA:", avar),"\n")
      next()
    }

    if (sum(!is.na(a[[avar]])) < DATA_PLOT_LIMIT) {
      cat(paste("Skip plot few points:", avar),"\n")
      next()
    }


    par(mar = c(2,2,1,1))

    rm   <- frollmean(a[[avar]], n = 30, hasNA = T, na.rm = T, algo = "exact" )
    ylim <- range(rm,a[[avar]], na.rm = T)

    ## regression my month
    ## fails when all is na in a group
    # lms <- a[,
    #          .(model1 = list( lm(get(avar)~Date, .SD, na.action = na.omit) )),
    #            by = .(year(Date), month(Date)) ]
    #
    # lms <- a[,
    #          .(model1 = if (!all(is.na(.SD[[avar]]))) {list(lm(get(avar)~Date, .SD, na.action = na.omit))} else {NULL}),
    #          by = .(year(Date), month(Date)) ]

    plot(a$Date, a[[avar]],
         col  = a$Col,
         pch  = a$Pch,
         cex  = 0.6,
         xlab = "", ylab = "")

    lines(a$Date, rm, col = "green")

    ## create lm with loops
    pp <- a[, .(Date, get(avar), month = month(Date), year = year(Date))]
    for (ay in unique(pp$year)) {
      tmp <- pp[year == ay, ]
      if ( sum(!is.na(tmp$V2)) > 1) {
        mlm    <- lm(V2 ~ Date, tmp, na.action = na.omit)
        Dstart <- as.POSIXct(strptime(paste(ay, "1", "1"), "%Y %m %d"))
        Dend   <- as.POSIXct(add_with_rollback(Dstart, months(1)))
        res    <- predict(mlm, data.table(Date = c(Dstart,Dend)))
        segments(x0 = Dstart, x1 = Dend, y0 = res[1], y1 = res[2], col = "grey")
      }
    }

    ## LOESS curve
    vec <- !is.na(a[[avar]])
    if (sum(vec) > 20) {
      FTSE.lo3 <- loess.as(a$Date[vec], a[[avar]][vec],
                           degree = 1,
                           criterion = LOESS_CRITERIO, user.span = NULL, plot = F)
      FTSE.lo.predict3 <- predict(FTSE.lo3, a$Date)
      lines(a$Date, FTSE.lo.predict3, col = "cyan", lwd = 1)
    }



    abline(v = as.numeric(unique(round(a$Date, "month"))),
           lty = 3, col = "lightgray")
    abline(h = pretty(a[[avar]]),
           lty = 3, col = "lightgray")

    title(avar)
  }

  dev.off()


  ## __  PLOT LAST -----------------------------------------------------------
  a <- a[ as.Date(Date) > (Sys.Date() - LASTDAYS) ]
  if (!interactive()) {
    pdf(file = pdfout2, width = 8, height = 4)
  }

  par(mar = c(4,4,1,1))

  plot(a$EPOC, a$Trimp_Points,
       col  = a$Col, pch  = a$Pch, cex  = 0.6,
       xlab = "EPOC", ylab = "TRIMP")

  plot(a$EPOC, a$Trimp_Zonal_Points,
       col  = a$Col, pch  = a$Pch, cex  = 0.6,
       xlab = "EPOC", ylab = "TRIMP Zonal")

  plot(a$Trimp_Points, a$Trimp_Zonal_Points,
       col  = a$Col, pch  = a$Pch, cex  = 0.6,
       xlab = "TRIMP", ylab = "TRIMP Zonal")

  plot(a$Total_Kcalories, a$Trimp_Points,
       col  = a$Col, pch  = a$Pch, cex  = 0.6)
  plot(a$Total_Kcalories, a$Trimp_Zonal_Points,
       col  = a$Col, pch  = a$Pch, cex  = 0.6)
  plot(a$Total_Kcalories, a$EPOC,
       col  = a$Col, pch  = a$Pch, cex  = 0.6)

  plot(a$Workout_Time,   a$Trimp_Points / a$EPOC,
       col  = a$Col, pch  = a$Pch, cex  = 0.6)

  plot(a$Total_Distance, a$Trimp_Points / a$EPOC,
       col  = a$Col, pch  = a$Pch, cex  = 0.6)



  ### how column exist?
  grep("istanc",names(a),ignore.case = T,value = T)
  # plot(a$Total_Distance, a$Distance,
  #      col  = a$Col, pch  = a$Pch, cex  = 0.6)

  # plot(a$Workout_Time, a$Time_Recording,
  #      col  = a$Col, pch  = a$Pch, cex  = 0.6,)
  # plot(a$Workout_Time, a$Time_Carrying,
  #      col  = a$Col, pch  = a$Pch, cex  = 0.6,)
  # plot(a$Workout_Time, a$Time_Riding,
  #      col  = a$Col, pch  = a$Pch, cex  = 0.6,)
  # plot(a$Workout_Time, a$Time_Moving,
  #      col  = a$Col, pch  = a$Pch, cex  = 0.6,)


  for (avar in wecare) {
    ## ignore no data
    if (all(as.numeric(a[[avar]]) %in% c(0, NA))) {
      cat(paste("Skip plot 0 or NA:", avar),"\n")
      next()
    }

    if (sum(!is.na(a[[avar]])) < DATA_PLOT_LIMIT) {
      cat(paste("Skip plot few points:", avar),"\n")
      next()
    }


    par(mar = c(2, 2, 1, 1))

    rm   <- frollmean(a[[avar]], n = 30, hasNA = T, na.rm = T, algo = "exact" )
    ylim <- range(rm,a[[avar]], na.rm = T)

    ## regression my month
    ## fails when all is na in a group
    # lms <- a[,
    #          .(model1 = list( lm(get(avar)~Date, .SD, na.action = na.omit) )),
    #            by = .(year(Date), month(Date)) ]
    #
    # lms <- a[,
    #          .(model1 = if (!all(is.na(.SD[[avar]]))) {list(lm(get(avar)~Date, .SD, na.action = na.omit))} else {NULL}),
    #          by = .(year(Date), month(Date)) ]

    plot(a$Date, a[[avar]],
         col  = a$Col,
         pch  = a$Pch,
         cex  = 0.6,
         xlab = "", ylab = "")

    lines(a$Date, rm, col = "green")

    ## create lm with loops
    pp <- a[, .(Date, get(avar), month = month(Date), year = year(Date))]
    for (ay in unique(pp$year)) {
      for (am in unique(pp$month)) {
        tmp <- pp[year == ay & month == am, ]
        if ( sum(!is.na(tmp$V2)) > 1) {
          mlm    <- lm(V2 ~ Date, tmp, na.action = na.omit)
          Dstart <- as.POSIXct(strptime(paste(ay, am, "1"), "%Y %m %d"))
          Dend   <- as.POSIXct(add_with_rollback(Dstart, months(1)))
          res    <- predict(mlm, data.table(Date = c(Dstart,Dend)) )
          segments(x0 = Dstart, x1 = Dend, y0 = res[1], y1 = res[2], col = "grey")
        }
      }
    }

    abline(v = as.numeric(unique(round(a$Date, "month"))),
           lty = 3, col = "lightgray")
    abline(h = pretty(a[[avar]]),
           lty = 3, col = "lightgray")

    ## LOESS curve
    vec <- !is.na(a[[avar]])
    if (sum(vec) > 20) {
      FTSE.lo3 <- loess.as(a$Date[vec], a[[avar]][vec],
                           degree = 1,
                           criterion = LOESS_CRITERIO, user.span = NULL, plot = F)
      FTSE.lo.predict3 <- predict(FTSE.lo3, a$Date)
      lines(a$Date, FTSE.lo.predict3, col = "cyan", lwd = 1)
    }

    title(avar)
  }

  dev.off()

  ## save make info
  Rmk_store_dependencies()

} else {
  cat("Don't have to run", Script.Name, "\n")
}


####_ END _####
tac <- Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
