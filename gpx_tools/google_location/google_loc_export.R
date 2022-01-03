#!/usr/bin/env Rscript
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### Export Google location history Rds to clean tables in multiple formats
# - Try to characterize points by main activity


#### _ INIT _ ####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()
# if(!interactive())pdf(file=sub("\\.R$",".pdf",Script.Name))
# sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)

library(data.table)
library(dplyr)
library(myRtools)

## time distance for activity characterization
ACTIVITY_MATCH_THRESHOLD <- 60*3

## Raw data location
indir   <- "~/DATA_RAW/Other/GLH/Raw/"
## Temp data location
tempdir <- "/dev/shm/tmp_glh"
## Data export path
outdir  <- "~/DATA/Other/GLH/Yearly"




#### _ MAIN _ ####

dir.create(tempdir, recursive = T, showWarnings = F)
dir.create(outdir,  recursive = T, showWarnings = F)

filestodo <- list.files(path        = indir,
                        pattern     = "GLH_part.*.Rds",
                        ignore.case = TRUE,
                        full.names  = TRUE)
filestodo <- sort(filestodo,decreasing = T)
####  Parse all raw files to yearly files  ####
for ( af in filestodo) {
    cat(paste("Parse:",af),"\n")

    ## read data and prepare
    tempdt <- data.table( readRDS(af) )

    ## get activities characterization
    activities    <- tempdt$activity

    if (!is.null(activities)) {

        sel           <- sapply(activities, function(x) !is.null(x[[1]]))
        activities    <- activities[sel]
        df3           <- do.call("bind_rows", activities)

        main_activity <- sapply(df3$activity, function(x) x[[1]][1][[1]][1])
        activities_2  <- data.table(main_activity = main_activity,
                                    time          = as.POSIXct(as.numeric(df3$timestampMs)/1000, origin = "1970-01-01"))
        setorder(activities_2, time)

        ## match activities
        activities_2$main_activity <- factor(activities_2$main_activity)

        ## find nearest
        mi <- nearest( target =  as.numeric(activities_2$time),
                       probe  =  as.numeric(tempdt$Date ))

        ## add possible main activity to each record
        tempdt$main_activity <- activities_2$main_activity[mi]

        ## apply a time threshold of validity for main activity
        not_valid_idx <- which( as.numeric(abs(activities_2$time[mi] - tempdt$Date)) > ACTIVITY_MATCH_THRESHOLD  )
        tempdt$main_activity[ not_valid_idx ] <- "UNKNOWN"
    }

    # print(table(tempdt$main_activity))
    # cat("\n")

    ## clean table from lists and sub tables
    tempdt[ , activity         := NULL ]
    tempdt[ , locationMetadata := NULL ]
    tempdt[ , deviceTag        := NULL ]
    tempdt[ , heading          := NULL ]
    tempdt[ , platformType     := NULL ]


    ## limit of other export methods to a simple structured data table
    tempdt <- data.table(tempdt)

    ## get years to do
    yearstodo <- unique(year(tempdt$Date))

    for (ay in yearstodo) {
        ## this year file
        yrfl <- paste0(outdir,"/GLH_",ay,".Rds")
        ## check if previous data exist
        if (!file.exists(yrfl)) {
            gather <- data.table()
        } else {
            gather <- data.table(readRDS(yrfl))
        }
        ## gather and save
        gather <- rbind(gather, tempdt, fill = TRUE)
        setorder(gather,Date)
        writeDATA(object = gather,
                  file   = yrfl,
                  clean  = TRUE,
                  type   = "Rds")
    }
    cat("\n")
}

stop("more codding")


####  Read and export yearly data to multiple formats  ####
yearlytodo <- list.files(path       = outdir,
                         pattern    = "GLS_*.Rds",
                         full.names = T )

time.rds      <- system.time({})
time.dat      <- system.time({})
time.parquet  <- system.time({})


for (af in yearlytodo) {
    cat(paste(af),"\n")



}




stop("FF")
iter <- data.table(Date = locations$Date)
# iter <- iter[ , .N , by = .(year(Date), month(Date)) ]
iter <- iter[ , .N , by = .(year(Date)) ]


####  Export daily data  ####
## also try to use the main activity to characterize points
# for (aday in unique(as.Date(locations$Date))) {
    # daydata <- locations[ as.Date(Date) == aday  ]
for ( ii in 1:nrow(iter) ) {
    jj <- iter[ii,]

    # daydata <- locations[ year(Date) == jj$year & month(Date) == jj$month  ]
    daydata <- locations[ year(Date) == jj$year  ]


    ## This sorting will hide dating errors
    ## we can assume that data point are already sorted
    ## but is that always true?
    setorder(daydata, Date)


    today <- sprintf("%04g", jj$year )
    cat(paste("Working on:", today, "  points:", nrow(daydata)),"\n")


    file <- path.expand(paste0(ydirec,"GLH_",today,".Rds"))
    time.rds <- time.rds + system.time({
        writeDATA(object = daydata,
                  file   = file,
                  clean  = FALSE,
                  type   = "Rds")
        ss <- readRDS(file)
    })

    file <- path.expand(paste0(ydirec,"GLH_",today,".dat"))
    time.dat <- time.dat + system.time({
        writeDATA(object = daydata,
                  file   = file,
                  clean  = FALSE,
                  type   = "dat")
        ss <- fread(file)
    })

    daydata <- as.data.frame(daydata)
    file <- path.expand(paste0(ydirec,"GLH_",today,".prqt"))
    time.parquet <- time.parquet + system.time({
        writeDATA(object = daydata,
                  file   = file,
                  clean  = FALSE,
                  type   = "prqt")
        ss <- read_parquet(file)
    })

    all.equal(ss, daydata)


    cat(paste("RDS      :"))
    cat(paste(signif(time.rds,     digits = 4)),"\n")
    cat(paste("parquet  :"))
    cat(paste(signif(time.parquet, digits = 4)),"\n")
    cat(paste("dat      :"))
    cat(paste(signif(time.dat,     digits = 4)),"\n")


    ref <- time.rds
    cat(paste("RDS      :"))
    cat(paste(signif(time.rds/ref,     digits = 4)),"\n")
    cat(paste("parquet  :"))
    cat(paste(signif(time.parquet/ref, digits = 4)),"\n")
    cat(paste("dat      :"))
    cat(paste(signif(time.dat/ref,     digits = 4)),"\n")

}




####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
