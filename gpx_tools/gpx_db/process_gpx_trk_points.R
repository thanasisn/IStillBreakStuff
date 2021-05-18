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

baseoutput     <- "~/GISdata/"
layers_out     <- "~/GISdata/Layers/Auto/"

fl_notimes <- paste0(baseoutput,"/Files_points_no_time.csv")

## load data
DT           <- readRDS(trackpoints_fl)
## drop files dates
DT[, F_mtime:=NULL]

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

    mistime <- DT[ is.na(time), .N, by = file]
    cat(paste(nrow(mistime), "Files with missing times\n"))

    ## show on terminal
    # print(mistime[,.(N,file)])
    ## write to file
    gdata::write.fwf(mistime[,.(N,file)],
                     sep  = " ; ",
                     file = fl_notimes )
    ## clean bad data
    DT <- DT[!is.na(time)]
}







####  Detect possible duplicate files  ####
cat(paste("Get possible duplicate files\n"))

## get files with points in the same date
file_dates <- DT[, .N, by = .(Date = as.Date(time), file)]
same_date  <- list()
for (ad in unique(file_dates$Date)) {
    ad   <- as.Date(ad, origin = "1970-01-01")
    temp <- file_dates[Date == ad]
    if (nrow(temp) > 1 ) {
        # cat(paste(temp$file),"\n")
        same_date <- c(same_date, list(t(temp$file)))
    }
}

## check the files if have dups points
dup_points <- data.frame()
for (il in 1:length(same_date)) {

    temp <- DT[ file %in% same_date[[il]]]

    ## only when we have time
    temp <- temp[ !is.na(time) ]

    setkey(temp, time, X, Y)
    dups <- duplicated(temp, by = key(temp))
    temp[, fD := dups | c(tail(dups, -1), FALSE)]
    duppoints <- temp[fD == TRUE]

    ## files with dups points
    countP <- duppoints[ , .(DupPnts = .N, STime = min(time), ETime = max(time)) , by = .(file ) ]
    countP$TotPnts <- 0
    countP$Set     <- il
    for (af in unique(countP$file)) {
        countP[file==af, TotPnts := DT[file == af, .N] ]
    }
    dup_points <- rbind(dup_points, countP)
}

dup_points[, Cover := DupPnts / TotPnts]

cat(paste(nrow(duppoints), "Duplicate points found\n"))


dup_points$STime <- format( dup_points$STime, "%FT%R:%S" )
dup_points$ETime <- format( dup_points$ETime, "%FT%R:%S" )


## get sets with big coverage
gdata::write.fwf(dup_points[ Set %in% unique(dup_points[ Cover >= 0.95, Set]),
                             .(Set, file, DupPnts, TotPnts, Cover, STime, ETime) ],
                 sep = " ; ", quote = FALSE,
                 file = paste0(baseoutput,"Dups_point_suspects.csv") )

## get all sets
gdata::write.fwf(dup_points[,.(Set, file, DupPnts, TotPnts, Cover, STime, ETime)],
                 sep = " ; ", quote = FALSE,
                 file = paste0(baseoutput,"Dups_point_suspects_all.csv") )



####  Filter data by speed  #####

##TODO
hist(DT$timediff)
hist(DT$dist)
hist(DT$kph)

table((DT$timediff %/% 5) * 5 )
table((DT$dist     %/% 1000) * 1000 )
table(abs(DT$kph   %/% 200) * 200 )

cat(paste("\nGreat distances\n"))
DT[dist > 100000, .( .N, MaxDist = max(dist)) , by = file]

cat(paste("\nGreat speeds\n"))
DT[kph > 500000 & !is.infinite(kph), .(.N, MaxKph = max(kph), time[which.max(kph)]) , by = file ]

cat(paste("\nGreat times\n"))
DT[timediff > 600 , .(.N, MaxTDiff = max(timediff), time = time[which.max(timediff)]) , by = file ]


# esss <- DT[kph > 200, .(file, kph, timediff, dist ,time) ]
# setorder(esss, kph)

# DT[dist > 200, .(max(kph), time[which.max(kph)] ), by = file ]

# DT[timediff==0]

# DT[dist==0 & timediff==0]
# DT[dist>0 & dist < 10 & timediff==0]

# DT[is.infinite(kph), .(max(dist), time[which.max(dist)]) ,by = file]

# DT[dist<0]



#### Bin points in grids ####
rsls <- unique(c(
    5,
    10,
    20,
    50,
    100,
    500,
    1000,
    5000,
    10000,
    20000,
    50000 ))

rsltemp <- 180 ## temporal resolution in seconds
## points inside the sqare counts once every 180 secs

## aggregate times
DT[ , time :=  (as.numeric(time) %/% rsltemp * rsltemp) + (rsltemp/2)]
DT[ , time :=  as.POSIXct( time, origin = "1970-01-01") ]


## exclude some data paths not mine
DT <- DT[ grep("/Plans/",   file, invert = T ), ]
DT <- DT[ grep("/E_paths/", file, invert = T ), ]
DT <- DT[ grep("/ROUT/",    file, invert = T ), ]

## get unique points
setkey( DT, time, X, Y )

## remove duplicate points
DT <- unique( DT[list(time, X, Y), nomatch = 0]  )

## keep only existing coordinates
DT <- DT[ !is.na(X) ]
DT <- DT[ !is.na(Y) ]

cat(paste( length(unique( DT$file )), "files to bin\n" ))
cat(paste( nrow( DT ), "points to bin\n" ))


# unique(dirname( DT$file))

## break data in two categories
Dtrain <- rbind(
    DT[ grep("/TRAIN/", file ), ],
    DT[ grep("/Running/Polar/", file ), ]
)
Dtrain <- unique(Dtrain)

Drest <-  DT[ ! grep("/Running/Polar/", file ), ]
Drest <- Drest[ ! grep("/TRAIN/", file ), ]
Drest <- unique(Drest)

# unique(dirname( Dtrain$file))
# unique(dirname( Drest$file))

## choose one
## One file for each resolution
## OR one file with one layer per resolution
onefile <-  paste0(layers_out,"/Grid_mega.gpkg")
for (res in rsls) {
    traindb   <- paste0(layers_out,"/Grid_",sprintf("%08d",res),"m.gpkg")
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
        TRcnt[ , X :=  (X %/% res * res) + (res/2) ]
        TRcnt[ , Y :=  (Y %/% res * res) + (res/2) ]
        REcnt[ , X :=  (X %/% res * res) + (res/2) ]
        REcnt[ , Y :=  (Y %/% res * res) + (res/2) ]

        TRpnts  <- TRcnt[ , .(.N ), by = .(X,Y) ]
        TRdays  <- TRcnt[ , .(N = length(unique(as.Date(time))) ), by = .(X,Y) ]
        TRhours <- TRcnt[ , .(N = length(unique( as.numeric(time) %/% 3600 * 3600 )) ), by = .(X,Y) ]

        REpnts  <- REcnt[ , .(.N ), by = .(X,Y) ]
        REdays  <- REcnt[ , .(N = length(unique(as.Date(time))) ), by = .(X,Y) ]
        REhours <- REcnt[ , .(N = length(unique( as.numeric(time) %/% 3600 * 3600 )) ), by = .(X,Y) ]

        ## just to init data frame for merging
        dummy <- unique(rbind( TRcnt[, .(X,Y)] , REcnt[, .(X,Y)] ))

        ## nice names
        names(TRpnts )[names(TRpnts )=="N"] <- paste(ay,"Train","Points")
        names(TRdays )[names(TRdays )=="N"] <- paste(ay,"Train","Days")
        names(TRhours)[names(TRhours)=="N"] <- paste(ay,"Train","Hours")
        names(REpnts )[names(REpnts )=="N"] <- paste(ay,"Rest","Points")
        names(REdays )[names(REdays )=="N"] <- paste(ay,"Rest","Days")
        names(REhours)[names(REhours)=="N"] <- paste(ay,"Rest","Hours")

        ## gather all to a data frame for a year
        aagg <- merge(dummy, TRpnts,  all = T )
        aagg <- merge(aagg,  TRdays,  all = T )
        aagg <- merge(aagg,  TRhours, all = T )
        aagg <- merge(aagg,  REpnts,  all = T )
        aagg <- merge(aagg,  REdays,  all = T )
        aagg <- merge(aagg,  REhours, all = T )

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
        ncat <- paste("Total All", at)
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
    st_write(gather, onefile, layer = resolname, append = FALSE, delete_layer= TRUE)
}






####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
