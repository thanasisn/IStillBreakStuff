# /* #!/usr/bin/env Rscript */
# /* Copyright (C) 2025 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "Utilities `r format(Sys.time(), '%F %T')`"
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
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/data_streams/house/H01_utilities.R"
export.file <- "~/Formal/REPORTS/H01_utilities.html"

## __ Document options ---------------------------------------------------------
knitr::opts_chunk$set(out.width  = "100%"   )

## __  Set environment ---------------------------------------------------------
suppressMessages({
  require(DT,         quietly = TRUE, warn.conflicts = FALSE)
  require(data.table, quietly = TRUE, warn.conflicts = FALSE)
  require(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
  require(ggplot2,    quietly = TRUE, warn.conflicts = FALSE)
  require(htmltools,  quietly = TRUE, warn.conflicts = FALSE)
  require(janitor,    quietly = TRUE, warn.conflicts = FALSE)
  require(plotly,     quietly = TRUE, warn.conflicts = FALSE)
  require(readODS,    quietly = TRUE, warn.conflicts = FALSE)
})

datadir <- "~/Documents/My_xls/data"
if (interactive() |
    !file.exists("~/Formal/REPORTS/M7_utilities.html") |
    any(
      file.mtime(c(
        paste0(datadir, "/utilities_gas.ods"),
        paste0(datadir, "/utilities_water.ods"),
        paste0(datadir, "/utilities_electricity.ods"),
        paste0(datadir, "/utilities_koinoxrista.ods")
      )) > file.mtime(export.file))) {
  cat("Have to run")
} else {
  stop("Dont have to run")
}


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

tlag <- lag(WATER$current) - WATER$previous
if (!all(tlag %in% c(NA, 0))) {
  cat("\n test day seq:\n")
  cat(lag(WATER$current) - WATER$previous, "\n")
}

WATER[, since := as.Date(since, "%d/%m/%Y")]
WATER[, until := as.Date(until, "%d/%m/%Y")]

tsince <- diff(order(WATER$since))
if (!all(tsince == 1)) {
  cat("\n test day order:\n")
  cat(diff(order(WATER$since)), "\n")
}

tuntil <- diff(order(WATER$until))
if (!all(tuntil == 1)) {
  cat("\n test day order:\n")
  cat(diff(order(WATER$until)), "\n")
}

## compute mean month
Wyear <- WATER[, .(month = sum(invoice)/12,
                   Date  = max(until)),
                    by = year(until)]

p <- ggplot(data = WATER, aes(x = until)) +
  geom_step(data = Wyear, aes(y = month, x = Date)) +
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

# cat("\n test day seq:\n")
# cat(lag(POWER$current) - POWER$previous, "\n")

POWER[, since := as.Date(since, "%F")]
POWER[, until := as.Date(until, "%F")]

# cat("\n test since order:\n")
# cat(diff(order(POWER$since)), "\n")
#
# cat("\n test until order:\n")
# cat(diff(order(POWER$until)), "\n")
#
# pander::pander(POWER[c(NA, diff(order(POWER$until))) != 1])
#
# pander::pander(POWER[c(NA, diff(order(POWER$since))) != 1])

POWER[difference == 0, difference := NA]
POWER[is.na(kwh) & !is.na(difference), kwh := difference ]

POWER[, invoicemean := frollmean(invoice, n = 12) ]
POWER[, kwhmean     := frollmean(kwh,     n = 12) ]

Pyear <- POWER[, .(month = sum(invoice)/12,
                   Date  = max(until)),
                   by    = year(until)]

p <- ggplot(data = POWER, aes(x = until)) +
  geom_step(data = Pyear, aes(y = month, x = Date)) +
  geom_line(aes(y = invoice), colour = "red", linewidth = 0.8) +
  geom_line(aes(y = invoicemean), colour = "blue", linewidth = 0.8) +
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
  geom_line(aes(y = kwh),     colour = "blue", linewidth = 0.8) +
  geom_line(aes(y = kwhmean), colour = "red", linewidth = 0.8) +
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
  geom_line(aes(y = kwh/invoice), colour = "orange", linewidth = 0.8) +
  xlab("") +
  ylab("Τιμή μονάδας kwh/eur") +
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

GAS[, since := as.Date(since, "%F")]
GAS[, until := as.Date(until, "%F")]
GAS[, row   := .I]

# cat("\n test day order:\n")
# cat(diff(order(GAS$since)), "\n")

# cat("\n test day order:\n")
# cat(diff(order(GAS$until)), "\n")

# pander::pander(
#   GAS[c(NA, diff(order(GAS$until))) != 1]
# )

GAS[difference == 0, difference := NA]
GAS[is.na(Nm3) & !is.na(difference), Nm3 := difference ]


GAS[, invoicemean := frollmean(invoice, n = 12) ]
GAS[, Nm3mean     := frollmean(Nm3,     n = 12) ]

Gyear <- GAS[, .(month = sum(invoice)/12,
                 Date  = max(until)),
                 by    = year(until)]


p <- ggplot(data = GAS, aes(x = until)) +
  geom_line(aes(y = invoice),     colour = "red", linewidth = 0.8) +
  geom_step(data = Gyear, aes(y = month, x = Date)) +
  geom_line(aes(y = invoicemean), colour = "blue", linewidth = 0.8) +
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
  geom_line(aes(y = Nm3),     colour = "blue",  linewidth = 0.8) +
  geom_line(aes(y = Nm3mean), colour = "green", linewidth = 0.8) +
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
  geom_line(aes(y = kwh/invoice), colour = "orange", linewidth = 0.8) +
  xlab("") +
  ylab("Τιμή μονάδας kwh/eur") +
  theme_linedraw()

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}

rm(GAS)



##  Koinoxrista  ---------------------------------------------------------------
#'
#' ## Κοινόχρηστα Παπάφη 36
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results = "asis"
KOIN <-  rbind(
  read_ods(paste0(datadir, "/utilities_koinoxrista.ods"), sheet = 1),
  read_ods(paste0(datadir, "/utilities_koinoxrista.ods"), sheet = 2)
) |> data.table()

KOIN[, Date := as.Date(Date, "%F")]
setorder(KOIN, Date)

KOIN_monthly <- KOIN[,
                     .(Value = sum(Value)),
                     by = .(Date = as.Date(paste(year(Date), month(Date), "1"), "%Y %m %d"))]

KOIN_yearly <- KOIN[,
                     .(Value = sum(Value)),
                     by = .(Date = as.Date(paste(year(Date), "1", "1"), "%Y %m %d"))]


p <- ggplot(data = KOIN, aes(x = Date)) +
  geom_point(aes(y = Value, colour = Type)) +
  geom_step(data = KOIN_monthly, aes(y = Value,    x = Date), colour = "blue", linewidth = 0.8) +
  geom_step(data = KOIN_yearly,  aes(y = round(Value/12,2), x = Date), colour = "green") +
  xlab("") +
  ylab("Κοινόχρηστα") +
  theme_linedraw()

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}




#+ include=T, echo=F, results="asis"
tac <- Sys.time()
cat(sprintf("**END** %s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
