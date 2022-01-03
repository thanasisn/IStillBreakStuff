#!/usr/bin/env Rscript

####  Gather and store track points from Google location with activities data.

# https://developers.google.com/android/reference/com/google/android/gms/location/DetectedActivity


#### _ Set environment _ ####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()
# if(!interactive())pdf(file=sub("\\.R$",".pdf",Script.Name))
# sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)


library(data.table)
library(sf)
library(myRtools)
library(trip)

## time distance for activity characterization
ACTIVITY_MATCH_THRESHOLD <- 60*3
ACCURACY_LIMIT           <- 5000
EPSG                     <- 3857

## Data path
basedir  <- "~/DATA_RAW/Other/GLH/"
outfile  <- paste0(basedir,"/Count_GlL_3857.Rds")




filelist <- list.files( path       = basedir ,
                        pattern    = "[0-9]{4}.*\\.Rds",
                        recursive  = T,
                        full.names = T)
filelist <- grep("/[0-9]{4}/",filelist,value = T)

## Parse all available data
gather <- data.table()
for (af in filelist) {

    cat(paste("Parse", basename(af)),"\n")
    tempd <- readRDS(af)

    ## drop some data
    tempd[, deviceTag        := NULL]
    tempd[, activity         := NULL]
    tempd[, locationMetadata := NULL]
    tempd[, heading          := NULL]
    tempd[, platform         := NULL]
    tempd[, platformType     := NULL]

    ## create proper spatial data
    names(tempd)[names(tempd) == "Date"] <- "time"
    temp <- st_as_sf(tempd, coords = c("Long","Lat"),crs = st_crs(4326) )

    ## keep initial coordinates
    latlon <- st_coordinates(temp$geometry)
    latlon <- data.table(latlon)
    names(latlon)[names(latlon)=="X"] <- "Xdeg"
    names(latlon)[names(latlon)=="Y"] <- "Ydeg"

    temp$timediff <- 0
    if (nrow(temp)>1){
        ## add distance between points in meters
        temp$dist <- c(0, trackDistance(st_coordinates(temp$geometry), longlat = TRUE)) * 1000
        ## add time between points
        for (i in 2:nrow(temp)) {
            temp$timediff[i] <- difftime( temp$time[i], temp$time[i-1] )
        }
    } else {
        temp$dist <- NA
    }

    ## parse coordinates for process in meters
    temp   <- st_transform(temp, crs = EPSG)
    trkcco <- st_coordinates(temp)
    temp   <- data.table(temp)
    temp$X <- unlist(trkcco[,1])
    temp$Y <- unlist(trkcco[,2])
    temp   <- cbind(temp, latlon)


    temp$file    <- af
    temp$F_mtime <- file.mtime(af)

    gather <- rbind(gather,temp, fill = TRUE)
}



## do some stats

# table(gather$source)
# table(gather$main_activity)
#
#
# gather[, .N, by = .(source, main_activity) ]
#
# acc_cl <- gather[  , .N, by = .(Acur_Class = (gather$accuracy %/% 100) * 100) ]
# setorder(acc_cl)
# acc_cl
#
# alt_cl <- gather[  , .N, by = .(Acur_Class = (gather$altitude %/% 100) * 100) ]
# setorder(alt_cl)
# alt_cl
#
#
# gather[accuracy > ACCURACY_LIMIT , .N, by = .(source, main_activity) ]
# table(gather[accuracy > ACCURACY_LIMIT, year(time) ])
#
#
#
# hist(gather$altitude,breaks = 100)
# hist(gather$accuracy,breaks = 100)
# hist(gather$verticalAccuracy,breaks = 100)
# hist(gather$velocity,breaks = 100)
#
# for (act in unique(gather$main_activity)) {
#     temp <- gather[ main_activity == act,]
#
#     hist(temp$altitude,         breaks = 100)
#     hist(temp$accuracy,         breaks = 100)
#     hist(temp$verticalAccuracy, breaks = 100)
#     hist(temp$velocity,         breaks = 100)
#
#
#     }
#
#
#
# any(duplicated(gather$Date))



####  Clean data  #####
data <- gather[accuracy <= ACCURACY_LIMIT]


# plot( gather$Long, gather$Lat)
# plot( data$Long, data$Lat)






#### Store data ######
saveRDS(data, file = outfile)







####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
