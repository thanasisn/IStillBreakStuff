#!/usr/bin/env Rscript

#### Gather and store gpx track points systematically.
## Will be processed by other scripts
## This gather all track points, filenames and mtime


####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()
if(!interactive())pdf(file=sub("\\.R$",".pdf",Script.Name))
sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)

library(sf)
library(dplyr)
library(data.table)
library(trip)
library(myRtools)
library(R.utils)

## read vars
source("~/CODE/gpx_tools/gpx_db/DEFINITIONS.R")

## You can turn warnings into errors with:
# options(warn=2)
options(warn=1)

## TODO add compressed gpx files or use fit files

## gather all gpx files
gpxlist <- c()
for (ar in gpx_repos) {
    templist  <- list.files(path        = ar,
                            pattern     = ".gpx$",
                            recursive   = T,
                            full.names  = T,
                            ignore.case = T)
    gpxlist <- unique(c(gpxlist, templist))
}

## add compressed data files
traincomplist <- list.files("~/TRAIN/GoldenCheetah/Athan/imports/",
                            pattern = "activity.*.gz",
                            full.names = T)
gpxlist <- unique(c(gpxlist, traincomplist))

read_sf(gunzip(traincomplist[1], remove = FALSE, temporary = TRUE, skip = TRUE ), layer = "track_points")
read_sf(gunzip(gpxlist[1], remove = FALSE, temporary = TRUE, skip = TRUE ), layer = "track_points")

## exclude some files
# gpxlist <- gpxlist[grep("orig", basename(gpxlist), ignore.case = TRUE, invert = T)]


## load or start a new data table
if (file.exists(trackpoints_fl)) {
    ## load old data
    data <- readRDS(trackpoints_fl)
    ## remove missing files
    data <- data[ file.exists(filename) ]
    ## get parsed files
    dblist <- unique( data[, c("filename","F_mtime")] )
    ## get all files
    fllist <- data.frame(file = gpxlist,
                         F_mtime = file.mtime(gpxlist))
    ## files to do
    ddd <- anti_join( fllist, dblist )

    ## check for changed files
    ##FIXME  not tested
    data <- data[ ! filename %in% ddd$filename ]

    gpxlist <- ddd$filename

} else {
    data <- data.table()
}


cnt   <- 0
total <- length(gpxlist)

for (af in gpxlist) {
    cnt <- cnt + 1
    if (!file.exists(af)) { next() }
    cat(paste(cnt,total,af,"\n"))

    ## get all points
    # temp <- read_sf(af, layer = "track_points")
    ## read both gz and regular files
    temp <- read_sf( gunzip(af, remove = FALSE, temporary = TRUE, skip = TRUE ),
                     layer = "track_points")


    ## This assumes that dates in file are correct.......
    temp <- temp[ order(temp$time, na.last = FALSE), ]
    if (nrow(temp)<2) { next() }

    ## keep initial coordinates
    latlon <- st_coordinates(temp$geometry)
    latlon <- data.table(latlon)
    names(latlon)[names(latlon)=="X"] <- "Xdeg"
    names(latlon)[names(latlon)=="Y"] <- "Ydeg"

    ## add distance between points in meters
    temp$dist <- c(0, trackDistance(st_coordinates(temp$geometry), longlat = TRUE)) * 1000

    ## add time between points
    temp$timediff <- 0
    for (i in 2:nrow(temp)) {
        temp$timediff[i] <- difftime( temp$time[i], temp$time[i-1] )
    }

    # st_crs(EPSG)
    ## parse coordinates for process in meters
    temp   <- st_transform(temp, crs = EPSG)
    trkcco <- st_coordinates(temp)
    temp   <- data.table(temp)
    temp$X <- unlist(trkcco[,1])
    temp$Y <- unlist(trkcco[,2])
    temp   <- cbind(temp, latlon)

    ## data to keep
    temp   <- temp[, .(time,X,Y,Xdeg,Ydeg,dist,timediff, filename = af, F_mtime = file.mtime(af))]

    ## some files don't have tracks
    if (!nrow(temp)>0) { next() }
    data <- rbind(data,temp)

    ## partial write
    if (cnt %% 40 == 0) {
        # write_RDS(data, trackpoints_fl)
        saveRDS(data, trackpoints_fl)
    }
}
## final write
# write_RDS(data, trackpoints_fl)
saveRDS(data, trackpoints_fl, compress = "xz")


####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
