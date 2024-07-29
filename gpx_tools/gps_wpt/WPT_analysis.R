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
Script.Name <- "~/CODE/gpx_tools/gps_wpt/WPT_analysis.R"

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
  library(stringi,    quietly = TRUE, warn.conflicts = FALSE)
  library(janitor,    quietly = TRUE, warn.conflicts = FALSE)
})

source("~/CODE/gpx_tools/gps_wpt/DEFINITIONS.R")
source("~/CODE/R_myRtools/myRtools/R/write_.R")

# options(warn = 1)

if (file.exists(fl_waypoints)) {
  DATA <- readRDS(fl_waypoints)
  DATA <- st_as_sf(DATA)
} else {
  stop("No input file\n")
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


## remove dummy data for analysis ####
valid_wpt  <- !st_is_empty(st_sfc(DATA$geometry))
DATA_wpt   <- DATA[ valid_wpt, ]
DATA_empty <- DATA[!valid_wpt, ]

## project to degrees
DATA_wpt <- st_transform(DATA_wpt, EPSG_WGS84)

cat(paste("\n", nrow(DATA_wpt), "waypoints loaded \n\n" ))


##  Export unfiltered GPX  -----------------------------------------------------
export_fl <- '~/DATA/GIS/WPT/Gathered_unfilter_wpt.gpx'
copywpt   <- DATA_wpt

names(copywpt)[names(copywpt) == "file"] <- 'desc'
wec       <- intersect(names(copywpt), wecare)
copywpt   <- copywpt[, wec]
copywpt$urlname <- copywpt$desc

copywpt$ctx_CreationTimeExtension <- NULL
copywpt$wptx1_WaypointExtension   <- NULL
copywpt$gpxx_WaypointExtension    <- NULL

if (!file.exists(export_fl) | any(copywpt$mtime > file.mtime(export_fl))) {
  file.remove(export_fl)

  ## drop data
  copywpt$file   <- NULL
  copywpt$mtime  <- NULL
  copywpt$Region <- NULL

  write_sf(copywpt,
           export_fl,
           driver    = "GPX",
           dataset_options = "GPX_USE_EXTENSIONS=YES",
           append    = F,
           overwrite = T)
  cat("Updated file: ", export_fl, "\n")
}
rm(copywpt)


##  Clean points  --------------------------------------------------------------


## __ Remove extra spaces  -----------------------------------------------------
DATA_wpt$name <- gsub("^[ ]+",    "", DATA_wpt$name)
DATA_wpt$name <- gsub("[ ]+$",    "", DATA_wpt$name)
DATA_wpt$name <- gsub("[ ]{2,}", " ", DATA_wpt$name)

# grep("[ ]{2,}", DATA_wpt$name)


## __ Translate names  ---------------------------------------------------------
DATA_wpt$name <- gsub("Aussichtspunkt", "Viewpoint", DATA_wpt$name)

## __ Drop points by name  -----------------------------------------------------
DATA_wpt <- DATA_wpt[grep(".*Following a path.*",                         DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep(".*go straight.*",                              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep(".*χαιντου από μαύρη.*",                        DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Ankerplatz[[:space:]]*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Arrive at.*",                      DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Ascending.*",                      DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Borderline.*",                     DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Descending.*",                     DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Dromos[0-9]*[[:space:]]*",         DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Entry path.*",                     DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Follow it.*",                      DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Follow the.*",                     DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*GRA[0-9]+[[:space:]]*",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*GRE[0-9]*[[:space:]]*",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Go[[:space:]]*right.*",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Head [a-z]+",                      DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Monopati erev.*",                  DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*PIN[0-9]+[[:space:]]*",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Parkplatz.*",                      DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Path entry.*",                     DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Straight .*",                      DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Trail Head[[:space:]]*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Turn .*",                          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*WPT[0-9]+[[:space:]]*",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*XDRXRD.*[[:space:]]*",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*[0-9]+![[:space:]]*",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*[0-9]+R",                          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*[0-9]+[[:space:]]*",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*arxh",                             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*arxi[[:space:]]*",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*asf-xom[[:space:]]*",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*at roundab[[:space:]]*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*aσφμον[[:space:]]*",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*dasmon[[:space:]]*",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*dexia[[:space:]]*",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*dias[[:space:]]*",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*end$",                             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*finish[[:space:]]*",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*foto[[:space:]]*",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*from[[:space:]]*",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*go left[[:space:]]*",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*hotmail.com",                      DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*kato[[:space:]]*",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*keep .*",                          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*lap [0-9].*[[:space:]]*",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*life [0-9]+",                      DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*monxom[[:space:]]*",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*null$",                            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*pagida *[0-9]+[[:space:]]*",       DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*pagida a[0-9]+[[:space:]]*",       DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*photo",                            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*photo[[:space:]]*",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*scat [0-9]+[[:space:]]*",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*scat$",                            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*skat [0-9]+[[:space:]]*",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*skat[[:space:]]*",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*start[[:space:]]*",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*strofi[[:space:]]*",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*summit[[:space:]]*",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*to[[:space:]]*",                   DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*tor *[0-9]*[[:space:]]*",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*via[0-9]+[[:space:]]*",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*xdr[0-9]+[[:space:]]*",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Αρκ [0-1]+[[:space:]]*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Αρκ![[:space:]]*",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Αρκ[[:space:]]*",                  DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Αρχή Μονοπατιού.*[[:space:]]*",    DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Γουρ!$",                           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Δείγ Ερθρλ",                       DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Δεξιά[[:space:]]*",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Διασταυρωση$",                     DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Διασταύρωση Junction[[:space:]]*", DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Διασταύρωση[[:space:]]*",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Κάτω δεξιά[[:space:]]*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Κατω δεξιά[[:space:]]*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Κατω δεξια[[:space:]]*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Λυκ?",                             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Μονοπάτι[[:space:]]*",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*Μονοπατι[[:space:]]*",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*άσφαλτος[[:space:]]*",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*από εδώ[[:space:]]*",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*αριστερά[[:space:]]*",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*αριστερα[[:space:]]*",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*αρχή μονοπάτι[[:space:]]*",        DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*ασφμον[[:space:]]*",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*γου[[:space:]]*",                  DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*γουρ[[:space:]]*",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*διαδρομή[[:space:]]*",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*εδω[[:space:]]*",                  DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*εδώ[[:space:]]*",                  DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*κ[0-9]+[[:space:]]*",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*σκατ[[:space:]]*",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*τριχεσ[[:space:]]*",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*χωματoδρομος[[:space:]]*",         DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*χωματόδρομος[[:space:]]*",         DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("[[:space:]]*ως εδώ[[:space:]]*",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("hotmail.com",                                  DATA_wpt$name, invert = T, ignore.case = T), ]

## Keep original name
DATA_wpt$name_orig <- DATA_wpt$name

## __ Make consistent names  -----------
DATA_wpt$name <- stri_trans_general(DATA_wpt$name, "Greek-Latin/UNGEGN")

## FIXME capitalize for consistency don't use for ROUT!!
DATA_wpt$name <- str_to_title(DATA_wpt$name)



## __ Distance test  ---------

DATA_wpt |> distinct_at(vars(name,geometry))

exact_dupes <- get_dupes(DATA_wpt, name,geometry)

##  Compute distance matrix
distm <- raster::pointDistance(p1 = DATA_wpt, lonlat = T, allpairs = T)
distm <- round(distm, digits = 3)


stop("ggg")




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
