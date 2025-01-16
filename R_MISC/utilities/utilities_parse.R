# /* #!/usr/bin/env Rscript */
# /* Copyright (C) 2025 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "`r format(Sys.time(), '%F %T')`"
#' author: ""
#' output:
#'   html_document:
#'     toc: true
#'     fig_width:  6
#'     fig_height: 4
#'     keep_md:    no
#' date: ""
#' ---

#+ echo=F, include=T
rm(list = (ls()[ls() != ""]))
Script.Name <- "utilities_parse.R"
dir.create("./runtime/", showWarnings = FALSE)
Sys.setenv(TZ = "UTC")
tic <- Sys.time()

## __ Document options ---------------------------------------------------------
knitr::opts_chunk$set(out.width  = "100%"   )

## __  Set environment ---------------------------------------------------------
suppressMessages({
  library(DT,         quietly = TRUE, warn.conflicts = FALSE)
  library(data.table, quietly = TRUE, warn.conflicts = FALSE)
  library(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
  library(ggplot2,    quietly = TRUE, warn.conflicts = FALSE)
  library(htmltools,  quietly = TRUE, warn.conflicts = FALSE)
  library(janitor,    quietly = TRUE, warn.conflicts = FALSE)
  library(plotly,     quietly = TRUE, warn.conflicts = FALSE)
  library(readODS,    quietly = TRUE, warn.conflicts = FALSE)
})

datadir <- "~/Documents/My_xls/data"

#+ include=FALSE, echo=FALSE
## init use of ggplot and html tables in loops
tagList(datatable(cars))
tagList(ggplotly(ggplot()))


##  Water  ------------------------------------------------------------
#'
#' `r cat(paste("# ", Sys.time()), "\n")`
#'
#' ## Water
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results = "asis"

WATER <- read_ods(paste0(datadir, "/utilities_water.ods")) |>
  filter(!is.na(since)) |>
  data.table()

cat("\n test day seq:\n")
cat(lag(WATER$current) - WATER$previous, "\n")


WATER[, since := as.Date(since, "%d/%m/%Y")]
WATER[, until := as.Date(until, "%d/%m/%Y")]

cat("\n test day order:\n")
cat(diff(order(WATER$since)), "\n")

cat("\n test day order:\n")
cat(diff(order(WATER$until)), "\n")

p <- ggplot(data = WATER, aes(x = until)) +
  geom_line(aes(y = invoice), colour = "red", linewidth = 0.8) +
  xlab("") +
  ylab("Λογαριασμός") +
  theme_linedraw()

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}

p <- ggplot(data = WATER, aes(x = until)) +
  geom_line(aes(y = difference), colour = "blue", linewidth = 0.8) +
  xlab("") +
  ylab("Κατανάλωση") +
  theme_linedraw()

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}
rm(WATER)


##  Electricity  ------------------------------------------------------------
#'
#' ## Electricity
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results = "asis"

POWER <- read_ods(paste0(datadir, "/utilities_electricity.ods")) |>
  filter(!is.na(since)) |>
  data.table()

cat("\n test day seq:\n")
cat(lag(POWER$current) - POWER$previous, "\n")

POWER[, since := as.Date(since, "%d/%m/%Y")]
POWER[, until := as.Date(until, "%d/%m/%Y")]

cat("\n test day order:\n")
cat(diff(order(POWER$since)), "\n")

cat("\n test day order:\n")
cat(diff(order(POWER$until)), "\n")

POWER[c(NA, diff(order(POWER$until))) != 1]

POWER[difference == 0, difference := NA]
POWER[is.na(kwh) & !is.na(difference), kwh := difference ]


p <- ggplot(data = POWER, aes(x = until)) +
  geom_line(aes(y = invoice), colour = "red", linewidth = 0.8) +
  xlab("") +
  ylab("Λογαριασμός") +
  theme_linedraw()

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}

p <- POWER |>
  filter(!is.na(kwh)) |>
  ggplot(aes(x = until)) +
  geom_line(aes(y = kwh), colour = "blue", linewidth = 0.8) +
  xlab("") +
  ylab("Κατανάλωση") +
  theme_linedraw()

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}

p <- POWER |>
  filter(!is.na(kwh)) |>
  ggplot(aes(x = until)) +
  geom_line(aes(y = invoice/kwh), colour = "orange", linewidth = 0.8) +
  xlab("") +
  ylab("Τιμή μονάδας") +
  theme_linedraw()

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}
rm(POWER)


##  Gas  ------------------------------------------------------------
#'
#' ## Gas
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results = "asis"


GAS <- read_ods(paste0(datadir, "/utilities_gas.ods")) |>
  filter(!is.na(since)) |>
  data.table()

cat("\n test day seq:\n")
cat(lag(GAS$current) - GAS$previous, "\n")

GAS[, since := as.Date(since, "%d/%m/%Y")]
GAS[, until := as.Date(until, "%d/%m/%Y")]

cat("\n test day order:\n")
cat(diff(order(GAS$since)), "\n")

cat("\n test day order:\n")
cat(diff(order(GAS$until)), "\n")


GAS[c(NA, diff(order(GAS$until))) != 1]

GAS[difference == 0, difference := NA]
GAS[is.na(Nm3) & !is.na(difference), Nm3 := difference ]


p <- ggplot(data = GAS, aes(x = until)) +
  geom_line(aes(y = invoice), colour = "red", linewidth = 0.8) +
  xlab("") +
  ylab("Λογαριασμός") +
  theme_linedraw()

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}


p <- ggplot(data = GAS, aes(x = until)) +
  geom_line(aes(y = Nm3), colour = "blue", linewidth = 0.8) +
  xlab("") +
  ylab("Κατανάλωση") +
  theme_linedraw()

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}

p <- ggplot(data = GAS, aes(x = until)) +
  geom_line(aes(y = invoice/Nm3), colour = "orange", linewidth = 0.8) +
  xlab("") +
  ylab("Τιμή μονάδας") +
  theme_linedraw()

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}

rm(GAS)


#+ include=T, echo=F, results="asis"
tac <- Sys.time()
cat(sprintf("**END** %s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))

