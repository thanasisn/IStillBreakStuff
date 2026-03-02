# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "LAP DAVIS `r strftime(Sys.time(), '%F %R %Z', tz= 'Europe/Athens')`"
#' author: ""
#' output:
#'   html_document:
#'     toc:             true
#'     number_sections: false
#'     fig_width:       6
#'     fig_height:      4
#'     keep_md:         no
#' date: ""
#' ---

#+ echo=F, include=F
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/data_streams/weather/W02_LAP_Davis.R"
export.file <- "~/Formal/REPORTS/W02_LAP_Davis.html"

if (interactive() ||
    !file.exists(export.file) ||
    file.mtime(export.file) <= (Sys.time() - 0.75 * 3600)) {
  print("Have to run")
} else {
  stop(paste0("\n\n", basename(Script.Name), "\nDon't have to run yet!\n\n"))
}

##  Set environment  -----------------------------------------------------------
require(scales,     quietly = TRUE, warn.conflicts = FALSE)
require(data.table, quietly = TRUE, warn.conflicts = FALSE)
require(ggplot2,    quietly = TRUE, warn.conflicts = FALSE)
require(tidyr,      quietly = TRUE, warn.conflicts = FALSE)
require(DT,         quietly = TRUE, warn.conflicts = FALSE)
require(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
require(janitor,    quietly = TRUE, warn.conflicts = FALSE)
require(lubridate,  quietly = TRUE, warn.conflicts = FALSE)
require(htmltools,  quietly = TRUE, warn.conflicts = FALSE)
require(plotly,     quietly = TRUE, warn.conflicts = FALSE)



#+ include=FALSE, echo=FALSE
## init use of ggplot and html tables in loops
tagList(datatable(cars))
tagList(ggplotly(ggplot()))

#'
#' ## LAP davis last data {-}
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis", warning=F

LAPDAV_FL  <- "/home/athan/DATA_RAW/LAPWeath/LAP_roof/LAP_AUTH_davis.csv"

## plot time range
# dt_start <- as.POSIXlt(paste(format(Sys.time() - TIME_BACK,  format = "%F"), "00:00"), tz = "Europe/Athens" )
# dt_end   <- as.POSIXlt(paste(format(Sys.time() + TIME_FRONT, format = "%F"), "00:00"), tz = "Europe/Athens" )

##  Load data  -----------------------------------------------------------------
lapd <- read.csv(LAPDAV_FL)

## TODO check time zone
lapd$dateTime <- as.POSIXct(lapd$dateTime, tz = "Europe/Athens")
lapd          <- remove_constant(lapd)
lapd <- lapd |> filter(dateTime > Sys.time() - months(1))

str_date <- format(as.POSIXct(Sys.time(), tz = "Europe/Athens"), "%F %H:%M %Z")

vars <- grep("dateTime|interval|maxSolarRad|radiation|UV", colnames(lapd), value = T, invert = T)
for (av in vars) {

  g <- ggplot(data = lapd, aes(x = dateTime, y = .data[[av]])) +
    geom_vline(xintercept = as.numeric(Sys.time()),              linetype = "dashed", color = "green") +
    xlab("") +
    ylab("") +
    labs(title = paste("Davis LAP", "  ", str_date, "  ", av)) +
    geom_line() +
    theme_bw() +
    theme(legend.position = "top")

  if (isTRUE(getOption('knitr.in.progress'))) {
    # In R Markdown, wrap in htmltools::tagList for plotly
    print(htmltools::tagList(ggplotly(g)))
  } else if (interactive()) {
    # In interactive mode
    print(ggplotly(g))
  } else {
    # For static plots
    print(g)
  }
}

#+ include=T, echo=F, results="asis"
tac <- Sys.time()
cat(sprintf("**END** %s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
