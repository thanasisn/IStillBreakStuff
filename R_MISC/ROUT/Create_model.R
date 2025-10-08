# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "Model ROUT"
#' date:   "`r strftime(Sys.time(), '%F %R %Z', tz= 'Europe/Athens')`"
#' author: ""
#'
#' output:
#'   bookdown::pdf_document2:
#'     number_sections:  no
#'     fig_caption:      no
#'     keep_tex:         yes
#'     keep_md:          yes
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
  library(lubridate,  quietly = TRUE, warn.conflicts = FALSE)
  library(pander,     quietly = TRUE, warn.conflicts = FALSE)
  library(readxl,     quietly = TRUE, warn.conflicts = FALSE)
  require(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
  require(tidyr,      quietly = TRUE, warn.conflicts = FALSE)
  require(readODS,    quietly = TRUE, warn.conflicts = FALSE)
})


dtk_fl <- "~/Documents/Running/ROUT results/ROUT_2024.ods"

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


## set gender
DT <- DT |>  mutate(Gender = if_else(grepl("M",Κατ.), "Male", "Female"))

#' \FloatBarrier
#'
#' A data driven prediction based on finishing times from ROUT 2024
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis", warning=F


## symmetric splits
bbrakes <- 5

#' \FloatBarrier
#'
#' # Inspect
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis", warning=F

plot(cut(DT$`K-181Χαϊντού`, breaks = bbrakes),
     xlab = "Minutes")


#' \FloatBarrier
#'
#' ## Assume there are `r bbrakes` class of athletes slit in equal bins of finishing times
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis", warning=F


DT <- DT |> mutate(
  bin   = cut(`K-181Χαϊντού`, breaks = bbrakes),
  binid = as.numeric(cut(`K-181Χαϊντού`, breaks = bbrakes)),
)

## create multiple models
models <- data.table()
for (id in unique(DT$binid)) {
  tmp <- DT[binid == id]
  tmp <- janitor::remove_empty(tmp, "cols")

  ## prepare data
  TT <- tmp |>
    select(contains("K-")) |>
    summarise_all(mean, na.rm = T) |> t()

  TT <- data.table(TT, keep.rownames = T)
  TT <- rename(.data = TT, Ttime = V1)

  TT$km <- as.numeric(stringr::str_match(TT$rn, "K-(\\d+).*")[,2])
  setorder(TT, km)

  ## create model
  TT[, Dx    := c(0, diff(km))]
  TT[, Dt    := c(0, diff(Ttime))]
  TT[, Pace  := Dt/Dx]
  TT[, Speed := Dx/Dt]

  TT[, Min   := min(tmp$`K-181Χαϊντού`)]
  TT[, Max   := max(tmp$`K-181Χαϊντού`)]
  TT[, Class := as.character(id)]

  # plot(TT[, Speed, Ttime])
  # title(id)

  models <- rbind(models, TT)
}

models[, TtimeH := Ttime / 60 ]

ggplot(models,
       aes(x = TtimeH,
           y = Speed,
           colour = Class,
           group  = Class)) +
  geom_point() +
  geom_line()


ggplot(models,
       aes(x = km,
           y = Speed,
           colour = Class,
           group  = Class)) +
  geom_point() + geom_line()












#+ include=T, echo=F, results="asis"
tac <- Sys.time()
cat(sprintf("\n**END** %s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
