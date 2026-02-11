#!/usr/bin/env Rscript
# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "`r format(Sys.time(), '%F %T')`"
#' author: ""
#' output:
#'   html_document:
#'     toc: true
#'     fig_width:  6
#'     fig_height: 4
#'     keep_md:    no
#' date: ""
#' ---

#+ echo=F, include=F
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/data_streams/S01_location_find.R"

## __ Document options ---------------------------------------------------------
knitr::opts_chunk$set(out.width  = "100%"   )

## __  Set environment ---------------------------------------------------------
require(data.table, quietly = TRUE, warn.conflicts = FALSE)
require(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
require(janitor,    quietly = TRUE, warn.conflicts = FALSE)
require(lubridate,  quietly = TRUE, warn.conflicts = FALSE)


source("~/CODE/data_streams/DEFINITIONS.R")
source("~/CODE/data_streams/helpers/fn_get_gpx_last_location.R")
source("~/CODE/data_streams/helpers/fn_reverse_geocode_osm.R")


filelist <- list.files(path        = gpx_dir,
                       pattern     = "*.gpx",
                       full.names  = TRUE,
                       ignore.case = TRUE)

DT <- data.table(File = filelist,
                 mtime = file.mtime(filelist))

DT[, Date := ymd(sub("\\..*", "", sub("^.*_", "", basename(File))))]

setorder(DT, mtime)

## select last updated file
File <- DT[mtime == max(mtime), File ]

# select last date file
File <- DT[Date == max(Date), File ]


# get location
myloc <- get_gpx_last_location(File, last_minutes = last_gpx_mins)

# get address
myadd <- reverse_geocode_osm(lat = myloc$median_lat, lon =  myloc$median_lon)






#+ include=T, echo=F, results="asis"
tac <- Sys.time()
cat(sprintf("**END** %s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))

