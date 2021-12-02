#!/usr/bin/env Rscript

#### Process track points data
## Filter, aggregate, analyze points and tracks
## Find possible bad or duplicate data
## Create reports

####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()
if(!interactive())pdf(file=sub("\\.R$",".pdf",Script.Name),width = 14)
sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)



library(data.table)
library(sf)

## read vars
source("~/CODE/gpx_tools/gpx_db/DEFINITIONS.R")


## TODO find files in bb 23.67452854,39.90723739,23.72368429,39.94759822
## 22.94751066,40.59749471,23.02471994,40.65515229
bb <- c(23.19148951,40.25211520,23.22016370,40.26935524)
# bb <- c(21.67452854,35.90723739,26.72368429,42.94759822)


## load data from gpx gather
DT           <- readRDS(trackpoints_fl)
## drop files dates
DT[, F_mtime:=NULL]

# ## load data from google locations
# DT2 <- readRDS(goolgepoints_fl)
# names(DT2)[names(DT2)=="file"] <- "filename"
# DT2[, F_mtime:=NULL]
#
# ## combine data
# DT <- rbind(DT, DT2[, names(DT), with =F ] )
# rm(DT2)

## remove fake dates
DT[ time < "1971-01-01", time := NA ]


hist(DT$time , breaks = 100)

typenames <- c("Points","Days","Hours")


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

if ( nrow( DT[ is.na(time)] ) > 0 ) {
    cat(paste(nrow(DT[is.na(time)]), "Points missing times\n"))

    mistime <- DT[ is.na(time), .N, by = filename]
    cat(paste(nrow(mistime), "Files with missing times\n"))

    ## show on terminal
    # print(mistime[,.(N,file)])
    ## write to file
    gdata::write.fwf(mistime[,.(N,filename)],
                     sep  = " ; ",
                     file = fl_notimes )
    ## clean bad data
    DT <- DT[!is.na(time)]
}



####  List file points in a bounding box for cleaning up

# files_bb <- DT[ Xdeg >= bb[1] &
#                 Xdeg <= bb[3] &
#                 Ydeg >= bb[2] &
#                 Ydeg <= bb[4] &
#                 grepl(".*.gpx", filename, ignore.case = T), .(Hits = .N), by = filename ]




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


## get sets with big coverage
gdata::write.fwf(dup_points[ Set %in% unique(dup_points[ Cover >= cover_threshold, Set]),
                             .(Set, filename, DupPnts, TotPnts, Cover, STime, ETime) ],
                 sep   = " ; ",
                 quote = FALSE,
                 file  = fl_suspctpt )

## get all sets
gdata::write.fwf(dup_points[,.(Set, filename, DupPnts, TotPnts, Cover, STime, ETime)],
                 sep = " ; ", quote = FALSE,
                 file = fl_suspctpt_all )



####  Filter data by speed  #####

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



#### Bin points in grids ####

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

## set flags for each category ##
DT[, Source := "Rest"]
DT[ grep("/Plans/", filename ), Source := "Plans" ]
DT[ grep("/ROUT/",  filename ), Source := "Plans" ]
DT[ grep("/TRAIN/", filename ), Source := "Train" ]

DT[ , filename := NULL ]

#### Change temporal resolution ####
DT[ , time :=  (as.numeric(time) %/% rsltemp * rsltemp) + (rsltemp/2)]
DT[ , time :=  as.POSIXct( time, origin = "1970-01-01") ]

## Count points in the minimum resolution of time and space
min_res <- min(rsls)

DT[ , X :=  (X %/% min_res * min_res) + (min_res/2) ]
DT[ , Y :=  (Y %/% min_res * min_res) + (min_res/2) ]
DT <- DT[ , .(Points = .N) ,  by = .(X,Y,Source, time) ]

## create other indexes to use
DT[ , day  := as.Date(time) ]
DT[ , hour := as.POSIXct(as.numeric(time) %/% 3600 * 3600, origin = "1970-01-01") ]



## export different spacial resolutions
for (res in sort(rsls,decreasing = T)) {
    resolname <- sprintf("Res %8d m",res)

    dt <- copy(DT)
    ## drop the resolution of the data
    dt[ , X :=  (X %/% res * res) + (res/2) ]
    dt[ , Y :=  (Y %/% res * res) + (res/2) ]

    stopifnot(nrow(dt[is.na(X), ])==0)

    ####  One pixel every day ####
    points_by_day        <- dt[ , .(Points  = sum(Points, na.rm = T),
                                    Hours   = length(unique(hour))), by = .(X,Y,Source,day) ]
    points_by_day$res    <- res
    points_by_day        <- st_as_sf( points_by_day,  coords = c("X", "Y"), crs = EPSG, agr = "constant")
    st_write(points_by_day, fl_gis_data_test, layer = sprintf("Days   %5d m",res), append = FALSE, delete_layer= TRUE)


    ####  One pixel every hour ####
    # points_by_hour       <- dt[ , .(Points  = sum(Points, na.rm = T)) , by = .(X,Y,Source,hour) ]
    # points_by_hour$res   <- res
    # points_by_hour       <- st_as_sf( points_by_hour,  coords = c("X", "Y"), crs = EPSG, agr = "constant")
    # st_write(points_by_hour, fl_gis_data_test, layer = sprintf("Hours  %5d m",res), append = FALSE, delete_layer= TRUE)


    ## should do that in gis
    # points_by_source     <- dt[ , .N , by = .(X,Y,Source, time) ]
    # points_by_source$res <- res
    # points_by_source     <- st_as_sf( points_by_source,  coords = c("X", "Y"), crs = EPSG, agr = "constant")
    # st_write(points_by_source, fl_gis_data_test, layer = sprintf("Source %5d m",res), append = FALSE, delete_layer= TRUE)

}



####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
