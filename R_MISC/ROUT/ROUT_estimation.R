# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "ROUT estimation of my times"
#' date:   "`r strftime(Sys.time(), '%F %R %Z', tz= 'Europe/Athens')`"
#' author: ""
#'
#' output:
#'   bookdown::pdf_document2:
#'     number_sections:  no
#'     fig_caption:      no
#'     keep_tex:         no
#'     keep_md:          no
#'     latex_engine:     xelatex
#'     toc:              yes
#'     toc_depth:        4
#'     fig_width:        8
#'     fig_height:       5
#'   html_document:
#'     toc:             true
#'     number_sections: false
#'     fig_width:       6
#'     fig_height:      4
#'     keep_md:         no
#'
#' header-includes:
#'   - \usepackage{fontspec}
#'   - \usepackage{xunicode}
#'   - \usepackage{xltxtra}
#'   - \usepackage{placeins}
#'   - \geometry{
#'      a4paper,
#'      left     = 25mm,
#'      right    = 25mm,
#'      top      = 30mm,
#'      bottom   = 30mm,
#'      headsep  = 3\baselineskip,
#'      footskip = 4\baselineskip
#'    }
#'   - \setmainfont[Scale=1.1]{Linux Libertine O}
#' ---

#+ echo=F, include=F
rm(list = (ls()[ls() != ""]))
Script.Name <- "~/CODE/R_MISC/ROUT/ROUT_estimation.R"
Sys.setenv(TZ = "UTC")
tic <- Sys.time()

## __ Document options ---------------------------------------------------------
#+ echo=FALSE, include=TRUE
knitr::opts_chunk$set(comment    = ""       )
# knitr::opts_chunk$set(dev        = c("pdf", "png")) ## expected option
knitr::opts_chunk$set(dev        = c("pdf"))
# knitr::opts_chunk$set(dev        = "png"    )       ## for too much data
knitr::opts_chunk$set(out.width  = "60%"   )
knitr::opts_chunk$set(fig.align  = "center" )
knitr::opts_chunk$set(fig.cap    = " - empty caption - " )
knitr::opts_chunk$set(cache      =  FALSE   )  ## !! breaks calculations
knitr::opts_chunk$set(fig.pos    = 'h!'    )


## __  Set environment ---------------------------------------------------------
library(readODS)
library(data.table)
library(reticulate, warn.conflicts = FALSE, quietly = TRUE)
require(grid,       quietly = TRUE, warn.conflicts = FALSE)
require(gridExtra,  quietly = TRUE, warn.conflicts = FALSE)
require(gtable,     quietly = TRUE, warn.conflicts = FALSE)

reticulate::py_config()
# use_python("~/.pyenv/versions/3.13.2/bin/python3")
py_require("astropy")
py_require("ephem")

## Load my previous times
DT <- data.table(read_ods("~/GISdata/GPX/Plans/ROUT/ROUT_2024/Results.ods"))
CP <- data.table(read_ods("~/CODE/R_MISC/ROUT/CP_cords.ods"))


DT <- merge(DT, CP, by.x = "Σημείο Ελέγχου", by.y = "cp_name")

## piramida sun calculation for this point
lat <- 41.523612
lon <- 24.454846
alt <- 900

## Race start time
START     <- as.POSIXct("2025-10-17 00:00 EEST")
START_UTC <- as.POSIXct(START, tz = "UTC")

## Set target time
target <- 43 * 60

## prepare data
DT$Συνολο_minutes <- as.numeric(DT$Συνολο) * 60

## compute change from previous
change <- 1 - tail(DT$Συνολο_minutes, 1) / target

## compute scaled times
DT$new <- DT$Συνολο_minutes * (1 + change)

minutes_to_hhmm <- function(minutes) {
  hours <- floor(minutes / 60)
  mins  <- round(minutes %% 60)
  hours[mins == 60] <- hours[mins == 60] + 1
  mins[ mins == 60]  <- 0
  sprintf("%02d:%02d", hours, mins)
}

# Apply to your data
DT$Συνολο_hhmm <- minutes_to_hhmm(as.numeric(DT$Συνολο_minutes))
DT$New_hhmm    <- minutes_to_hhmm(as.numeric(DT$new))

DT$Date_EET <- START
DT$Date_UTC <- START_UTC


DT$Date_EET <- DT$Date_EET + DT$new * 60
DT$Date_UTC <- DT$Date_UTC + DT$new * 60

DT <- DT[!is.na(Συνολο)]
setorder(DT, KM)

DT$Dx <- diff(c(0, DT$KM))
DT$Dt <- diff(c(0, DT$new))

DT[, Pace  := round(Dt/Dx, 2)]
DT[, Speed := round(Dx/(Dt/60), 2)]

##  Compute Astropy data  ------------------------------------------------------
source_python("~/BBand_LAP/parameters/sun/sun_vector_astropy_p3.py")
source_python("~/BBand_LAP/parameters/sun/moon_vector_ephem.py")

moon_elevation <- function(date, lat = lat, lon = lon, height = alt) {
  res <- moon_sky_parameters(date, lat = lat, lon = lon, height = height)
  return(res$moon$elevation)
}

moon_phase <- function(date, lat = lat, lon = lon, height = alt) {
  res <- moon_sky_parameters(date, lat = lat, lon = lon, height = height)
  return(res$moon$phase)
}



DT[, Sun_Elevation := mapply(function(dt, lt, ln, ht) {
  round(sun_vector(dt, lat = lt, lon = ln, height = ht)[[2]], 2)
}, Date_UTC, lat, lon, alt)]

DT[, Moon_Elevation := mapply(function(dt, lt, ln, al) {
  round(moon_elevation(dt, lat = lt, lon = ln, height = al), 2)
}, Date_UTC, lat, lon, alt)]

DT[, Moon_Phase_percent := mapply(function(dt, lt, ln, al) {
  100 * round(moon_phase(dt, lat = lt, lon = ln, height = al), 3)
}, Date_UTC, lat, lon, alt)]


# res <- moon_sky_parameters(as.POSIXct(Sys.time(), tz = "UTC"), lat = lat, lon = lon, height = alt)

# res$moon$phase
# stop()



# ##  Calculate sun vector
# sss <- data.frame(t(sapply(DT$Date_UTC, sunR_astropy )))
#
# ##  reshape data
# ADD <- data.frame(AsPy_Azimuth   = unlist(sss$X1),
#                   AsPy_Elevation = unlist(sss$X2),
#                   AsPy_Dist      = unlist(sss$X3),
#                   Date           = as.POSIXct(unlist(sss$X4),
#                                               origin = "1970-01-01"))
# DT$SunElevation_Pir <- round(ADD$AsPy_Elevation, 2)

setorder(DT, KM)

TT <- DT[, .(KM, `Σημείο Ελέγχου`, New_hhmm, Speed, Pace, Date_EET, Sun_Elevation, Moon_Elevation, Moon_Phase_percent, alt)]
setorder(TT, KM)

#+ echo=FALSE, include=TRUE
cat(c("Γωνία του ήλιου πάνω από τον ορίζοντα για υποθετικούς χρόνους στα check point\n"))
print( TT )

#' \FloatBarrier
#'
#' # Create some groups
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis", warning=F

pander::pander(TT, split.table = Inf)




## create a table as an image
ttl <- paste("ROUT finishing target:", target/60, "hours")

png(paste0("P_H_", target/60, ".png"), height = 25 * nrow(TT), width = 90 * ncol(TT))

t1      <- tableGrob(TT, rows = NULL)
title   <- textGrob(ttl, gp = gpar(fontsize = 20))
padding <- unit(5,"mm")

table <- gtable_add_rows(
  t1,
  heights = grobHeight(title) + padding,
  pos = 0)
table <- gtable_add_grob(
  table,
  title,
  1, 1, 1, ncol(table))

grid.newpage()
grid.draw(table)

dev.off()
