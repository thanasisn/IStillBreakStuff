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
Script.Name <- "./read_fit.R"
tic <- Sys.time()

if (!interactive()) {
  pdf( file = paste0("./runtime/", basename(sub("\\.R$",".pdf", Script.Name))))
}

#+ echo=F, include=T
library(FITfileR, quietly = TRUE, warn.conflicts = FALSE)



#'
#' https://msmith.de/FITfileR/articles/FITfileR.html
#'



expfiles <- list.files(path       = "~/TRAIN/Garmin_Exports/original/",
                       # pattern    = "*.fit",
                       recursive  = T,
                       full.names = T)

tempfl <- "/dev/shm/tmp_fit/"

for (af in expfiles) {
  ## check for fit file
  stopifnot( nrow(unzip(af, list = T)) == 1 )
  if (!grepl(".fit$", unzip(af, list = T)$Name)) {
    cat("NOT A FIT FILE!!:", af, "\n")
    next()
  }

  ## create in memory file
  unzip(af, unzip(af, list = T)$Name, overwrite = T, exdir = tempfl)
  from   <- paste0(tempfl, unzip(af, list = T)$Name)
  target <- paste0(tempfl, "temp.fit")
  file.rename(from, target)


  readFitFile(target)

  stop()
}




fitfiles <- list.files(path       = "~/TRAIN/GoldenCheetah/Athan/imports/",
                       pattern    = "*.fit",
                       full.names = T)

for (af in fitfiles) {
  res <- readFitFile(af)

  rest <- listMessageTypes(res)[!listMessageTypes(res) %in% c("record", "lap", "file_id")]

  for (at in rest) {
    dat <- getMessagesByType(res, message_type = at)

    cat(paste(at), "\n")
    cat(paste(dat), "\n")

  }



  ## may return multiple tables or a list of tables
  records(res)

  laps(res)
  file_id(res)
  hrv(res)
  monitoring(res)


  stop()
}



#' **END**
#+ include=T, echo=F
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
if (difftime(tac,tic,units = "sec") > 30) {
  system("mplayer /usr/share/sounds/freedesktop/stereo/dialog-warning.oga", ignore.stdout = T, ignore.stderr = T)
  system(paste("notify-send -u normal -t 30000 ", Script.Name, " 'R script ended'"))
}
