#!/usr/bin/env Rscript
## https://github.com/thanasisn <natsisphysicist@gmail.com>


#### Split Google location history json to smaller manageable Rds files
## The output may need some manual adjustment


#### _ INIT _ ####

closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()

library(data.table)
library(jsonlite)
library(myRtools)

## break every n data points
breaks   <- 10000

## input file path
Bfile     <- "~/DATA_RAW/Other/Google_Takeout/Location History/Records.json"

## raw output location
storedir <- "~/DATA_RAW/Other/GLH/Raw"

## temp output base
tempdir  <- "/dev/shm/glh/"


#### _ MAIN _ ####

dir.create(storedir, showWarnings = F )
dir.create(tempdir,  showWarnings = F )

# nfile <- paste0(tempdir, "master_temp.json")

## create a copy of working file
# file.copy(Bfile, nfile)


## remove some decorations of the file
# system(paste("sed -i '/\"locations\" :/d'", nfile ))
# system(paste("sed -i 's/^{$/[ {/'", nfile ))
# system(paste("sed -i '$d'", nfile ))

## read the file
# lines <- readLines(nfile)

## find the location of each point in the file
# ntim <- grep("timestampMs", lines)
# nlat <- grep("latitudeE7",  lines)
# nlon <- grep("longitudeE7", lines)
## move indexes same as ntime
# nlat <- nlat - 1
# nlon <- nlon - 2

## these are sets anyway
stopifnot( all(nlat == nlon) )

## the location of every point start
# npoints <- intersect(ntim,nlat)
## distribute the point to chunks for breaking
# targets <- which( npoints %% breaks == 1)
## index of split points
# spltlin <- c(1,npoints[targets], length(lines))

# #### Split json in smaller json files ####
# for ( ii in 1:(length(spltlin)-1) ) {
#     from  <- spltlin[ii]
#     until <- spltlin[ii+1]
#
#     cat(paste("Part:",ii),"\n")
#     cat(paste(from, until,"\n"))
#
#     ## inspect chunk
#     # head(temp)
#     # tail(temp)
#
#     temp <- lines[(from-1):(until-1)]
#
#     ## fix proper ends
#     if (grepl("\\}, \\{", temp[length(temp)])) {
#         temp[length(temp)] <- "} ]"
#     }
#
#     ## fix proper starts
#     if (grepl("\\}, \\{", temp[1])) {
#         temp[1] <- "[ {"
#     }
#
#     ## fix end all for the last chunk
#     ## FIXME not writing to the end every time works on manual runs
#     if ( ii == length(spltlin)-1 ) {
#         ## remove last comma
#         ## although this mean that some lines at the end may be missing
#         temp[length(temp)] <- sub(",$","", temp[length(temp)])
#         temp <- c(temp,"} ]")
#     }
#
#     ## inspect output
#     cat("HEAD:......\n")
#     cat(head(temp),sep = "\n")
#     cat("TAIL:......\n")
#     cat(tail(temp),sep = "\n")
#     cat("......\n")
#
#     ## write spitted files
#     writeLines( temp, paste0(tempdir,"GLH_part_", sprintf("%04d",ii), ".json"))
# }
# rm(lines)
#
# cat(paste("May need to do manual corrections to the last splitted json files"),"\n")
#
# filestodo <- list.files(path       = tempdir,
#                         pattern    = "GLH_part.*.json",
#                         full.names = T)




## read directly the main file
filestodo <- Bfile

####  Parse smaller json files to Rds  ####
for (af in filestodo) {
    cat(paste("Parsing: ",af),"\n")

    # test1 <- ndjson::stream_in(af, cls = "dt" )
    # test2 <- jsonlite::stream_in(file(af), flatten=TRUE, verbose=FALSE)
    tempJ <- data.table(jsonlite::fromJSON(af))

    ## test
    saveRDS(tempJ, "./tempj_temp.Rdat")
    tempJ <- readRDS("/home/athan/CODE/gpx_tools/google_location/tempj_temp.Rdat")


    tempJ <- tempJ$V1[[1]]

    ## proper dates
    tempJ$Date      <- as.POSIXct(strptime(tempJ$timestamp,"%FT%H:%M:%OS"))
    tempJ$timestamp <- NULL

    ## proper coordinates
    tempJ$Lat         <- tempJ$latitudeE7  / 1e7
    tempJ$Long        <- tempJ$longitudeE7 / 1e7
    tempJ$latitudeE7  <- NULL
    tempJ$longitudeE7 <- NULL

    ## clean data coordinates
    tempJ$Long[tempJ$Long == 0] <- NA
    tempJ$Lat [tempJ$lat  == 0] <- NA



    tempJ <- tempJ[ !is.na(tempJ$Long), ]
    tempJ <- tempJ[ !is.na(tempJ$Lat),  ]
    tempJ <- tempJ[ abs(tempJ$Lat)  <  89.9999, ]
    tempJ <- tempJ[ abs(tempJ$Long) < 179.9999, ]


    for (ay in unique(year(tempJ$Date))) {
        ydata <- tempJ[ year(tempJ$Date) == ay, ]

        outfile <- paste0(storedir,"/GLH_part_",ay)
        writeDATA(ydata,
                  file  = outfile,
                  clean = TRUE,
                  type  = "Rds")
    }



    # ## output file name
    # outfile <- paste0(storedir,"/",basename(af))
    # ## write to Rds to preserve sub tables in cells
    # writeDATA(tempJ,
    #           file  = outfile,
    #           clean = TRUE,
    #           type  = "Rds")
}
## remove temp folder
unlink(tempdir, recursive = T)

#### _ END _ ####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
