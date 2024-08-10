#!/usr/bin/env Rscript

#### Process track points data
## Filter, aggregate, analyse points and tracks
## Find possible bad or duplicate data
## Create reports

####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/gpx_tools/gpx_db/process_gpx_trk_points.R"

if (!interactive()) {
  dir.create("../runtime/", showWarnings = F, recursive = T)
  pdf( file = paste0("../runtime/", basename(sub("\\.R$",".pdf", Script.Name))))
  sink(file = paste0("../runtime/", basename(sub("\\.R$",".out", Script.Name))),split=TRUE)
}


library(data.table)
library(sf)

## read vars
source("~/CODE/gpx_tools/gpx_db/DEFINITIONS.R")

## google use data from google if no other data within n seconds
google_threshold <- 6 * 60

## TODO find files in bb 23.67452854,39.90723739,23.72368429,39.94759822
## 22.94751066,40.59749471,23.02471994,40.65515229
bb <- c(23.19148951,40.25211520,23.22016370,40.26935524)
# bb <- c(21.67452854,35.90723739,26.72368429,42.94759822)


## load data from gpx gather
DT  <- readRDS(trackpoints_fl)
## drop files dates
DT[ , F_mtime:=NULL]
DT[ time < "1971-01-01", time := NA ]
# DT[ , type := 1]
DT <- DT[ !is.na(time), ]

## load data from google locations
DT2 <- readRDS(goolgepoints_fl)
names(DT2)[names(DT2)=="file"] <- "filename"
DT2[, F_mtime:=NULL]
DT2[ time < "1971-01-01", time := NA ]
# DT2[, type := 2]
DT2 <- DT2[ !is.na(time), ]

## find Google data we should include due to missing data
setorder(DT2, time )
setorder(DT,  time)
near    <- myRtools::nearest(as.numeric( DT2$time),
                             as.numeric( DT$time ))
timdiff <- abs( as.numeric(DT[ near, ]$time - DT2$time))
DT2     <- DT2[ timdiff >= google_threshold ]

## combine data
DT <- rbind(DT, DT2[, names(DT), with =F ] )
DT <- DT[ ! is.na(time) ]
rm(DT2)


hist(DT$time , breaks = 100)

typenames <- c( "Points", "Days", "Hours")


cat(paste( length(unique( DT$file )), "total files parsed\n" ))
cat(paste( nrow( DT ), "points parsed\n" ))

## create speed
DT$kph <- (DT$dist / 1000) / (DT$timediff / 3600)


#### clean problematic data ####
if ( nrow(DT[ is.na(X) |
                is.na(Y) |
                is.infinite(X) |
                is.infinite(Y) |
                !is.numeric(X) |
                !is.numeric(Y)   ]) != 0) {
    cat("\nMissing coordinates!!\n")
    cat("Add some code to fix!!\n")
}








####  Detect possible duplicate files  ####
cat(paste("Get possible duplicate files\n"))

## get files with points in the same date
file_dates <- DT[, .N, by = .(Date = as.Date(time), filename)]
same_date  <- list()
for (ad in unique(file_dates$Date)) {
    ad   <- as.Date(ad, origin = "1970-01-01")
    temp <- file_dates[Date == ad]
    if (nrow(temp) > 1 ) {
        # cat(paste(temp$file),"\n")
        same_date <- c(same_date, list(t(temp$filename)))
    }
}

## check the files if have dups points
dup_points <- data.frame()
for (il in 1:length(same_date)) {

    temp <- DT[ filename %in% same_date[[il]]]

    ## only when we have time
    temp <- temp[ !is.na(time) ]

    setkey(temp, time, X, Y)
    dups <- duplicated(temp, by = key(temp))
    temp[, fD := dups | c(tail(dups, -1), FALSE)]
    duppoints <- temp[fD == TRUE]

    ## files with dups points
    countP <- duppoints[ , .(DupPnts = .N, STime = min(time), ETime = max(time)) , by = .(filename) ]
    countP$TotPnts <- 0
    countP$Set     <- il
    for (af in unique(countP$filename)) {
        countP[ filename == af, TotPnts := DT[ filename == af, .N] ]
    }
    dup_points <- rbind(dup_points, countP)
}

dup_points[, Cover := DupPnts / TotPnts]

cat(paste(nrow(duppoints), "Duplicate points found\n"))

dup_points$STime <- format( dup_points$STime, "%FT%R:%S" )
dup_points$ETime <- format( dup_points$ETime, "%FT%R:%S" )





##  Filter data by speed  ------------------------------------------------------

##TODO
hist(DT$timediff)
hist(DT$dist)
hist(DT$kph)

table((DT$timediff %/% 5) * 5 )
table((DT$dist     %/% 1000) * 1000 )
table(abs(DT$kph   %/% 200) * 200 )

cat(paste("\nGreat distances\n"))
DT[dist > 100000, .( .N, MaxDist = max(dist)) , by = filename]

cat(paste("\nGreat speeds\n"))
DT[kph > 500000 & !is.infinite(kph), .(.N, MaxKph = max(kph), time[which.max(kph)]) , by = filename ]

cat(paste("\nGreat times\n"))
DT[timediff > 600 , .(.N, MaxTDiff = max(timediff), time = time[which.max(timediff)]) , by = filename ]


# esss <- DT[kph > 200, .(file, kph, timediff, dist ,time) ]
# setorder(esss, kph)
# DT[dist > 200, .(max(kph), time[which.max(kph)] ), by = file ]
# DT[timediff==0]
# DT[dist==0 & timediff==0]
# DT[dist>0 & dist < 10 & timediff==0]
# DT[is.infinite(kph), .(max(dist), time[which.max(dist)]) ,by = file]
# DT[dist<0]



##  Bin points in grids  -------------------------------------------------------

## no need for all data for griding
DT[, kph      := NULL]
DT[, timediff := NULL]
DT[, dist     := NULL]
DT[, Xdeg     := NULL]
DT[, Ydeg     := NULL]

## keep only existing coordinates
DT <- DT[ !is.na(X) ]
DT <- DT[ !is.na(Y) ]

cat(paste( length(unique( DT$filename )), "files to bin\n" ))
cat(paste( nrow( DT ), "points to bin\n" ))

## aggregate times
DT[ , time :=  (as.numeric(time) %/% rsltemp * rsltemp) + (rsltemp/2)]
DT[ , time :=  as.POSIXct( time, origin = "1970-01-01") ]



## exclude some data paths not mine
DT <- DT[ grep("/Plans/",   filename, invert = T ), ]
DT <- DT[ grep("/ROUT/",    filename, invert = T ), ]




####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
