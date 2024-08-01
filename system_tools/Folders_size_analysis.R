#!/usr/bin/env Rscript
# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "......."
#' author: "Natsis Athanasios"
#' institute: "AUTH"
#' affiliation: "Laboratory of Atmospheric Physics"
#' abstract: "........."
#' output:
#'   html_document:
#'     toc: true
#'     fig_width:  9
#'     fig_height: 4
#'   pdf_document:
#' date: "`r format(Sys.time(), '%F')`"
#' ---


#+ echo=F, include=T
rm(list = (ls()[ls() != ""]))
Script.Name <- "~/CODE/system_tools/Folders_size_analysis.R"
dir.create("./runtime/", showWarnings = FALSE)
Sys.setenv(TZ = "UTC")
## standard output
if (!interactive()) {
    pdf( file = paste0("/home/athan/LOGs/SYSTEM_LOGS/",  basename(sub("\\.R$",".pdf", Script.Name))))
    sink(file = paste0("/home/athan/LOGs/SYSTEM_LOGS/",  basename(sub("\\.R$",".out", Script.Name))), split = TRUE)
}
## error notification function
tic <- Sys.time()



## __ Document options ---------------------------------------------------------
knitr::opts_chunk$set(comment    = ""       )
# knitr::opts_chunk$set(dev        = c("pdf", "png"))
knitr::opts_chunk$set(dev        = "png"    )
knitr::opts_chunk$set(out.width  = "100%"   )
knitr::opts_chunk$set(fig.align  = "center" )
knitr::opts_chunk$set(cache      =  FALSE   )  ## !! breaks calculations
knitr::opts_chunk$set(fig.pos    = '!h'     )

## __  Set environment ---------------------------------------------------------
require(data.table, quietly = TRUE, warn.conflicts = FALSE)
require(stringr,    quietly = TRUE, warn.conflicts = FALSE)


#' Text is here
#+ echo=F, include=T

data_fl      <- paste0("/home/athan/LOGs/SYSTEM_LOGS/Log_folders_size_", Sys.info()["nodename"], ".Rds")

datafls <- list.files(path         = "/home/athan/LOGs/SYSTEM_LOGS",
                      pattern      = "Log_folders_size_.*.Rds",
                      full.names   = TRUE,
                      recursive    = FALSE,
                      include.dirs = FALSE)


##  Analysis  -----------------------------------------------

for (af in datafls) {
  host <- sub("Log_folders_size_", "", sub(".Rds", "", basename(af)))
  DATA <- data.table(readRDS(af))

  cat("\n", host, "\n")

  ## clean and prepare
  DATA       <- DATA[ size > 2, ]
  DATA$Bytes <- gdata::humanReadable(DATA$size)
  DATA$Date  <- as.Date(DATA$Date, origin = "1970-01-01")
  DATA[, Depth := str_count(file, "/")]


  ## keep the oldest unchanged row only
  ## assume the size is constant since last day
  DATA <- DATA[DATA[, .I[which.min(Date)], by = .(file, size) ]$V1]

  ## keep only folder with changed size
  DATA <- DATA[DATA[, .I[.N > 1], by = .(file)]$V1, ]

  ## TODO check not changing folder


  cat(length(unique(DATA$file)), "Folders with changed size\n")


  ## to monitor change

  ## % change per day
  ## % total change
  ## min max current

  ## Table and plots
  ## the most offending




}









# # ~  Universal Footer  ~ # # # # # # # # # # # # # # # # # # # # # # # # # # #
#' **END**
#+ include=T, echo=F
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
