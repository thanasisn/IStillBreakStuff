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


# if (!interactive()) {
  dir.create("~/CODE/gpx_tools/gps_wpt/runtime/", showWarnings = F, recursive = T)
  # pdf( file = paste0("~/CODE/gpx_tools/gps_wpt/runtime/", basename(sub("\\.R$",".pdf", Script.Name))))
  sink(file = paste0("~/CODE/gpx_tools/gps_wpt/runtime/", basename(sub("\\.R$",".out", Script.Name))), split = TRUE)
# }

#+ echo=F, include=T
suppressPackageStartupMessages({
  library(arrow,         quietly = TRUE, warn.conflicts = FALSE)
  library(data.table,    quietly = TRUE, warn.conflicts = FALSE)
  library(dplyr,         quietly = TRUE, warn.conflicts = FALSE)
  library(sf,            quietly = TRUE, warn.conflicts = FALSE)
  library(stringr,       quietly = TRUE, warn.conflicts = FALSE)
  library(stringi,       quietly = TRUE, warn.conflicts = FALSE)
  library(janitor,       quietly = TRUE, warn.conflicts = FALSE)
  library(RecordLinkage, quietly = TRUE, warn.conflicts = FALSE)
  library(stringdist,    quietly = TRUE, warn.conflicts = FALSE)
  library(hunspell,      quietly = TRUE, warn.conflicts = FALSE)
  if (!require("qdap")) {install.packages("qdap")} else {library(qdap)}
})

source("~/CODE/gpx_tools/gps_wpt/DEFINITIONS.R")
source("~/CODE/R_myRtools/myRtools/R/write_.R")

EXPORT <- FALSE
EXPORT <- TRUE  ## for debug

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


cat(paste("\n", nrow(DATA_wpt), "waypoints loaded \n" ))

##  Export unfiltered GPX  -----------------------------------------------------
export_fl <- "~/DATA/GIS/WPT/Gathered_unfilter_wpt.gpx"
copywpt   <- DATA_wpt

## __ Execution control  -------------------------------------------------------
if (EXPORT |
    !file.exists(export_fl) |
    file.mtime(export_fl) < file.mtime(fl_waypoints)) {
  cat("Going on with analysis and export\n")
} else {
  cat("No new data for analysis\n")
  stop(" --- Exit here --- ")
}


## __ Export unfiltered WPT  ---------------------------------------------------
names(copywpt)[names(copywpt) == "file"] <- 'desc'
wec       <- intersect(names(copywpt), wecare)
copywpt   <- copywpt[, wec]
copywpt$urlname <- copywpt$desc

copywpt$ctx_CreationTimeExtension <- NULL
copywpt$wptx1_WaypointExtension   <- NULL
copywpt$gpxx_WaypointExtension    <- NULL

file.remove(export_fl)
EXPORT <- TRUE

## drop data
copywpt$file   <- NULL
copywpt$mtime  <- NULL
copywpt$Region <- NULL
copywpt$type   <- NULL

# copywpt$name      <- copywpt$name_orig
copywpt$name_orig <- NULL

write_sf(copywpt,
         export_fl,
         driver          = "GPX",
         dataset_options = "GPX_USE_EXTENSIONS=YES",
         append          = FALSE,
         overwrite       = TRUE)
cat("Updated file: ", export_fl, "\n")
rm(copywpt)

##  Clean points  --------------------------------------------------------------
DATA_wpt$type <- NULL

## TODO check spell

if (TRUE) {

  # DATA_wpt |> hunspell_check(name)
  #
  #
  # DATA_wpt |> quanteda::tokens(name,
  #                              remove_punct = T,
  #                              remove_numbers = T,
  #                              remove_symbols = T,
  #                              remove_separators = T)
  #
  # DATA_wpt$token <- quanteda::tokens(DATA_wpt$name,
  #                                    remove_punct = T,
  #                                    remove_numbers = T,
  #                                    remove_symbols = T,
  #                                    remove_separators = T)
  #
  # hunspell_check(DATA_wpt$token)

  words <- unique(
    unlist(
      quanteda::tokens(DATA_wpt$name,
                       remove_punct = T,
                       remove_numbers = T,
                       remove_symbols = T,
                       remove_separators = T)
    )
  )

  ## keep big words
  words <- words[nchar(words) > 3]
  ## ignore numbers
  words <- words[!grepl("[0-9]+", words)]


  vec      <- grepl("[Α-Ω]", words, ignore.case = T )
  el_words <- sort(words[ vec])
  en_words <- sort(words[!vec])

  er_en <- data.table(
    words   = en_words,
    correct = hunspell_check(words = en_words,
                             dict = dictionary("en_US"))
  )
  er_en <- er_en[ correct == F, ]

  lld <- lapply(er_en$words, function(x)
    paste(unlist(
      hunspell_suggest(x, dict = dictionary("en_US"))
    ), collapse = ", ")
  )
  er_en$suggest <- unlist(lld)
  er_en <- er_en[suggest != "",]
  er_en$correct <- NULL


  er_gr <- data.table(
    words   = el_words,
    correct = hunspell_check(words = el_words, dict = dictionary("el_GR"))
  )
  er_gr <- er_gr[ correct == F, ]

  lld <- lapply(er_gr$words, function(x)
    paste(unlist(
      hunspell_suggest(x, dict = dictionary("el_GR"))
    ), collapse = ", ")
  )
  er_gr$suggest <- unlist(lld)
  er_gr <- er_gr[suggest != "",]
  er_gr$correct <- NULL

  # for (aw in er_gr$words) {
  #   cat(aw, ":", paste(unlist(hunspell_suggest(aw, dict = dictionary("el_GR"))), collapse = ", "), "\n")
  # }
  #


  ## find error source

  # to_check <- DATA_wpt[!grepl("OSM", DATA_wpt$Src_Type, ignore.case = T), ]
  to_check <- DATA_wpt[grepl("WPT", DATA_wpt$file, ignore.case = T), ]

  for (aw in 1:nrow(er_gr)) {
    temp <- to_check[grepl(er_gr$words[aw], to_check$name), ]
    if (nrow(temp)>0){
      cat(er_gr$words[aw], ":", er_gr$suggest[aw], "\n")
      print(unique(temp$file))
      cat("\n")
    }
  }

  for (aw in 1:nrow(er_en)) {
    temp <- to_check[grepl(er_en$words[aw], to_check$name), ]
    if (nrow(temp)>0){
      cat(er_en$words[aw], ":", er_en$suggest[aw], "\n")
      print(unique(temp$file))
      cat("\n")
    }
  }

}



## __ Remove extra spaces  -----------------------------------------------------
DATA_wpt$name <- gsub("^[ ]+",    "", DATA_wpt$name)
DATA_wpt$name <- gsub("[ ]+$",    "", DATA_wpt$name)
DATA_wpt$name <- gsub("[ ]{2,}", " ", DATA_wpt$name)
# grep("[ ]{2,}", DATA_wpt$name)

## __ Translate names  ---------------------------------------------------------
DATA_wpt$name <- gsub("Aussichtspunkt", "Viewpoint", DATA_wpt$name, ignore.case = T)
DATA_wpt$name <- gsub("Beach",          "Παραλία",   DATA_wpt$name, ignore.case = T)
DATA_wpt$name <- gsub("Vrisi",          "Βρύση",     DATA_wpt$name, ignore.case = T)
DATA_wpt$name <- gsub("pigi",           "Πηγή",      DATA_wpt$name, ignore.case = T)

# stop("DD")
# which(DATA_wpt$name == "tomap")

## __ Drop points by name  -----------------------------------------------------
DATA_wpt <- DATA_wpt[grep(".*Following a path.*",  DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep(".*go straight.*",       DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep(".*χαιντου από μαύρη.*", DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Ankerplatz",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Arrive at.*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Ascending.*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Borderline.*",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Descending.*",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Dromos[0-9]*",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Entry path.*",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Follow it.*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Follow the.*",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("GRA[0-9]+",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("GRE[0-9]*",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Go right.*",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Head [a-z]+",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Intersection",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Monopati erev.*",       DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("PIN[0-9]+",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Parkplatz.*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Path entry.*",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Straight .*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Trail Head",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Turn .*",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("WPT[0-9]+",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("XDRXRD.*",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^[0-9]+!",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^[0-9]+",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^[0-9]+R",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^afeteria$",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^arxh$",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^arxi$",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^aσφμον$",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^dasmon$",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^dexia$",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^dias$",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^end$",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^finish$",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^foto$",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^from$",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^kato$",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^keep .*$",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^photo$",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^scat [0-9]+",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^scat$",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^skat [0-9]+",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^skat$",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^start$",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^strofi$",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^summit$",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^to$",                  DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^Αρκ [0-1]+",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^Αρκ!$",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^Αρκ$",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^γου$",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^γουρ$",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^εδω$",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^εδώ$",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^σκατ$",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("^τριχεσ$",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("arxi monopat",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("asf-xom",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("at roundab",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("go left",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("hotmail.com",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("lap [0-9].*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("life [0-9]+",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("monxom",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("null$",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("pagida *[0-9]+",        DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("pagida a[0-9]+",        DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("tor *[0-9]*",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("via[0-9]+",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("xdr[0-9]+",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Αρχή Μονοπατιού.*",     DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Γουρ!$",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Δείγ Ερθρλ",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Δεξιά",                 DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Διασταυρωση$",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Διασταύρωση Junction",  DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Διασταύρωση",           DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Κάτω δεξιά",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Κατω δεξιά",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Κατω δεξια",            DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Λυκ?",                  DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Μονοπάτι",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("Μονοπατι",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("άσφαλτος",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("από εδώ",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("αριστερά",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("αριστερα",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("αρχή μονοπάτι",         DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("ασφμον",                DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("διαδρομή",              DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("επιστροφή",             DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("κ[0-9]+",               DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("χωματoδρομος",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("χωματόδρομος",          DATA_wpt$name, invert = T, ignore.case = T), ]
DATA_wpt <- DATA_wpt[grep("ως εδώ",                DATA_wpt$name, invert = T, ignore.case = T), ]

## Keep original name
DATA_wpt$name_orig <- DATA_wpt$name

## __ Make consistent names  -----------
DATA_wpt$name <- stri_trans_general(DATA_wpt$name, "Greek-Latin/UNGEGN")

## FIXME capitalize for consistency don't use for ROUT!!
DATA_wpt$name <- str_to_title(DATA_wpt$name)

## Drop unnamed points
DATA_wpt <- DATA_wpt[!is.na(DATA_wpt$name), ]


##  Set icons by name  ---------------------------------------------------------

terms <- c("καταφύγιο", "refuge")
icon <- "lodge"
cat("Set symbol:", icon, "\n")
ids <- unique(unlist(lapply(
  terms,
  function(x) unique(c(agrep(x, DATA_wpt$name, ignore.case = T), agrep(x, DATA_wpt$name_orig, ignore.case = T)))
)))
# DATA_wpt[ids, c("name", "name_orig")]
DATA_wpt$sym[ids] <- icon


terms <- c("κορυφή", "peak")
icon <- "Summit"
cat("Set symbol:", icon, "\n")
ids <- unique(unlist(lapply(
  terms,
  function(x) unique(c(agrep(x, DATA_wpt$name, ignore.case = T), agrep(x, DATA_wpt$name_orig, ignore.case = T)))
)))
# View(DATA_wpt[ids, c("name", "name_orig","file")])
DATA_wpt$sym[ids] <- icon


terms <- c("beach", "paralia", "παραλια")
icon <- "Beach"
cat("Set symbol:", icon, "\n")
ids <- unique(unlist(lapply(
  terms,
  function(x) unique(c(agrep(x, DATA_wpt$name, ignore.case = T), agrep(x, DATA_wpt$name_orig, ignore.case = T)))
)))
# View(DATA_wpt[ids, c("name", "name_orig","file")])
DATA_wpt$sym[ids] <- icon


terms <- c("viewpoint", "θέα")
icon <- "Scenic area"
cat("Set symbol:", icon, "\n")
ids <- unique(unlist(lapply(
  terms,
  function(x) unique(c(grep(x, DATA_wpt$name, ignore.case = T), grep(x, DATA_wpt$name_orig, ignore.case = T)))
)))
# View(DATA_wpt[ids, c("name", "name_orig","file")])
DATA_wpt$sym[ids] <- icon


terms <- c("πηγή", "βρύση", "spring", "ποτίστρα", "νερό", "water")
icon <- "Drinking water"
cat("Set symbol:", icon, "\n")
ids <- unique(unlist(lapply(
  terms,
  function(x) unique(c(agrep(x, DATA_wpt$name, ignore.case = T), agrep(x, DATA_wpt$name_orig, ignore.case = T)))
)))
# View(DATA_wpt[ids, c("name", "name_orig", "sym","file")])
DATA_wpt$sym[ids] <- icon

# terms <- c("scat", "σκατ", "τρίχες", "toros", "τορός")
# icon <- "Campground"
# cat("Set symbol:", icon, "\n")
# ids <- unique(unlist(lapply(
#   terms,
#   function(x) unique(c(grep(x, DATA_wpt$name, ignore.case = T), grep(x, DATA_wpt$name_orig, ignore.case = T)))
# )))
# View(DATA_wpt[ids, c("name", "name_orig", "sym","file")])
# DATA_wpt$sym[ids] <- icon

terms <- c("camp", "κατασκήνωση")
icon <- "Campground"
cat("Set symbol:", icon, "\n")
ids <- unique(unlist(lapply(
  terms,
  function(x) unique(c(grep(x, DATA_wpt$name, ignore.case = T), grep(x, DATA_wpt$name_orig, ignore.case = T)))
)))
# View(DATA_wpt[ids, c("name", "name_orig", "sym","file")])
DATA_wpt$sym[ids] <- icon


terms <- c("διασταυρωση", "crossin")
icon <- "Crossing"
cat("Set symbol:", icon, "\n")
ids <- unique(unlist(lapply(
  terms,
  function(x) unique(c(agrep(x, DATA_wpt$name, ignore.case = T), agrep(x, DATA_wpt$name_orig, ignore.case = T)))
)))
# DATA_wpt[ids, c("name", "name_orig")]
DATA_wpt$sym[ids] <- icon


terms <- c("αδιέξοδο", "dead end")
icon <- "Circle with x"
cat("Set symbol:", icon, "\n")
ids <- unique(unlist(lapply(
  terms,
  function(x) unique(c(agrep(x, DATA_wpt$name, ignore.case = T), agrep(x, DATA_wpt$name_orig, ignore.case = T)))
)))
# View(DATA_wpt[ids, c("name", "name_orig", "sym","file")])
DATA_wpt$sym[ids] <- icon


terms <- c("tomap")
icon <- "Flag, Green"
cat("Set symbol:", icon, "\n")
ids <- unique(unlist(lapply(
  terms,
  function(x) unique(c(grep(x, DATA_wpt$name, ignore.case = T), grep(x, DATA_wpt$name_orig, ignore.case = T)))
)))
# View(DATA_wpt[ids, c("name", "name_orig", "sym","file")])
DATA_wpt$sym[ids] <- icon


## __ Distance test  -----------------------------------------------------------

## test exact location dupes
exact_dupes <- get_dupes(
  DATA_wpt |>
    filter(!grepl("Plans/ROUT", file)),
  geometry)

cat("There are", nrow(exact_dupes), "exact location dupes\n")


## work on distinct names and places
DATA_wpt <- DATA_wpt |>
  filter( !grepl("Plans/ROUT", file)) |>
  distinct_at(vars(name, geometry), .keep_all = TRUE)

##  Compute distance matrix for all pairs
distm <- raster::pointDistance(p1 = DATA_wpt, lonlat = T, allpairs = T)

##  Investigate closest
dd <- which(distm < close_flag, arr.ind = T)
## remove diagonal
dd <- dd[dd[,1] != dd[,2], ]

## remove pairs 2,3 == 3,2
for (i in 1:nrow(dd)) {
  dd[i, ] = sort(dd[i, ])
}
dd <- unique(dd)

cat(nrow(dd), "point pairs under", close_flag, "m distance\n")



stop("kkkkk")


## __ Check suspect points  ----------------------------------------------------
suspects <- data.table(
  name_A = DATA_wpt$name     [dd[,1]],
  name_B = DATA_wpt$name     [dd[,2]],
  orig_A = DATA_wpt$name_orig[dd[,1]],
  orig_B = DATA_wpt$name_orig[dd[,2]],
  file_A = DATA_wpt$file     [dd[,1]],
  file_B = DATA_wpt$file     [dd[,2]],
  geom_A = DATA_wpt$geometry [dd[,1]],
  geom_B = DATA_wpt$geometry [dd[,2]],
  elev_A = DATA_wpt$ele      [dd[,1]],
  elev_B = DATA_wpt$ele      [dd[,2]],
  # time_A = DATA_wpt$time     [dd[,1]],
  id_A   = dd[,1],
  # time_B = DATA_wpt$time     [dd[,2]],
  id_B   = dd[,2]
)
suspects$Dist <- distm[cbind(dd[,2], dd[,1])]
suspects      <- suspects[order(suspects$Dist, decreasing = T), ]


## remove all this from data
torem <- suspects[ name_A == name_B & Dist < 5 ]

## if A and B remove one
for (al in 1:nrow(torem)) {
  ll <- torem[al, ]

  ## if both points exist remove B geometry
  if ((DATA_wpt[ll$id_A,]$geometry == ll$geom_A) & (
       DATA_wpt[ll$id_B,]$geometry == ll$geom_B)) {

    DATA_wpt |> mutate()
    DATA_wpt[ll$id_B, name]   <- NA
    DATA_wpt[ll$id_B, "Region"] <- NA
  }

  ## also remove from suspects?
  suspects <- suspects[!suspects$geom_B == ll$geom_B & suspects$id_B == ll$id_B & suspects$id_A == ll$id_A]

}
## clean removed poinst
is.na(DATA_wpt$geometry)

stop()


## FIXME change method
# suspects$S_Dist <- levenshteinDist(suspects$name_A, suspects$name_B)
suspects$S_Sim  <- levenshteinSim(suspects$name_A, suspects$name_B)

## ignore points in the same file
suspects <- suspects[name_A != name_B]


setorder(suspects, S_Sim)

## reformat for faster cvs use
suspects$time_A <- format(suspects$time_A, "%FT%R:%S")
suspects$time_B <- format(suspects$time_B, "%FT%R:%S")

gdata::write.fwf(suspects[, c("Dist",   "S_Sim",
                              "name_A", "name_B",
                              "orig_A", "orig_B",
                              "file_A", "file_B")],
                 sep  = ";", quote = TRUE,
                 file = "~/DATA/GIS/WPT/Suspects_wpt.csv")


## count cases in files
filescnt <- suspects[, .(file_A, file_B)]
filescnt <- filescnt[, .N, by = (paste(file_A, file_B))]
filescnt$Max_dist <- close_flag
setorder(filescnt, N)
gdata::write.fwf(filescnt,
                 sep  = ";", quote = TRUE,
                 file = "~/DATA/GIS/WPT/Suspect_wpt_to_clean.csv")

## export suspects
ex_sus <- rbind(
  DATA_wpt[dd[,2],],
  DATA_wpt[dd[,1],]
) |> distinct()

write_sf(ex_sus,
         "~/DATA/GIS/WPT/Suspects_wpt.gpx",
         driver          = "GPX",
         dataset_options = "GPX_USE_EXTENSIONS=YES",
         append          = FALSE,
         overwrite       = TRUE)


##  Export filtered GPX for usage  ---------------------------------------------

## deduplicate WPT
DATA_wpt <- DATA_wpt |> distinct_at(vars(name, geometry), .keep_all = T)

## rename vars
DATA_wpt$desc <- NULL
names(DATA_wpt)[names(DATA_wpt) == "file"] <- 'desc'

## drop data
DATA_wpt$file  <- NULL
DATA_wpt$mtime <- NULL

DATA_wpt$name      <- DATA_wpt$name_orig
DATA_wpt$name_orig <- NULL

## characterize missing regions
DATA_wpt$Region[is.na(DATA_wpt$Region)] <- "Other"

cat(paste("\n", nrow(DATA_wpt), "waypoints after filtering\n" ))

## ignore some waypoints files not relevant for our usage
drop_files <- c(
  "grammos2012/Acquired_from_GPS.gpx",
  "WPT_hair_traps_rodopi_2015-06-28.gpx",
  "WPT_stanes_rodopi.gpx"
)

for (ast in drop_files) {
  DATA_wpt <- DATA_wpt |> filter(!grepl(ast, desc))
}


##  Export GPX waypoints by region  --------------------------------------------
for (ar in unique(DATA_wpt$Region)) {

  temp        <- DATA_wpt[DATA_wpt$Region == ar, ]
  temp$Region <- NULL
  temp        <- temp[order(temp$name), ]
  wec         <- intersect(names(temp), wecare)

  cat(paste("export", nrow(temp), "wpt", ar, "\n"))

  ## export all data for QGIS with all metadata
  if (nrow(temp) < 1) { next() }

  write_sf(temp[, wec],
           paste0("~/LOGs/waypoints/wpt_", ar, ".gpx"),
           driver = "GPX", append = F, overwrite = T)

  ## remove a lot of data for GPX devices
  ## TODO you are removing useful info!!
  temp$cmt  <- NA
  temp$desc <- NA
  temp$src  <- NA

  write_sf(temp[, wec],
           paste0("~/LOGs/waypoints_etrex/wpt_", ar, ".gpx"),
           driver = "GPX", append = F, overwrite = T)
}

## export all points for QGIS with more data
write_sf(DATA_wpt,
         '~/DATA/GIS/WPT/Gathered_filtered_wpt.gpx',
         driver          = "GPX",
         dataset_options = "GPX_USE_EXTENSIONS=YES",
         append          = FALSE,
         overwrite       = TRUE)

## export all with few metadata
wec <- intersect(names(DATA_wpt), wecare)
wec <- grep("Region", wec, invert = T, value = T)

write_sf(DATA_wpt[, wec],
         '~/LOGs/waypoints_etrex/WPT_ALL.gpx',
         driver          = "GPX",
         append          = FALSE,
         overwrite       = TRUE)

write_sf(DATA_wpt,
         '~/LOGs/waypoints/WPT_ALL.gpx',
         driver          = "GPX",
         dataset_options = "GPX_USE_EXTENSIONS=YES",
         append          = FALSE,
         overwrite       = TRUE)



## export by source
for (st in unique(DATA_wpt$Src_Type)) {
  temp <- DATA_wpt |> filter(Src_Type == st)
  temp <- temp[, wec]
  temp$Region <- NULL
  wec  <- intersect(names(temp), wecare)

  cat(paste("export", nrow(temp), "wpt", st, "\n"))

  ## export all data for QGIS with all metadata
  if (nrow(temp) < 1) { next() }


  write_sf(temp,
           paste0("~/LOGs/waypoints/", st, "_WPT.gpx"),
           driver          = "GPX",
           dataset_options = "GPX_USE_EXTENSIONS=YES",
           append          = F,
           overwrite       = T)

  temp$cmt  <- NA
  temp$desc <- NA
  temp$src  <- NA

  write_sf(temp[, wec],
           paste0("~/LOGs/waypoints_etrex/", st, "_WPT.gpx"),
           driver = "GPX",
           append = F,
           overwrite = T)



}





#' **END**
#+ include=T, echo=F
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
