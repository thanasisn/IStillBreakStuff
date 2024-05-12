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
Script.Name <- "./parse_gpx.R"
tic <- Sys.time()

if (!interactive()) {
  dir.create("./runtime/", showWarnings = F, recursive = T)
  pdf( file = paste0("./runtime/", basename(sub("\\.R$",".pdf", Script.Name))))
}

#+ echo=F, include=T
library(data.table, quietly = TRUE, warn.conflicts = FALSE)
library(stringr,    quietly = TRUE, warn.conflicts = FALSE)
library(R.utils,    quietly = TRUE, warn.conflicts = FALSE)
# library(tibble,     quietly = TRUE, warn.conflicts = FALSE)
library(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
# library(sf,         quietly = TRUE, warn.conflicts = FALSE)
# library(trip,       quietly = TRUE, warn.conflicts = FALSE)


repo  <- "~/TRAIN/GoldenCheetah/Athan/imports/"
tempd <- "/dev/shm/tempcleangoldche/"


filelist <- list.files(path = repo,
                       full.names = T)

table(tools::file_ext(filelist))


activs <- grep("activity", filelist, ignore.case = T, value = T)

files <- data.frame(
  files = activs,
  id    = str_extract(basename(activs), "[0-9]{5,}"),
  size  = file.size(activs)
)



files$type <- sapply(files$files,
                     function(x) {
                       strsplit(
                         system(paste("file -b -z -i", x), intern = TRUE),
                         split = ";")[[1]][1]
                     },
                     simplify  = T,
                     USE.NAMES = F
)

aid   <- files |> count(id) |> filter(n > 1)

files <- data.table(files |> filter(id %in% aid$id))

table(tools::file_ext(files$files))


for (ai in unique(files$id)) {
  files[id == ai]

}

files |> filter(type == "text/xml") |> summarise(sum(size)) / 1024 / 1024




stop()

#' **END**
#+ include=T, echo=F
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
if (difftime(tac,tic,units = "sec") > 30) {
  system("mplayer /usr/share/sounds/freedesktop/stereo/dialog-warning.oga", ignore.stdout = T, ignore.stderr = T)
  system(paste("notify-send -u normal -t 30000 ", Script.Name, " 'R script ended'"))
}
