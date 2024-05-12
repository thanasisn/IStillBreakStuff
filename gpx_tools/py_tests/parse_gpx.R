#!/usr/bin/env Rscript
# /* Copyright (C) 2022 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:         "hhh "
#' author:
#'   - Natsis Athanasios^[natsisphysicist@gmail.com]
#'
#' documentclass:  article
#' classoption:    a4paper,oneside
#' fontsize:       10pt
#' geometry:       "left=0.5in,right=0.5in,top=0.5in,bottom=0.5in"
#' link-citations: yes
#' colorlinks:     yes
#'
#' header-includes:
#' - \usepackage{caption}
#' - \usepackage{placeins}
#' - \captionsetup{font=small}
#'
#' output:
#'   bookdown::pdf_document2:
#'     number_sections: no
#'     fig_caption:     no
#'     keep_tex:        yes
#'     latex_engine:    xelatex
#'     toc:             yes
#'     toc_depth:       4
#'     fig_width:       7
#'     fig_height:      4.5
#'   html_document:
#'     toc:             true
#'     keep_md:         yes
#'     fig_width:       7
#'     fig_height:      4.5
#'
#' date: "`r format(Sys.time(), '%F')`"
#'
#' ---

#+ echo=F, include=T

## __ Document options  --------------------------------------------------------

#+ echo=FALSE, include=TRUE
knitr::opts_chunk$set(comment    = ""       )
knitr::opts_chunk$set(dev        = c("pdf", "png")) ## expected option
# knitr::opts_chunk$set(dev        = "png"    )       ## for too much data
knitr::opts_chunk$set(out.width  = "100%"   )
knitr::opts_chunk$set(fig.align  = "center" )
knitr::opts_chunk$set(cache      =  FALSE   )  ## !! breaks calculations
knitr::opts_chunk$set(fig.pos    = '!h'     )

#+ echo=FALSE, include=TRUE
## __ Set environment  ---------------------------------------------------------
Sys.setenv(TZ = "UTC")
Script.Name <- "./parse_gpx.R"
tic <- Sys.time()

if (!interactive()) {
  dir.create("./runtime/", showWarnings = F, recursive = T)
  pdf( file = paste0("./runtime/", basename(sub("\\.R$",".pdf", Script.Name))))
}

#+ echo=F, include=T
library(data.table, quietly = TRUE, warn.conflicts = FALSE)
library(arrow,      quietly = TRUE, warn.conflicts = FALSE)
library(tibble,     quietly = TRUE, warn.conflicts = FALSE)
library(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
library(sf,         quietly = TRUE, warn.conflicts = FALSE)
library(trip,       quietly = TRUE, warn.conflicts = FALSE)
library(filelock,   quietly = TRUE, warn.conflicts = FALSE)


#'
#' https://msmith.de/FITfileR/articles/FITfileR.html
#'
#' Have to run it manually for the first time to init the DB
#'

DATASET    <- "/home/athan/DATA/Other/Track_points"
BATCH      <- 100
EPSG_WGS84 <- 4326
EPSG       <- 3857

## make sure only one parser is working
lock(paste0(DATASET, ".lock"), exclusive = TRUE, timeout = 2000)

if (file.exists(DATASET)) {
  DB <- open_dataset(DATASET,
                     partitioning  = c("year"),
                     unify_schemas = T)
  db_rows <- unlist(DB |> tally() |> collect())
} else {
  stop("Init DB manually!")
}


## Get from GPX repo
expfiles <- list.files(path        = "~/GISdata/GPX/",
                       pattern     = "*.gpx",
                       recursive   = T,
                       ignore.case = T,
                       full.names  = T)

expfiles <- grep("\\/Points\\/", expfiles, invert = T, value = T)
expfiles <- grep("\\/Plans\\/", expfiles, invert = T, value = T)

## work on new files only
wehave   <- DB |> select(filename) |> unique() |> collect()
expfiles <- expfiles[!expfiles %in% wehave$filename]
expfiles <- sort(expfiles, decreasing = T)


## Get from Goldencheetah
golfiles <- list.files(path        = "~/TRAIN/GoldenCheetah/Athan/imports/",
                       pattern     = "*.gpx",
                       recursive   = T,
                       ignore.case = T,
                       full.names  = T)

## work on new files only
wehave   <- DB |> select(filename) |> unique() |> collect()
golfiles <- golfiles[!golfiles %in% wehave$filename]
golfiles <- sort(golfiles, decreasing = T)



if (length(expfiles) < 1 & length(golfiles) < 1) {
  cat("\nNO NEW FILES TO PARSE!!\n\n")
  stop()
} else {
  cat("\nFiles to parse:", length(expfiles)+length(golfiles), "\n\n")
}

## test
# expfiles <- head(expfiles, n = 10)

if (length(expfiles) > BATCH) {
  # expfiles <- sample(expfiles, BATCH)
  expfiles <- c(head(expfiles, BATCH),
                head(golfiles, BATCH))
}



gather <- data.table()
for (af in expfiles) {
  cat(af,"\n")

  # temp <- read_sf( gunzip(af, remove = FALSE, temporary = TRUE, skip = TRUE ),
  #                  layer = "track_points")

  temp <- read_sf(af,
                  layer = "track_points")

  ## This assumes that dates in file are correct.......
  temp <- temp[ order(temp$time, na.last = FALSE), ]
  if (nrow(temp)<2) { next() }

  names(temp)[names(temp) == "src"] <- "source"
  names(temp)[names(temp) == "ele"] <- "Z"

  ## keep initial coordinates
  latlon <- st_coordinates(temp$geometry)
  latlon <- data.table(latlon)
  names(latlon)[names(latlon) == "X"] <- "Xdeg"
  names(latlon)[names(latlon) == "Y"] <- "Ydeg"

  ## add distance between points in meters
  temp$dist <- c(0, trackDistance(st_coordinates(temp$geometry), longlat = TRUE)) * 1000

  ## add time between points
  temp$timediff <- 0
  for (i in 2:nrow(temp)) {
    temp$timediff[i] <- difftime( temp$time[i], temp$time[i-1] )
  }

  ## create speed
  temp <- temp |> mutate(kph = (dist/1000) / (timediff/3600)) |> collapse()

  # st_crs(EPSG)
  ## parse coordinates for process in meters
  temp   <- st_transform(temp, crs = EPSG)
  trkcco <- st_coordinates(temp)
  temp   <- data.table(temp)
  temp$X <- unlist(trkcco[,1])
  temp$Y <- unlist(trkcco[,2])
  temp   <- cbind(temp, latlon)

  re <- temp[, .(time,
                 X, Y, Z,
                 Xdeg, Ydeg,
                 dist, timediff, kph,
                 filename  = af,
                 F_mtime   = file.mtime(af),
                 name      = "gpx file",
                 sport     = as.character(NA),
                 sub_sport = as.character(NA),
                 source
  )]

  re[, year  := year(time)  ]

  gather <- rbind(gather, re)
}

## set data types as in arrow
attr(gather$time, "tzone") <- "UTC"
gather[, year  := as.integer(year) ]

## merge all rows
DB <- DB |> full_join(gather) |> compute()

cat("\nNew rows:", nrow(DB) - db_rows, "\n")

## write only new months within gather
new <- unique(gather[, year])

cat("\nUpdate:", new, "\n")

write_dataset(DB |> filter(year %in% new),
              DATASET,
              compression            = "lz4",
              compression_level      = 5,
              format                 = "parquet",
              partitioning           = c("year"),
              existing_data_behavior = "delete_matching",
              hive_style             = F)





DB |> select(filename) |> unique() |> collect() |> nrow()

DB |> summarise(n = n()) |> collect()

DB |> count(filename) |> collect()

DB |> count(source) |> collect()

DB |> count(sport) |> collect()

DB |> count(sport, sub_sport) |> collect()

DB |> count(sub_sport) |> collect()

DB |> count(sport, filename) |> collect()

DB |> tally() |> collect()


# stop()
# write_dataset(gather,
#               DATASET,
#               compression            = "lz4",
#               compression_level      = 5,
#               format       = "parquet",
#               partitioning = c("year"),
#               existing_data_behavior = "delete_matching",
#               hive_style   = F)




#' **END**
#+ include=T, echo=F
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
if (difftime(tac,tic,units = "sec") > 30) {
  system("mplayer /usr/share/sounds/freedesktop/stereo/dialog-warning.oga", ignore.stdout = T, ignore.stderr = T)
  system(paste("notify-send -u normal -t 30000 ", Script.Name, " 'R script ended'"))
}
