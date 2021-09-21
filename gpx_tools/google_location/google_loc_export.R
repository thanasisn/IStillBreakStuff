#!/usr/bin/env Rscript

#'
#' #### Export Google location history to RDS
#' - Try to characterize points by main activity
#'

#### _ Set environment _ ####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()
# if(!interactive())pdf(file=sub("\\.R$",".pdf",Script.Name))
sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)


library(jsonlite)
library(data.table)
library(dplyr)
library(myRtools)
library(arrow)


## time distance for activity characterization
ACTIVITY_MATCH_THRESHOLD <- 60*3

## Data export path
basedir  <- "~/DATA_RAW/Other/GLH/"



#### _ Main _ ####

####  Read and prepare data  ####

## This is a big file to read
locations <- data.table(fromJSON("~/LOGs/Takeout/Location History/Location History.json"))
locations <- data.table(locations[[1]][[1]])

## proper dates
locations[, Date := as.POSIXct(as.numeric(timestampMs)/1000, tz='GMT', origin='1970-01-01') ]
locations[, timestampMs := NULL]

## proper coordinates
locations[, Lat         := latitudeE7  / 1e7 ]
locations[, Long        := longitudeE7 / 1e7 ]
locations[, latitudeE7  := NULL]
locations[, longitudeE7 := NULL]

## clean data coordinates
locations[ Long == 0, Long := NA ]
locations[ Lat  == 0, Lat  := NA ]
locations <- locations[ !is.na(Long) ]
locations <- locations[ !is.na(Lat)  ]
locations <- locations[ abs(Lat)  <  89.9999 ]
locations <- locations[ abs(Long) < 179.9999 ]

## list groups of activities
unique(locations$activity)

time.rds      <- system.time({})
time.hdf      <- system.time({})
time.feather  <- system.time({})
time.feather2 <- system.time({})
time.parquet  <- system.time({})
####  Export daily data  ####
## also try to use the main activity to characterize points
for (aday in unique(as.Date(locations$Date))) {
    daydata <- locations[ as.Date(Date) == aday  ]
    ## This sorting will hide dating errors
    ## we can assume that data point are already sorted
    ## but is that always true?
    setorder(daydata, Date)
    today   <- as.Date(daydata[1,Date])
    cat(paste("Working on:", today, "  points:", nrow(daydata)),"\n")

    ydirec <- paste0(basedir, year(daydata[1,Date]), "/" )
    dir.create(ydirec,showWarnings = F)

    ## get activities characterization
    activities <- daydata$activity
    sel        <- sapply(activities, function(x) !is.null(x[[1]]))
    activities <- activities[sel]
    df3        <- do.call("bind_rows", activities)


    main_activity <- sapply(df3$activity, function(x) x[[1]][1][[1]][1])
    activities_2  <- data.table(main_activity = main_activity,
                                time          = as.POSIXct(as.numeric(df3$timestampMs)/1000, origin = "1970-01-01"))
    setorder(activities_2, time)

    ## match activities
    activities_2$main_activity <- factor(activities_2$main_activity)

    ## find nearest
    mi <- nearest( target =  as.numeric(activities_2$time),
                   probe  =  as.numeric(daydata$Date ))

    ## add possible main activity to each record
    daydata$main_activity <- activities_2$main_activity[mi]

    ## apply a time threshold of validity for main activity
    not_valid_idx <- which( as.numeric(abs(activities_2$time[mi] - daydata$Date)) > ACTIVITY_MATCH_THRESHOLD  )
    daydata$main_activity[ not_valid_idx ] <- "UNKNOWN"

    cat(print(table(daydata$main_activity)),"\n")
    cat("\n")

    ## clean table
    daydata$activity         <- NULL
    daydata$locationMetadata <- NULL


    attributes(daydata) <- c()


    file <- path.expand(paste0(ydirec,"GLH_",today,".Rds"))
    time.rds <- time.rds + system.time({
        write_RDS(object = daydata,
                  file = file)
        ss<-readRDS(file)

        attributes(ss)


    })


    file <- path.expand(paste0(ydirec,"GLH_",today,".dat"))
    write_dat(object = daydata,
              file = file)

    memCompress()


    attributes(ss)

    file <- path.expand(paste0(ydirec,"GLH_",today,".prqt"))
    time.parquet <- time.parquet + system.time({
        arrow::write_parquet( daydata, file, compression = 'zstd', compression_level = 9)
        arrow::read_parquet(file)
    })

    # file <- path.expand(paste0(ydirec,"GLH_",today,".fthr"))
    # time.feather <- time.feather + system.time({
    #     arrow::write_feather( daydata, file, compression = 'zstd', compression_level = 9)
    #     arrow::read_feather(file)
    # })

    cat(paste("RDS      :"))
    cat(paste(signif(time.rds,digits = 10)),"\n")
    cat(paste("parquet  :"))
    cat(paste(signif(time.parquet,digits = 10)),"\n")
    # cat(paste("feather  :"))
    # cat(paste(signif(time.feather,digits = 10)),"\n")
    #
    #

    stop("test")



library(myRtools)



}

####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
