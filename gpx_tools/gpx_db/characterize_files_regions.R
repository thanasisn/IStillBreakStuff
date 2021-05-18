#!/usr/bin/env Rscript


#### Characterize gpx files by regions in which they intersect


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
library(sfheaders)
library(myRtools)

##TODO create a new shapefile with count in each region

## read vars
source("~/CODE/gpx_tools/gpx_db/DEFINITIONS.R")


## prepare data
data           <- readRDS(trackpoints_fl)
data[, F_mtime := NULL]
data[, time    := NULL]
data[, dist    := NULL]
data[, timediff:= NULL]


cat(paste( length(unique( data$file )), "total files parsed\n" ))
cat(paste( nrow( data ), "points parsed\n" ))

#### clean problematic data ####
if ( nrow(data[ is.na(X) |
                is.na(Y) |
                is.infinite(X) |
                is.infinite(Y) |
                !is.numeric(X) |
                !is.numeric(Y)   ]) != 0) {
    cat("\nMissing coordinates!!\n")
    cat("Add some code to fix!!\n")
}

## drop resolution of files
data[ , X :=  (X %/% resolution_lcz * resolution_lcz) + (resolution_lcz/2) ]
data[ , Y :=  (Y %/% resolution_lcz * resolution_lcz) + (resolution_lcz/2) ]

data <- unique(data)
data[ , N:=.N, by = file]


#### read polygons for the regions ####
regions <- st_read(fl_regions, stringsAsFactors = FALSE)
regions <- st_transform(regions, EPSG)


## characterize all files with all regions
gather         <- data.table()
reproj         <- sf_point(data, x = "X", y = "Y")
st_crs(reproj) <- EPSG

for (ii in 1:length(regions$Name)) {
    cat(paste("Characterize", regions$Name[ii],"\n"))

    vec <- apply(st_intersects(regions$geometry[ii], reproj, sparse = FALSE), 2,
                 function(x) { x })

    cat(paste(sum(vec),"points\n"))

    temp <- data[vec, .(FN=.N), by= .(file,N)]
    if (nrow(temp)>0) {
        gather <- rbind(gather,
                        cbind(temp, Region = regions$Name[ii]))
    } else {
        cat(paste("No data poinrs for: ", regions$Name[ii], "\n"))
    }
}

## characterize rest of files as "Other" location
files  <- unique(data$file)
gather <- rbind(gather,
                cbind(file   = files[ ! files %in% gather$file],
                      Region = "Other"), fill = T)

## list of characterized files
write_RDS(gather, file = fl_localized )



####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
