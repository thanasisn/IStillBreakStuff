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
setorder(DT, time  )
near <- myRtools::nearest( as.numeric( DT2$time),
                           as.numeric( DT$time ) )
timdiff <- abs( as.numeric(DT[ near, ]$time - DT2$time))
DT2     <- DT2[ timdiff >= google_threshold ]

## combine data
DT <- rbind(DT, DT2[, names(DT), with =F ] )
DT <- DTt[ ! is.na(time) ]
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


## FIXME this is pointless here!!
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

## aggregate times
DT[ , time :=  (as.numeric(time) %/% rsltemp * rsltemp) + (rsltemp/2)]
DT[ , time :=  as.POSIXct( time, origin = "1970-01-01") ]



## exclude some data paths not mine
DT <- DT[ grep("/Plans/",   filename, invert = T ), ]
DT <- DT[ grep("/ROUT/",    filename, invert = T ), ]

## get unique points
setkey( DT, time, X, Y )

## remove duplicate points
DT <- unique( DT[list(time, X, Y), nomatch = 0]  )





# unique(dirname( DT$file))

## break data in two categories
Dtrain <- rbind(
    DT[ grep("/TRAIN/", filename ), ]
)
Dtrain <- unique(Dtrain)

Drest <- DT[ ! grep("/TRAIN/", filename ), ]
Drest <- unique(Drest)

# unique(dirname( Dtrain$file))
# unique(dirname( Drest$file))

## choose one
## One file for each resolution
## OR one file with one layer per resolution

for (res in rsls) {
    # traindb   <- paste0(layers_out,"/Grid_",sprintf("%08d",res),"m.gpkg")
    resolname <- sprintf("Res %8d m",res)

    ## one column for each year and type and aggregator
    ## after that totals are computed

    yearstodo <- unique(year(DT$time))
    yearstodo <- sort(na.exclude(yearstodo))

    gather <- data.table()
    for (ay in yearstodo) {
        ## create all columns
        TRcnt <- copy(Dtrain[year(time)==ay])
        REcnt <- copy(Drest[ year(time)==ay])
        # ALcnt <- copy(DT[    year(time)==ay])
        TRcnt[ , X :=  (X %/% res * res) + (res/2) ]
        TRcnt[ , Y :=  (Y %/% res * res) + (res/2) ]
        REcnt[ , X :=  (X %/% res * res) + (res/2) ]
        REcnt[ , Y :=  (Y %/% res * res) + (res/2) ]
        # ALcnt[ , X :=  (X %/% res * res) + (res/2) ]
        # ALcnt[ , Y :=  (Y %/% res * res) + (res/2) ]

        TRpnts  <- TRcnt[ , .(.N ), by = .(X,Y) ]
        TRdays  <- TRcnt[ , .(N = length(unique(as.Date(time))) ), by = .(X,Y) ]
        TRhours <- TRcnt[ , .(N = length(unique( as.numeric(time) %/% 3600 * 3600 )) ), by = .(X,Y) ]

        REpnts  <- REcnt[ , .(.N ), by = .(X,Y) ]
        REdays  <- REcnt[ , .(N = length(unique(as.Date(time))) ), by = .(X,Y) ]
        REhours <- REcnt[ , .(N = length(unique( as.numeric(time) %/% 3600 * 3600 )) ), by = .(X,Y) ]

        # ALpnts  <- ALcnt[ , .(.N ), by = .(X,Y) ]
        # ALdays  <- ALcnt[ , .(N = length(unique(as.Date(time))) ), by = .(X,Y) ]
        # ALhours <- ALcnt[ , .(N = length(unique( as.numeric(time) %/% 3600 * 3600 )) ), by = .(X,Y) ]

        ## just to init data frame for merging
        dummy <- unique(rbind( TRcnt[, .(X,Y)], REcnt[, .(X,Y)] ))
        # dummy <- unique(rbind( TRcnt[, .(X,Y)], REcnt[, .(X,Y)], ALcnt[, .(X,Y)] ))

        ## nice names
        names(TRpnts )[names(TRpnts )=="N"] <- paste(ay,"Train","Points")
        names(TRdays )[names(TRdays )=="N"] <- paste(ay,"Train","Days"  )
        names(TRhours)[names(TRhours)=="N"] <- paste(ay,"Train","Hours" )
        names(REpnts )[names(REpnts )=="N"] <- paste(ay,"Rest", "Points")
        names(REdays )[names(REdays )=="N"] <- paste(ay,"Rest", "Days"  )
        names(REhours)[names(REhours)=="N"] <- paste(ay,"Rest", "Hours" )
        # names(ALpnts )[names(ALpnts )=="N"] <- paste(ay,"ALL",  "Points")
        # names(ALdays )[names(ALdays )=="N"] <- paste(ay,"ALL",  "Days"  )
        # names(ALhours)[names(ALhours)=="N"] <- paste(ay,"ALL",  "Hours" )

        ## gather all to a data frame for a year
        aagg <- merge(dummy, TRpnts,  all = T )
        aagg <- merge(aagg,  TRdays,  all = T )
        aagg <- merge(aagg,  TRhours, all = T )
        aagg <- merge(aagg,  REpnts,  all = T )
        aagg <- merge(aagg,  REdays,  all = T )
        aagg <- merge(aagg,  REhours, all = T )
        # aagg <- merge(aagg,  ALpnts,  all = T )
        # aagg <- merge(aagg,  ALdays,  all = T )
        # aagg <- merge(aagg,  ALhours, all = T )

        ## gather columns for all years
        if (nrow(gather) == 0) {
            gather <- aagg
        } else {
            gather <- merge(gather,aagg, all = T )
        }
    }

    ## create total columns for all years
    categs <- grep("geometry|X|Y" , unique(sub("[0-9]+ ","", names(gather))), invert = T, value = T)
    for (ac in categs) {
        wecare <- grep(ac, names(gather), value = T)

        ncat           <- paste("Total", ac)
        gather[[ncat]] <- rowSums( gather[, ..wecare ], na.rm = T)
        gather[[ncat]][gather[[ncat]]==0] <- NA
    }

    ## create total column for all years and all types
    cols <- grep( "Total" , names(gather), value = T)
    for (at in typenames) {
        wecare <- grep(at, cols, value = T)
        ncat   <- paste("Total All", at)
        gather[[ncat]] <- rowSums( gather[, ..wecare ], na.rm = T)
        gather[[ncat]][gather[[ncat]]==0] <- NA
    }

    ## add info for qgis plotting functions
    gather$Resolution <- res
    ## convert to spatial data objects
    gather <- st_as_sf(gather, coords = c("X", "Y"), crs = EPSG, agr = "constant")

    ## store spatial data one layer per file
    # st_write(gather, traindb, layer = NULL, append = FALSE, delete_layer= TRUE)

    ## store data as one layer in one file one layer per resolution
    st_write(gather, fl_gis_data, layer = resolname, append = FALSE, delete_layer= TRUE)
}



####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
