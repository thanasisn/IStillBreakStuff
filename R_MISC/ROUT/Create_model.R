# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "A data driven prediction, based on the finishing times of 2024 ROUT"
#' date:   "`r strftime(Sys.time(), '%F', tz= 'Europe/Athens')`"
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
#'     fig_width:        6
#'     fig_height:       4
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
#'      left     = 20mm,
#'      right    = 20mm,
#'      top      = 25mm,
#'      bottom   = 25mm,
#'      headsep  = 3\baselineskip,
#'      footskip = 4\baselineskip
#'    }
#'   - \setmainfont[Scale=1.1]{Linux Libertine O}
#' ---

#+ echo=F, include=F, warning=F, message=F
rm(list = (ls()[ls() != ""]))
Script.Name <- "~/CODE/R_MISC/ROUT/Create_model.R"
Sys.setenv(TZ = "UTC")
tic <- Sys.time()

## __ Document options ---------------------------------------------------------
#+ echo=FALSE, include=TRUE
knitr::opts_chunk$set(comment    = ""       )
knitr::opts_chunk$set(dev        = c("pdf", "png")) ## expected option
# knitr::opts_chunk$set(dev        = "png"    )       ## for too much data
knitr::opts_chunk$set(out.width  = "100%"   )
knitr::opts_chunk$set(fig.align  = "center" )
knitr::opts_chunk$set(fig.cap    = " - empty caption - " )
knitr::opts_chunk$set(cache      =  FALSE   )  ## !! breaks calculations
knitr::opts_chunk$set(fig.pos    = 'h!'    )
knitr::opts_chunk$set(tidy = TRUE,
                      tidy.opts = list(
                        indent       = 4,
                        blank        = FALSE,
                        comment      = FALSE,
                        args.newline = TRUE,
                        arrow        = TRUE)
)

## __  Set environment ---------------------------------------------------------
suppressMessages({
  library(data.table, quietly = TRUE, warn.conflicts = FALSE)
  library(janitor,    quietly = TRUE, warn.conflicts = FALSE)
  library(ggplot2,    quietly = TRUE, warn.conflicts = FALSE)
  library(pander,     quietly = TRUE, warn.conflicts = FALSE)
  require(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
  require(readODS,    quietly = TRUE, warn.conflicts = FALSE)
  require(reticulate, quietly = TRUE, warn.conflicts = FALSE)
  require(grid,       quietly = TRUE, warn.conflicts = FALSE)
  require(gridExtra,  quietly = TRUE, warn.conflicts = FALSE)
  require(gtable,     quietly = TRUE, warn.conflicts = FALSE)
})

## Race start time
START     <- as.POSIXct("2025-10-17 00:00", tz = "EEST")
START_UTC <- as.POSIXct(START, tz = "UTC")

base_year <- 2024

PLANS  <- FALSE

dtk_fl <- paste0("~/Documents/Running/ROUT results/ROUT_", base_year, ".ods")
mdl_fl <- paste0("~/Documents/Running/ROUT results/ROUT_models_", base_year, ".Rds")
cp_fl  <- "~/CODE/R_MISC/ROUT/CP_cords.ods"

## get locations
CP <- data.table(read_ods(cp_fl))

## get finished
DT <- data.table(read_ods(dtk_fl))
DT <- DT[!is.na(`K-181Χαϊντού`)]
DT[, Bib       := NULL]
DT[, `AZ ID`   := NULL]
DT[, `#`       := NULL]
DT[, Κ.Κ       := NULL]
DT[, Γ.Κ       := NULL]
DT[, Χωρ       := NULL]
DT[, `ΔΧ Ω`    := NULL]
DT[, `ΔΧ %`    := NULL]
DT[, συνμωτ    := NULL]
DT[, `K-0CP-0` := 0]

minutes_to_hhmm <- function(minutes) {
  hours <- floor(minutes / 60)
  mins  <- round(minutes %% 60)
  hours[mins == 60] <- hours[mins == 60] + 1
  mins[ mins == 60]  <- 0
  sprintf("%02d:%02d", hours, mins)
}

##  Compute Astropy data  ------------------------------------------------------
py_require("astropy")
py_require("ephem")
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

# ## Call pythons Astropy for sun distance calculation
# sunR_astropy <- function(date) {
#   cbind(t(sun_vector(date, lat = lat, lon = lon, height = alt)), date)
# }

## set gender
DT <- DT |>  mutate(Gender = if_else(grepl("M",Κατ.), "Male", "Female"))

#' \FloatBarrier
#'
#' **Source code: [`github.com/thanasisn/IStillBreakStuff/blob/main/R_MISC/ROUT/Create_model.R`](https://github.com/thanasisn/IStillBreakStuff/blob/main/R_MISC/ROUT/Create_model.R)**
#'
#' This is just an statistical estimation, not a actual prediction tool.
#'
#+ echo=F, include=T, results="asis", warning=F


## symmetric splits
bbrakes <- 5

#' \FloatBarrier
#'
#' # Create models with the results of `r base_year`
#'
#' Assume there are `r bbrakes` class of athletes.
#'
#' We split finishing times in equal bins, and ignore differences in age or gender.
#'
#' Sun angles are computed at the actual location of each check point.
#'
#+ echo=F, include=T, results="asis", warning=F

hist(DT$`K-181Χαϊντού`,
     breaks = seq(min(DT$`K-181Χαϊντού`), max(DT$`K-181Χαϊντού`), l = bbrakes + 1),
     main = "Histogram",
     xlab = "Minutes",
     ylab = "Athletes",
     yaxs = "i",
     xaxs = "i")

DT <- DT |> mutate(
  bin   = cut(`K-181Χαϊντού`, breaks = bbrakes),
  binid = as.numeric(cut(`K-181Χαϊντού`, breaks = bbrakes)
  ),
)

DT$lower <- as.numeric( sub("\\((.+),.*", "\\1", DT$bin) )
DT$upper <- as.numeric( sub("[^,]*,([^]]*)\\]", "\\1", DT$bin) )


#' \FloatBarrier
#'
#' # Model each class
#'
#' Get a representative value for each part and variable, and create a pace/speed for each group
#'
#+ echo=T, include=T, results="asis", warning=F

## create model for each class
models <- data.table()
for (id in unique(DT$binid)) {
  tmp <- DT[binid == id]
  tmp <- remove_empty(tmp, "cols")

  ## get representative data as the mean of each group
  TT <- tmp |>
    select(contains("K-")) |>
    summarise_all(mean, na.rm = T) |> t()

  TT <- data.table(TT, keep.rownames = T)
  TT <- rename(.data = TT, Ttime = V1)

  TT$km <- as.numeric(stringr::str_match(TT$rn, "K-(\\d+).*")[,2])
  setorder(TT, km)

  TT$lower <- unique(tmp$lower)
  TT$upper <- unique(tmp$upper)

  ## create model
  TT[, Dx    := diff(c(0, km))]
  TT[, Dt    := diff(c(0, Ttime))]
  TT[, Pace  := round(Dt / Dx     , 2)]
  TT[, Speed := round(Dx / (Dt/60), 2)]
  TT[, Class := as.character(id)]

  models <- rbind(models, TT)
}

CP[, km := NULL]

## use actual coordinates of check points for sun calculation
models <- merge(models, CP, by.x = "rn", by.y = "rn" )

#' \FloatBarrier
#'
#' # Use each class to get relative times within each class finishing times
#'
#+ echo=F, include=T, results="asis", warning=F
## create multiple models

models[, TtimeH := Ttime / 60 ]

ggplot(models,
       aes(x = TtimeH,
           y = Speed,
           colour = Class,
           group  = Class)) +
  geom_point() +
  geom_line() +
  theme_bw()

ggplot(models,
       aes(x = km,
           y = Speed,
           colour = Class,
           group  = Class)) +
  geom_point() +
  geom_line() +
  theme_bw()

## Store models


#' \FloatBarrier
#'
#' # Create table for each hour within it's class
#'
#' Predict passes for a range of finishing time. This was posted online.
#'
#+ echo=F, include=PLANS, results="asis", warning=F

if (PLANS) {

  hours <- (min(models$lower) %/% 60):(max(models$upper) %/% 60)

  for (HH in hours) {
    MM  <- HH * 60
    tmp <- models[ MM < upper & MM > lower]
    if (nrow(tmp) == 0) next

    cat("\\newpage", "\n\n")
    cat("### Hours", HH, "model class", tmp[, unique(Class)], "\n\n")

    setorder(tmp, Ttime)

    last(tmp$Ttime)

    ## compute change from previous
    change <- 1 - last(tmp$Ttime) / MM

    ## compute scaled times
    tmp$Tnew <- tmp$Ttime * (1 + change)

    tmp$Tnew_hhmm <- minutes_to_hhmm(tmp$Tnew)
    tmp$Tpartial  <- minutes_to_hhmm(c(0, diff(tmp$Tnew) ))
    tmp           <- tmp[-1,]

    tmp$Date     <- START     + tmp$Tnew * 60
    tmp$Date_UTC <- START_UTC + tmp$Tnew * 60

    ## Calculate sun vector
    tmp[, Sun_Elevation := mapply(function(dt, lt, ln, ht) {
      round(sun_vector(dt, lat = lt, lon = ln, height = ht)[[2]], 2)
    }, Date_UTC, lat, lon, alt)]

    tmp[, Moon_Elevation := mapply(function(dt, lt, ln, ht) {
      round(moon_elevation(dt, lat = lt, lon = ln, height = ht), 2)
    }, Date_UTC, lat, lon, alt)]

    tmp[, Moon_Phase_percent := mapply(function(dt, lt, ln, al) {
      100 * round(moon_phase(dt, lat = lt, lon = ln, height = al), 3)
    }, Date_UTC, lat, lon, alt)]

    ## for export
    pp <- tmp[, .(  rn,   km,     Tnew_hhmm,       Tpartial,   Pace,   Speed,   Date,         Sun_Elevation,         Moon_Elevation, Moon_Phase_percent)]
    names(pp) <- c("CP", "km", "Total time", "Partial time", "Pace", "Speed", "Date", "Sun elevation angle", "Moon elevation angle", "Moon Phase %")

    rownames(pp) <- NULL

    ## for pdf
    cat(pander(pp, split.table = Inf))

    ## create a table as an image
    ttl <- paste("ROUT finishing target:", HH, "hours, model class:", tmp[, unique(Class)])

    png(paste0("C_", tmp[, unique(Class)], "_H_", HH, ".png"), height = 25 * nrow(pp), width = 90 * ncol(pp))

    t1      <- tableGrob(pp, rows = NULL)
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
  }
}

res_fl <- paste0("~/Documents/Running/ROUT results/ROUT_", base_year+1, ".ods")
if (file.exists(res_fl)) {
  VALIDATE <- TRUE
  RS <- data.table(read_ods(res_fl))
  RS <- RS[!is.na(`K-181Χαϊντού`)]
} else {
  VALIDATE <- FALSE
}


#' \FloatBarrier
#'
#' # Evaluate models against `r base_year + 1` results.
#'
#' For all finishers estimate pass times from each CP, using the appropriate
#' class model. Prediction are based on individual finishing time.
#'
#+ echo=F, include=VALIDATE, fig.width=6, fig.height=6, results="asis", warning=F

if (VALIDATE) {

  gather <- data.table()
  for (al in 1:nrow(RS)) {
    ll  <- RS[al]
    MM  <- ll$`K-181Χαϊντού`
    HH  <- MM / 60
    tmp <- models[ MM < upper & MM > lower]
    if (nrow(tmp) == 0) next

    # cat("\\newpage", "\n\n")
    # cat("### Hours", HH, "model class", tmp[, unique(Class)], "\n\n")

    setorder(tmp, Ttime)

    ## compute change from previous
    change <- 1 - last(tmp$Ttime) / MM

    ## compute scaled times
    tmp$Tnew <- tmp$Ttime * (1 + change)

    tmp$Tnew_hhmm <- minutes_to_hhmm(tmp$Tnew)
    tmp$Tpartial  <- minutes_to_hhmm(c(0, diff(tmp$Tnew) ))
    tmp           <- tmp[-1,]

    # tmp$Date     <- START     + tmp$Tnew * 60
    # tmp$Date_UTC <- START_UTC + tmp$Tnew * 60

    pp <- ll |>
      select(contains("K-")) |>
      t()

    tt <- data.table(
      rn      = rownames(pp),
      ActTime = pp[,1])

    tmps <- merge(tmp, tt)
    setorder(tmps, km)

    gather <- rbind(
      gather,
      tmps[, .(rn, km, Tnew, ActTime, Name = ll$Αθλητής, Class)]
    )
  }
}

#'
#' We excluded finishing time from the statistical evaluation, as the modelled
#' finishing time is equal.
#'
#+ echo=F, include=VALIDATE, results="asis", warning=F

gather <- gather[rn != "K-181Χαϊντού"]

#'
#' ## Summary of % difference for all CP
#'
#+ echo=F, include=VALIDATE, results="asis", warning=F
pander(summary(gather[, 100 * (Tnew - ActTime) / ActTime]))


#'
#' ## Distribution of % difference for all CP and classes
#'
#+ echo=F, include=VALIDATE, results="asis", warning=F
hist(gather[, 100 * (Tnew - ActTime) / ActTime], breaks = 20,
     main = "Distribution of % difference for all CP")


#'
#' ## Departures by CP
#'
#' Per cent difference from the modelled time for all classes, by each check point.
#'
#+ echo=F, include=VALIDATE, results="asis", warning=F
for (cp in unique(gather$rn)) {
  tmp <- gather[rn == cp]
  if (nrow(tmp[!is.na(ActTime) & !is.na(Tnew)]) <= 4) next()

  cat("\\newpage", "\n\n")
  cat("#### ", cp, "\n\n")

  pander(summary(tmp[, 100 * (Tnew - ActTime) / ActTime]))

  hist(tmp[, 100 * (Tnew - ActTime) / ActTime], breaks = 20,
     main = paste("Distribution of % difference for", cp))
}


#'
#' ## Departures by class
#'
#' Per cent difference from the modelled time for all check point, fro each class.
#'
#+ echo=F, include=VALIDATE, results="asis", warning=F
for (cl in unique(gather$Class)) {
  tmp <- gather[Class == cl]
  if (nrow(tmp[!is.na(ActTime) & !is.na(Tnew)]) <= 4) next()

  cat("\\newpage", "\n\n")
  cat("#### ", cl, "\n\n")

  pander(summary(tmp[, 100 * (Tnew - ActTime) / ActTime]))

  hist(tmp[, 100 * (Tnew - ActTime) / ActTime], breaks = 20,
     main = paste("Distribution of % difference for class", cl))
}

#'
#' ## Departures by athlete
#'
#' Actual pass time minus predicted passes.
#'
#' Positive values mean that actual time is longer than expected, and the athlete slower than expected.
#'
#+ echo=F, include=VALIDATE, results="asis", warning=F
for (al in unique(gather$Name)) {
  tmp <- gather[Name == al]
  if (nrow(tmp) <= 4) next()

  cat("\\newpage", "\n\n")

  cat(" \n \n")
  cat("#### ", al, "\n \n")

  pander(summary(tmp[, 100 * (Tnew - ActTime) / ActTime]))

  cat(" \n \n")

  # hist(tmp[, 100 * (Tnew - ActTime) / ActTime], breaks = 20,
  #    main = paste("Distribution of % difference for", al))

  cat(" \n \n")

  plot(tmp[, ActTime - Tnew, km ],
       xlab = "",
       ylab = "Diff minutes",
       xaxt = "n",
       main = al)
  axis(1, at = tmp$km, labels = tmp$rn, las = 2)
  cat(" \n \n")
}


#+ include=F, echo=F, results="asis"
tac <- Sys.time()
cat(sprintf("\n**END** %s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
