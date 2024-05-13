# /* #!/usr/bin/env Rscript */
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
Script.Name <- "./parse_garmin_fit.R"
tic <- Sys.time()

if (!interactive()) {
  dir.create("./runtime/", showWarnings = F, recursive = T)
  pdf( file = paste0("./runtime/", basename(sub("\\.R$",".pdf", Script.Name))))
}

#+ echo=F, include=T
library(FITfileR,   quietly = TRUE, warn.conflicts = FALSE)
library(data.table, quietly = TRUE, warn.conflicts = FALSE)
library(arrow,      quietly = TRUE, warn.conflicts = FALSE)
library(tibble,     quietly = TRUE, warn.conflicts = FALSE)
library(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
library(sf,         quietly = TRUE, warn.conflicts = FALSE)
library(trip,       quietly = TRUE, warn.conflicts = FALSE)




DATASET    <- "/home/athan/DATA/Other/Track_points"
BATCH      <- 50
## unzip in memory
tempfl     <- "/dev/shm/tmp_fit/"
EPSG_WGS84 <- 4326
EPSG       <- 3857


if (file.exists(DATASET)) {
  DB <- open_dataset(DATASET,
                     partitioning  = c("year"),
                     unify_schemas = T)
  db_rows <- unlist(DB |> tally() |> collect())
} else {
  stop("Init DB manually!")
}


#; ## remove deleted files
#; ## TODO test
#;
#; test <- DB |>
#;   select(filename, year, month) |>
#;   unique()  |>
#;   collect() |>
#;   data.table()
#;
#; test[, exist := file.exists(filename)]
#; test <- test[exist == F, ]
#;
#; if (nrow(test) > 0) {
#;
#;   DB |> count() |> collect()
#;
#;   ## drop missing files data from dataset
#;   # DB <- DB |> filter(!filename %in% test[exist == F, filename]) |> collect()
#;
#;
#;   edit <- unique(test[, year, month])
#;
#;
#;   # DB |> filter(year %in% edit$year & month %in% edit$month) |> count() |> collect()
#;
#;   DB |> filter(year %in% edit$year &
#;                  month %in% edit$month &
#;                  !filename %in% test[exist == F, filename]) |> count() |> collect()
#;
#;   ## re write only parts that have removed data
#;   write_dataset(DB |> filter(year %in% edit$year &
#;                                month %in% edit$month &
#;                                !filename %in% test[exist == F, filename]),
#;                 DATASET,
#;                 compression            = "lz4",
#;                 compression_level      = 5,
#;                 format                 = "parquet",
#;                 partitioning           = c("year", "month"),
#;                 existing_data_behavior = "delete_matching",
#;                 hive_style             = F)
#;
#; }


## total points
cat(paste(DB |> count() |> collect()), "\n")


# ## sanity points
# TP <- DB |> filter(time > as.POSIXct("1971-01-01") & !is.na(time))
# cat(paste(TP |> count() |> collect()), "\n")




sameday <- DB |>
  select(filename, time) |>
  mutate(time = as.Date(time)) |>
  unique() |> collect() |> data.table()



samedays <- sameday[, .N, by = time]
samedays <- samedays[N > 1, time]

## check in common days files
for (ad in samedays) {

  yy   <- year(ad)
  test <- DB |> filter(year == yy & as.Date(time) == as.Date(ad)) |> collect()

  dups <- duplicated(test[, .(Xdeg, Ydeg, time)])
  if (any(dups)) {

    cat(unique(test[dups, filename]), sep = "\n")
    cat("\n")

    # test[dups,]

  }

}





## files on same date
test <- DB |>
  select(filename, time, sport, name, sub_sport, source) |>
  mutate(time = as.Date(time)) |>
  unique() |> collect() |> data.table()



test_d <- test[, .N, by = time]

test <- test[time %in% test_d[N>1, time]]


























## remove tmp dir
unlink(tempfl, recursive = T)
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
#               partitioning = c("year", "month"),
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
