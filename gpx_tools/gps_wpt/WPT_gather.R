#!/usr/bin/env Rscript
# /* Copyright (C) 2022 Athanasios Natsis <natsisphysicist@gmail.com> */
#'
#' - Gather GPX waypoints in a DB
#'
#+ echo=FALSE, include=TRUE


#+ echo=FALSE, include=TRUE
## __ Set environment  ---------------------------------------------------------
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/gpx_tools/gps_wpt/WPT_gather.R"

if (!interactive()) pdf(file = sub("\\.R$", ".pdf", Script.Name), width = 14)

if (!interactive()) {
  dir.create("../runtime/", showWarnings = F, recursive = T)
  pdf( file = paste0("../runtime/", basename(sub("\\.R$",".pdf", Script.Name))))
  sink(file = paste0("../runtime/", basename(sub("\\.R$",".out", Script.Name))), split = TRUE)
}

#+ echo=F, include=T
suppressPackageStartupMessages({
  library(arrow,      quietly = TRUE, warn.conflicts = FALSE)
  library(data.table, quietly = TRUE, warn.conflicts = FALSE)
  library(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
  library(sf,         quietly = TRUE, warn.conflicts = FALSE)
  library(stringr,    quietly = TRUE, warn.conflicts = FALSE)
  library(janitor,    quietly = TRUE, warn.conflicts = FALSE)
})


## read vars
source("~/CODE/gpx_tools/gps_wpt/DEFINITIONS.R")

options(warn = 1)


DRINKING_WATER <- TRUE
WATERFALLS     <- TRUE
CAVES          <- TRUE


#### list GPX files ####
gpxlist   <- list.files(gpx_repo,
                        pattern     = ".gpx$",
                        recursive   = T,
                        full.names  = T,
                        ignore.case = T)

gpxlist <- data.table(file  = gpxlist,
                      mtime = file.mtime(gpxlist))


if (file.exists(fl_waypoints)) {
  DATA <- readRDS(fl_waypoints)

  ## remove readed files
  ## reread edited files


} else {
  DATA <- data.table()
}



##  Get all waypoints from files  ----------------------------------------------
if (length(gpxlist$file) > 0) {
  for (af in gpxlist$file) {
    if (!file.exists(af)) { next() }
    cat(paste(af,"\n"))

    ##  Read a file
    gpx  <- read_sf(af, layer = "waypoints")

    meta <- data.table(file   = af,
                       Region = NA,
                       mtime  = file.mtime(af))

    if (nrow(gpx) > 0) {
      ## gather points
      wpt  <- st_transform(gpx, EPSG_MERCA)

      DATA <- rbind(DATA,
                    cbind(wpt, meta),
                    fill = T)

    } else {
      ## keep track of empty files
      DATA <- rbind(DATA,
                    meta,
                    fill = T)
    }
  }
}



##  Add drinking water from OSM  -----------------------------------------------
if (DRINKING_WATER) {
  dw_fl     <- "~/GISdata/Layers/Auto/osm/OSM_Drinking_water_springs_Gr.gpx"
  dw        <- read_sf(dw_fl, layer = "waypoints")
  ## clean data
  dw$desc   <- gsub("\n", " ", dw$desc)
  dw$name   <- gsub("\n", " ", dw$name)
  ## set a name for display in case of empty
  dw$name[is.na(dw$name)] <- "Nero"
  dw$link <- NA

  ## overpass web interface
  ## parse drinking water
  # indx <- grep("amenity=drinking_water",dw$desc)
  # dw$desc[indx]   <- gsub("amenity=drinking_water","βρύση OSM",dw$desc[indx])
  # dw$name[indx]   <- sub("node/[0-9]+","vris",dw$name[indx])
  ## parse springs
  # indx <- grep("natural=spring",dw$desc)
  # dw$desc[indx]   <- gsub("natural=spring","Πηγή OSM",dw$desc[indx])
  # dw$name[indx]   <- sub("node/[0-9]+","pigi",dw$name[indx])

  meta <- data.table(file   = dw_fl,
                     Region = NA,
                     mtime  = file.mtime(dw_fl))
  dw   <- cbind(dw, meta)

  dw   <- st_transform(dw, EPSG_MERCA)

  # distmwt <- raster::pointDistance(p1 = dw, p2 = gather_wpt, lonlat = T, allpairs = T)
  # distmwt <- round(distmwt, digits = 3)

  ## find close points
  # dd <- which(distmwt < 5, arr.ind = T)

  DATA <- rbind(DATA,
                dw,
                fill = T)
  rm(dw)
}


##  Add waterfalls from OSM  ---------------------------------------------------
if (WATERFALLS) {
  dw_fl     <- "~/GISdata/Layers/Auto/osm/OSM_Waterfalls_Gr.gpx"
  dw        <- read_sf(dw_fl, layer = "waypoints")
  ## clean data
  dw$desc   <- gsub("\n", " ", dw$desc)
  dw$name   <- gsub("\n", " ", dw$name)
  ## set a name for display in case of empty
  dw$name[is.na(dw$name)] <- "Waterfall"
  dw$link <- NA

  meta <- data.table(file   = dw_fl,
                     Region = NA,
                     mtime  = file.mtime(dw_fl))
  dw   <- cbind(dw, meta)

  dw   <- st_transform(dw, EPSG_MERCA)

  # distmwt <- raster::pointDistance(p1 = dw, p2 = gather_wpt, lonlat = T, allpairs = T     # distmwt <- round(distmwt, digits = 3)
  ## find close points
  # dd <- which(distmwt < 5, arr.ind = T)

  DATA <- rbind(DATA,
                dw,
                fill = T)
  rm(dw)
}


##  Add caves from OSM  --------------------------------------------------------
if (CAVES) {
  dw_fl     <- "~/GISdata/Layers/Auto/osm/OSM_Caves_Gr.gpx"
  dw        <- read_sf(dw_fl, layer = "waypoints")
  ## clean data
  dw$desc   <- gsub("\n", " ", dw$desc)
  dw$name   <- gsub("\n", " ", dw$name)
  ## set a name for display in case of empty
  dw$name[is.na(dw$name)] <- "Cave"
  dw$link <- NA

  meta <- data.table(file   = dw_fl,
                     Region = NA,
                     mtime  = file.mtime(dw_fl))
  dw   <- cbind(dw, meta)

  ## reproject to meters
  dw  <- st_transform(dw, EPSG_MERCA)

  # distmwt <- raster::pointDistance(p1 = dw, p2 = gather_wpt, lonlat = T, allpairs = T     # distmwt <- round(distmwt, digits = 3)
  ## find close points
  # dd <- which(distmwt < 5, arr.ind = T)

  DATA <- rbind(DATA,
                dw,
                fill = T)
  rm(dw)
}

DATA <- remove_empty(DATA, which = "cols")


##  ID regions  -----------------------

##  Read polygons for the regions
regions <- st_read(fl_regions, stringsAsFactors = FALSE)
regions <- st_transform(regions, EPSG_MERCA)
regions$NFiles  <- 0
regions$NPoints <- 0

valid_wpt  <- !st_is_empty(st_sfc(DATA$geometry))
DATA_wpt   <- DATA[ valid_wpt, ]
DATA_empty <- DATA[!valid_wpt, ]

## characterize all waypoints within each polygon
for (ii in 1:length(regions$Name)) {

  cat(paste("Characterize", regions$Name[ii],"\n"))

  ## mark region
  vec <- apply(
    st_intersects(
      regions$geometry[ii],
      DATA_wpt$geometry,
      sparse = FALSE
    ),
    2,
    function(x) { x }
  )

  ## set region
  DATA_wpt$Region[ vec ] <- regions$Name[ii]
}

DATA <- rbind(DATA_wpt, DATA_empty, fill = T)
rm(DATA_wpt, DATA_empty)

table(DATA$Region)










stop()

wpt_seed     <- "~/GISdata/seed2.Rds"
wpt_seed3    <- "~/GISdata/seed3.Rds"


update         <- FALSE


##FIXME duplicates work around
file.remove(fl_waypoints)

## check if we need to update data ####
if (file.exists(fl_waypoints)) {
  ## load old data
  gather_wpt <- readRDS(fl_waypoints)
  gather_wpt <- unique(gather_wpt)

  ## remove all data from missing files
  gather_wpt <- gather_wpt[ file.exists(gather_wpt$file), ]

  ## list parsed files
  dblist <- gather_wpt[, c("file","mtime") ]
  dblist$geometry <- NULL
  dblist <- unique( dblist )

  ## list all files
  fllist <- data.frame(file = gpxlist,
                       mtime = file.mtime(gpxlist),
                       stringsAsFactors = F)

  ## files to do
  ddd <- anti_join( fllist, dblist )

  ## remove data from changed files
  gather_wpt <- gather_wpt[ ! gather_wpt$file %in% ddd$file, ]

  gpxlist <- ddd$file

} else {
  gather_wpt <- readRDS(wpt_seed)
}




wecare <- c("ele",
            "time",
            "magvar",
            "geoidheight",
            "name",
            "cmt",
            "desc",
            "src",
            "sym",
            "type",
            "ageofdgpsdata",
            "dgpsid",
            "geometry",
            "Region",
            "file",
            "mtime")







## store for all R
if (update) {
  gather_wpt <- unique(gather_wpt)
  myRtools::write_RDS(gather_wpt, fl_waypoints)
}







## remove dummy data for analysis ####
ssel       <- gather_wpt$geometry == ffff$geometry
gather_wpt <- gather_wpt[ ! ssel, ]


## clean
gather_wpt <- gather_wpt[ ! lapply(gather_wpt$geometry, length) != 2, ]
gather_wpt <- gather_wpt[ unique(which(apply(!is.na(st_coordinates(gather_wpt$geometry)),1,all))), ]

## transform to degrees
gather_wpt <- st_transform(gather_wpt, EPSG_WGS84)

cat(paste("\n", nrow(gather_wpt),"waypoints parsed \n\n" ))


#### export unfiltered gpx ####
copywpt <- gather_wpt

## rename
names(copywpt)[names(copywpt) == "file"] <- 'desc'

## drop data
copywpt$file   <- NULL
copywpt$mtime  <- NULL
copywpt$Region <- NULL
write_sf(copywpt, '~/GISdata/Layers/Gathered_unfilt_wpt.gpx', driver = "GPX", append = F, overwrite = T)


## compute distance matrix unfiltered ####
distm <- raster::pointDistance(p1 = gather_wpt, lonlat = T, allpairs = T)
distm <- round(distm, digits = 3)


## find close points
dd <- which(distm < close_flag, arr.ind = T)
## remove diagonal
dd <- dd[dd[,1] != dd[,2], ]
paste( nrow(dd), "point couples under", close_flag, "m distance")

## remove pairs 2,3 == 3,2
for (i in 1:nrow(dd)) {
  dd[i, ] = sort(dd[i, ])
}

# pA <- gather_wpt[dd[,1],]
# pA <- data.table(pA)
# pA <- pA[, .(Total_Dups = .N),by=file]
# for (ii in 1:nrow(pA)){
#     afi <- unlist(pA[ii,file])
#     pA[ii,Total_Dups]
#     gather_wpt$file == afi
# }



dd <- unique(dd)
paste( nrow(dd), "point couples under", close_flag, "m distance" )



####
suspects <- data.table(
  name_A = gather_wpt$name    [dd[,1]],
  geom_A = gather_wpt$geometry[dd[,1]],
  file_A = gather_wpt$file    [dd[,1]],
  name_B = gather_wpt$name    [dd[,2]],
  geom_B = gather_wpt$geometry[dd[,2]],
  file_B = gather_wpt$file    [dd[,2]],
  time_A = gather_wpt$time    [dd[,1]],
  time_B = gather_wpt$time    [dd[,2]],
  elev_A = gather_wpt$ele     [dd[,1]],
  elev_B = gather_wpt$ele     [dd[,2]]
)
suspects$Dist <- distm[ cbind(dd[,2],dd[,1]) ]
suspects      <- suspects[order(suspects$Dist, decreasing = T) , ]
# suspects <- suspects[order(suspects$file_A,suspects$file_B, decreasing = T) , ]



## reformat for faster cvs use
suspects$time_A <- format( suspects$time_A, "%FT%R:%S" )
suspects$time_B <- format( suspects$time_B, "%FT%R:%S" )

wecare <- grep("geom", names(suspects),invert = T,value = T )
wecare <- c("Dist","elev_A","time_A","name_A","name_B","file_A","file_B" )

gdata::write.fwf(suspects[, ..wecare],
                 sep = " ; ", quote = TRUE,
                 file = "~/GISdata/Suspects_wpt.csv" )


## ignore points in the same file
suspects <- suspects[name_A != name_B]

## count cases in files
filescnt <- suspects[, .(file_A,file_B) ]
filescnt <- filescnt[, .N , by = (paste(file_A,file_B))]
filescnt$Max_dist <- close_flag
setorder(filescnt, N)
gdata::write.fwf(filescnt,
                 sep = " ; ", quote = TRUE,
                 file = "~/GISdata/Suspect_wpt_to_clean.csv" )



####  Export filtered GPX for usage  ###########################################

## deduplicate WPT
gather_wpt <- unique(gather_wpt)
gather_wpt <- gather_wpt %>% distinct_at(vars(-file, -mtime), .keep_all = T)

## rename vars
gather_wpt$desc <- NULL
names(gather_wpt)[names(gather_wpt) == "file"] <- 'desc'

## drop data
gather_wpt$file  <- NULL
gather_wpt$mtime <- NULL

## characterize missing regions
gather_wpt$Region[is.na(gather_wpt$Region)] <- "Other"

## Clean waypoints names  ------------------------------------------------------
gather_wpt <- gather_wpt[grep(".*go straight.*",                              gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Ankerplatz[[:space:]]*",           gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep(".*χαιντου από μαύρη.*",                        gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep(".*Following a path.*",                         gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Arrive at.*",                      gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Ascending.*",                      gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Borderline.*",                     gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Borderline.*",                     gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Descending.*",                     gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Monopati erev.*",                     gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Dromos[0-9]*[[:space:]]*",         gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Entry path.*",                     gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Follow it.*",                      gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Follow the.*",                     gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*GRA[0-9]+[[:space:]]*",            gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*GRE[0-9]*[[:space:]]*",            gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Go[[:space:]]*right.*",            gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Head [a-z]+",                      gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*PIN[0-9]+[[:space:]]*",            gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Parkplatz.*",                      gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Path entry.*",                     gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Straight .*",                      gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Trail Head[[:space:]]*",           gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Turn .*",                          gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*WPT[0-9]+[[:space:]]*",            gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*XDRXRD.*[[:space:]]*",             gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*[0-9]+![[:space:]]*",              gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*[0-9]+R",                          gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*[0-9]+[[:space:]]*",               gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*arxh",                             gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*arxi[[:space:]]*",                 gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*asf-xom[[:space:]]*",              gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*at roundab[[:space:]]*",           gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*aσφμον[[:space:]]*",               gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*dasmon[[:space:]]*",               gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*dexia[[:space:]]*",                gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*dias[[:space:]]*",                 gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*end$",                             gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*finish[[:space:]]*",               gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*foto[[:space:]]*",                 gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*from[[:space:]]*",                 gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*go left[[:space:]]*",              gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*hotmail.com",                      gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*kato[[:space:]]*",                 gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*keep .*",                          gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*lap [0-9].*[[:space:]]*",          gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*life [0-9]+",                      gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*monxom[[:space:]]*",               gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*null$",                            gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*pagida *[0-9]+[[:space:]]*",       gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*pagida a[0-9]+[[:space:]]*",       gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*photo",                            gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*photo[[:space:]]*",                gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*scat [0-9]+[[:space:]]*",          gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*scat$",                            gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*skat [0-9]+[[:space:]]*",          gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*skat[[:space:]]*",                 gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*start[[:space:]]*",                gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*strofi[[:space:]]*",               gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*summit[[:space:]]*",               gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*to[[:space:]]*",                   gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*tor *[0-9]*[[:space:]]*",          gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*via[0-9]+[[:space:]]*",            gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*xdr[0-9]+[[:space:]]*",            gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Αρκ [0-1]+[[:space:]]*",           gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Αρκ![[:space:]]*",                 gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Αρκ[[:space:]]*",                  gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Αρχή Μονοπατιού.*[[:space:]]*",    gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Γουρ!$",                           gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Δείγ Ερθρλ",                       gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Δεξιά[[:space:]]*",                gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Διασταυρωση$",                     gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Διασταύρωση Junction[[:space:]]*", gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Διασταύρωση[[:space:]]*",          gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Κάτω δεξιά[[:space:]]*",           gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Κατω δεξιά[[:space:]]*",           gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Κατω δεξια[[:space:]]*",           gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Λυκ?",                             gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Μονοπάτι[[:space:]]*",             gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*Μονοπατι[[:space:]]*",             gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*άσφαλτος[[:space:]]*",             gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*από εδώ[[:space:]]*",              gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*αριστερά[[:space:]]*",             gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*αριστερα[[:space:]]*",             gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*αρχή μονοπάτι[[:space:]]*",        gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*ασφμον[[:space:]]*",               gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*γου[[:space:]]*",                  gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*γουρ[[:space:]]*",                 gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*διαδρομή[[:space:]]*",             gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*εδω[[:space:]]*",                  gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*εδώ[[:space:]]*",                  gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*κ[0-9]+[[:space:]]*",              gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*σκατ[[:space:]]*",                 gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*τριχεσ[[:space:]]*",               gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*χωματoδρομος[[:space:]]*",         gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*χωματόδρομος[[:space:]]*",         gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*ως εδώ[[:space:]]*",               gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("hotmail.com",                                  gather_wpt$name, invert = T, ignore.case = T), ]

## Translate waypoints names  --------------------------------------------------
gather_wpt$name <- gsub("Aussichtspunkt", "Viewpoint", gather_wpt$name)


## TODO capitalize for consistency don't use for ROUT!!
gather_wpt$name <- str_to_title(gather_wpt$name)
stringi::stri_trans_general("πατατα", "Greek-Latin/UNGEGN")

gather_wpt <- unique(gather_wpt)

ttt <- table(gather_wpt$name)

cat(paste("\n", nrow(gather_wpt),"waypoints after filtering \n\n" ))

## ignore some waypoints files not relevant to our usage
drop_files <- c(
  "grammos2012/Acquired_from_GPS.gpx",
  "WPT_hair_traps_rodopi_2015-06-28.gpx",
  "WPT_stanes_rodopi.gpx"
)



##  Export GPX waypoints by region  --------------------------------------------
for (ar in unique(gather_wpt$Region)) {

  temp <- gather_wpt[gather_wpt$Region == ar, ]
  temp$Region <- NULL
  temp <- temp[order(temp$name),]

  cat(paste("export", nrow(temp), "wpt", ar, "\n"))

  ## ignore some files
  for (ast in drop_files) {
    sel  <- !grepl(ast, temp$desc)
    temp <- temp[sel,]
  }
  temp <- unique(temp)

  ## export all data for QGIS with all metadata
  if (nrow(temp) < 1) { next() }
  write_sf(temp,
           paste0("~/LOGs/waypoints/wpt_", ar, ".gpx"),
           driver = "GPX", append = F, overwrite = T)

  ## remove a lot of data for GPX devices
  ## TODO you are removing useful info!!
  temp$cmt  <- NA
  temp$desc <- NA
  temp$src  <- NA

  write_sf(temp,
           paste0("~/LOGs/waypoints_etrex//wpt_", ar, ".gpx"),
           driver = "GPX", append = F, overwrite = T)
}

## export all points for QGIS
gather_wpt$Region <- NULL
write_sf(gather_wpt, '~/GISdata/Layers/Gathered_wpt.gpx',
         driver = "GPX", append = F, overwrite = T)

## export all with all metadata
write_sf(gather_wpt, '~/LOGs/waypoints/WPT_ALL.gpx',
         driver = "GPX", append = F, overwrite = T)




##  Compute distance matrix filtered  ------------------------------------------
distm <- raster::pointDistance(p1 = gather_wpt, lonlat = T, allpairs = T)

## find close points
dd <- which(distm < close_flag, arr.ind = T)

## TODO fix table efficiency
# lower.tri()


## remove diagonal
dd <- dd[dd[,1] != dd[,2], ]
cat(paste( nrow(dd), "point couples under", close_flag, "m distance" ),"\n")

## remove pairs 2,3 == 3,2
for (i in 1:nrow(dd)) {
  dd[i, ] = sort(dd[i, ])
}
dd <- unique(dd)
cat(paste( nrow(dd), "point couples under", close_flag, "m distance" ), "\n")


## identify suspects
suspects <- data.table(
  name_A = gather_wpt$name    [dd[,1]],
  geom_A = gather_wpt$geometry[dd[,1]],
  file_A = gather_wpt$desc    [dd[,1]],
  name_B = gather_wpt$name    [dd[,2]],
  geom_B = gather_wpt$geometry[dd[,2]],
  file_B = gather_wpt$desc    [dd[,2]],
  time_A = gather_wpt$time    [dd[,1]],
  time_B = gather_wpt$time    [dd[,2]],
  elev_A = gather_wpt$ele     [dd[,1]],
  elev_B = gather_wpt$ele     [dd[,2]]
)
suspects$Dist <- distm[ cbind(dd[,2], dd[,1]) ]
suspects      <- suspects[order(suspects$Dist, decreasing = T), ]

## ignore points in the same file
suspects <- suspects[name_A != name_B]

## count cases in files
filescnt <- suspects[, .(file_A,file_B) ]
filescnt <- filescnt[, .N , by = (paste(file_A,file_B))]
filescnt$Max_dist <- close_flag
setorder(filescnt, N)
# write.csv(filescnt, "~/GISdata/Layers/Suspect_point_to_clean_filtered.csv", row.names = FALSE)
myRtools::write_dat(object = filescnt,
                    file   = "~/GISdata/Layers/Suspect_point_to_clean_filtered.csv",
                    clean  = TRUE)

wecare <- grep("geom", names(suspects),invert = T,value = T )
wecare <- c("Dist", "name_A", "name_B", "file_A", "file_B")

# write.csv(suspects[,..wecare], "~/GISdata/Suspects_filtered.csv", row.names = FALSE)
myRtools::write_dat(object = suspects[,..wecare],
                    file   = "~/GISdata/Suspects_filtered.csv",
                    clean  = TRUE)


## export all points for GPS devices
gather_wpt$Region <- NULL
gather_wpt$cmt    <- NA
gather_wpt$desc   <- NA
gather_wpt$src    <- NA
write_sf(gather_wpt, '~/LOGs/waypoints_etrex/WPT_ALL.gpx',
         driver = "GPX", append = F, overwrite = T)



#' **END**
#+ include=T, echo=F
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
# if (difftime(tac,tic,units = "sec") > 30) {
#   system("mplayer /usr/share/sounds/freedesktop/stereo/dialog-warning.oga", ignore.stdout = T, ignore.stderr = T)
#   system(paste("notify-send -u normal -t 30000 ", Script.Name, " 'R script ended'"))
# }
