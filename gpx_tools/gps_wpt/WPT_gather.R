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

source("~/CODE/gpx_tools/gps_wpt/DEFINITIONS.R")
source("~/CODE/R_myRtools/myRtools/R/write_.R")


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

  ## keep existing files with not modified date
  DATA <- DATA[file.exists(DATA$file) & file.mtime(DATA$file) == mtime ]

  ## ignore existing and not modified files from reading
  gpxlist <- gpxlist[ !(file %in% DATA$file & mtime %in% DATA$mtime) ]

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

    meta <- data.table(file   = path.expand(af),
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

  meta <- data.table(file   = path.expand(dw_fl),
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

  meta <- data.table(file   = path.expand(dw_fl),
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

  meta <- data.table(file   = path.expand(dw_fl),
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
DATA <- DATA |> distinct()


##  ID regions  ----------------------------------------------------------------

##  Read regions
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

## store for all R  ------------------------------------------------------------
DATA <- DATA |> distinct()
write_RDS(DATA, fl_waypoints)

pander::pander(table(DATA$Region))

#' **END**
#+ include=T, echo=F
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
# if (difftime(tac,tic,units = "sec") > 30) {
#   system("mplayer /usr/share/sounds/freedesktop/stereo/dialog-warning.oga", ignore.stdout = T, ignore.stderr = T)
#   system(paste("notify-send -u normal -t 30000 ", Script.Name, " 'R script ended'"))
# }
