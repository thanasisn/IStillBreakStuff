
####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- funr::sys.script()
if (!interactive()) pdf(file = sub("\\.R$", ".pdf", Script.Name), width = 14)
sink(file = sub("\\.R$", ".out", Script.Name), split = TRUE)


## read vars
source("~/CODE/gpx_tools/gpx_db/DEFINITIONS.R")

options(warn = 1)


gpx_repo     <- "~/GISdata/GPX/"

wpt_seed     <- "~/GISdata/seed2.Rds"
wpt_seed3    <- "~/GISdata/seed3.Rds"

DRINKING_WATER <- TRUE
WATERFALLS     <- TRUE
CAVES          <- TRUE

update         <- FALSE













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
gather_wpt <- gather_wpt[grep("[[:space:]]*τριχεσ[[:space:]]*",               gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*χωματoδρομος[[:space:]]*",         gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*χωματόδρομος[[:space:]]*",         gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("[[:space:]]*ως εδώ[[:space:]]*",               gather_wpt$name, invert = T, ignore.case = T), ]
gather_wpt <- gather_wpt[grep("hotmail.com",                                  gather_wpt$name, invert = T, ignore.case = T), ]


gather_wpt <- unique(gather_wpt)

ttt <- table(gather_wpt$name)

cat(paste("\n", nrow(gather_wpt),"waypoints after filtering \n\n" ))



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
