# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "ROUT model for all"
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


## __  Set environment ---------------------------------------------------------
suppressMessages({
  library(data.table, quietly = TRUE, warn.conflicts = FALSE)
  library(janitor,    quietly = TRUE, warn.conflicts = FALSE)
  library(ggplot2,    quietly = TRUE, warn.conflicts = FALSE)
  library(pander,     quietly = TRUE, warn.conflicts = FALSE)
  require(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
  require(readODS,    quietly = TRUE, warn.conflicts = FALSE)
  require(grid,       quietly = TRUE, warn.conflicts = FALSE)
  require(gridExtra,  quietly = TRUE, warn.conflicts = FALSE)
  require(gtable,     quietly = TRUE, warn.conflicts = FALSE)
})

## Race start time
START     <- as.POSIXct("2025-10-17 00:00 EEST")
START_UTC <- as.POSIXct(START, tz = "UTC")

dtk_fl <- "~/Documents/Running/ROUT results/ROUT_2024.ods"
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

  sprintf("%02d:%02d", hours, mins)
}

## set gender
DT <- DT |>  mutate(Gender = if_else(grepl("M",Κατ.), "Male", "Female"))

#' \FloatBarrier
#'
#' # **A data driven prediction, based on the finishing times of 2024 ROUT.**
#'
#' **Source code: [`github.com/thanasisn/IStillBreakStuff/blob/main/R_MISC/ROUT/Create_model.R`](https://github.com/thanasisn/IStillBreakStuff/blob/main/R_MISC/ROUT/Create_model.R)**
#'
#' This is just an estimation, not a actual prediction tool.
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis", warning=F


## symmetric splits
bbrakes <- 5

#' \FloatBarrier
#' \newpage
#'
#' ## Assume there are `r bbrakes` class of athletes.
#'
#' We split finishing times in equal bins, and ignore differences in age or gender.
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis", warning=F

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
#' ## Model each group
#'
#' Get a representative value for each part and variable, and create a pace/speed for each group
#'
#+ echo=T, include=T, fig.width=6, fig.height=6, results="asis", warning=F

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
  TT[, Dx    := c(0, diff(km))]
  TT[, Dt    := c(0, diff(Ttime))]
  TT[, Pace  := Dt/Dx]
  TT[, Speed := Dx/Dt]
  TT[, Class := as.character(id)]

  models <- rbind(models, TT)
}

CP[, km := NULL]

## use actual coordinates of check points for sun calculation
models <- merge(models, CP, by.x = "rn", by.y = "rn" )

#' \FloatBarrier
#' \newpage
#'
#' ## Use each group to get relative times within group range
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis", warning=F
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


#' \newpage
#' \FloatBarrier
#'
#' ## Create table for each hour within it's class
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis", warning=F
## create multiple models

hours <- (min(models$lower) %/% 60):(max(models$upper) %/% 60)

for (HH in hours) {
  MM  <- HH * 60
  tmp <- models[ MM < upper & MM > lower]
  if (nrow(tmp) == 0) next

  cat("### Hours", HH, "model class", tmp[, unique(Class)], "\n")

  setorder(tmp, Ttime)

  last(tmp$Ttime)

  ## compute change from previous
  change <- 1 - last(tmp$Ttime) / MM

  ## compute scaled times
  tmp$Tnew <- tmp$Ttime * (1 + change)

  tmp$Tnew_hhmm <- minutes_to_hhmm(tmp$Tnew)
  tmp$Tpartial  <- minutes_to_hhmm(c(0,diff(tmp$Tnew)))
  tmp           <- tmp[-1,]

  pp <- tmp[, .(rn, km, Tnew_hhmm, tmp$Tpartial)]
  names(pp) <- c("CP", "km", "Total time", "Partial time")


  ## Calculate sun vector






  stop( )

  ## for pdf
  cat(pander(pp))



  ## create a table as an image
  ttl <- paste("Target hours", HH, "model class", tmp[, unique(Class)])

  png(paste0("C_", tmp[, unique(Class)], "_H_", HH, ".png"), height = 25 * nrow(pp), width = 95 * ncol(pp))


  t1      <- tableGrob(pp)
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




#+ include=F, echo=F, results="asis"
tac <- Sys.time()
cat(sprintf("\n**END** %s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
