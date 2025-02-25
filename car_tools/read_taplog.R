# /* #!/usr/bin/env Rscript */
# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
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

#+ echo=F, include=F
####_ Set environment _####
rm(list = (ls()[ls() != ""]))
tic <- Sys.time()
Script.Name <- "~/CODE/car_tools/read_taplog.R"

## __ Document options ---------------------------------------------------------
knitr::opts_chunk$set(out.width  = "100%"   )

filenames <- list.files(path       = "~/MISC/a34_export/TapLog",
                        pattern    = "TrackAndGraphBackup.*db",
                        full.names = T)

library(data.table)
library(dplyr)
library(RSQLite)
library(janitor)
library(ggplot2)
library(plotly)
library(htmltools)

#+ include=FALSE, echo=FALSE
## init use of ggplot and html tables in loops
tagList(ggplotly(ggplot()))

## find file to read
filelist <- data.table(filenames,
                       mtime = file.mtime(filenames))
setorder(filelist, mtime)
dbfile <- filelist[nrow(filelist), filenames]


## connect to db
con <- dbConnect(drv = RSQLite::SQLite(), dbname = dbfile)
dbListTables(con)

points   <- tbl(con, "data_points_table")
features <- tbl(con, "features_table"   )
groups   <- tbl(con, "groups_table"     )

DATA <- left_join(
  left_join(points,
            features,
            by = join_by(feature_id == id)) |>
    select(-feature_id,
           -display_index) |>
    rename(variable = "name"),
  groups,
  by = join_by(group_id == id)
) |>
  select(-group_id,
         -display_index) |>
  rename(group = "name") |>
  collect() |>
  data.table()

DATA <- remove_empty(DATA, which = "cols")
DATA <- remove_constant(DATA)

DATA$Date <- as.POSIXct(DATA$epoch_milli/1000, origin = "1970-01-01", tz = "UTC")
DATA[, epoch_milli := NULL]
setorder(DATA, Date)

## create tables

table(DATA$group)

DTRIP  <- DATA[group == "Duster trip" ]
DGAS   <- DATA[group == "Duster gas"  ]
DOTHER <- DATA[group == "Duster other"]

dcast(DTRIP, Date ~ variable + note + label)

dcast(DTRIP, Date ~ variable )

dcast(DTRIP, Date ~ variable , value.var = c("value", "label", "note"))

dcast(DTRIP, Date ~ variable + note , value.var = c("value", "label", "note"))

#'
#' # Raw trip data
#'
#+ echo=F, include=T

# for (av in sort(unique(DTRIP$variable))) {
#   pp <- DTRIP[variable == av]
#
#   p <- ggplot(pp, aes(x = Date, y = value)) +
#     geom_line() +
#     theme_linedraw() +
#     labs(subtitle = av)
#
#   if (!isTRUE(getOption('knitr.in.progress'))) {
#     suppressWarnings(print(p))
#   }
#
#   if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
#     ggplotly(p)
#   }
#
# }

av <- "Avg_kmph"
pp <- DTRIP[variable == av]
p <- ggplot(pp, aes(x = Date, y = value)) +
  geom_line() +
  theme_linedraw() +
  labs(subtitle = av,
       y        = av)

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}


av <- "Consumption_Accum"
pp <- DTRIP[variable == av]
p <- ggplot(pp, aes(x = Date, y = value)) +
  geom_line() +
  theme_linedraw() +
  labs(subtitle = av,
       y        = av)

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}
av <- "Consumption_Rate"
pp <- DTRIP[variable == av]
p <- ggplot(pp, aes(x = Date, y = value)) +
  geom_line() +
  theme_linedraw() +
  labs(subtitle = av,
       y        = av)

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}
av <- "Fuel_Level"
pp <- DTRIP[variable == av]
p <- ggplot(pp, aes(x = Date, y = value)) +
  geom_line() +
  theme_linedraw() +
  labs(subtitle = av,
       y        = av)

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}
av <- "km"
pp <- DTRIP[variable == av]
p <- ggplot(pp, aes(x = Date, y = value)) +
  geom_line() +
  theme_linedraw() +
  labs(subtitle = av,
       y        = av)

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}
av <- "Range"
pp <- DTRIP[variable == av]
p <- ggplot(pp, aes(x = Date, y = value)) +
  geom_line() +
  theme_linedraw() +
  labs(subtitle = av,
       y        = av)

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}
av <- "trip_km"
pp <- DTRIP[variable == av]
p <- ggplot(pp, aes(x = Date, y = value)) +
  geom_line() +
  theme_linedraw() +
  labs(subtitle = av,
       y        = av)

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}



#'
#' # Trip analysis
#'
#+ echo=F, include=T

ANT <- dcast(DTRIP, Date ~ variable )
ANT[, KM_lp100   := c(NA, 100 * diff(Consumption_Accum)/diff(km))]
ANT[, TRIP_lp100 := c(NA, 100 * diff(Consumption_Accum)/diff(trip_km))]


p <- ANT |>
  rename(lp100 = Consumption_Rate) |>
  select(Date, contains("lp100")) |>
  melt(id.vars = "Date") |>
  filter(!is.na(value) & value > 0) |>
  ggplot(aes(x = Date, y = value, colour = variable)) +
  geom_point() +
  theme_linedraw() +
  labs(subtitle = "Consumption", y = "l/100km")
if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}

p <- ANT |>
  rename(lp100 = Consumption_Rate) |>
  select(Date, contains("lp100")) |>
  melt(id.vars = "Date") |>
  filter(!is.na(value) & value < 0) |>
  ggplot(aes(x = Date, y = value, colour = variable)) +
  geom_point() +
  theme_linedraw() +
  labs(subtitle = "Consumption errors",
       y = "l/100km")
if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}



#'
#' # Gas analysis
#'
#+ echo=F, include=T

GAS <- dcast(DGAS, Date ~ variable) |>
  filter(!is.na(Litre) & !is.na(Mileage))
GAS[, lp100 := 100 * Litre/c(NA, diff(Mileage))]

p <- ggplot(GAS, aes(x = Date, y = lp100)) +
  geom_point() +
  theme_linedraw() +
  labs(subtitle = "Consumption from gas",
       y = "l/100km")
if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}


GAS <- dcast(DGAS, Date ~ variable)

p <- ggplot(GAS, aes(x = Date)) +
  geom_point(aes(y = Cost,  color = "Cost")) +
  geom_point(aes(y = Litre, color = "Litre")) +
  theme_linedraw() +
  labs(subtitle = "gas",
       y = element_blank())
if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}

p <- ggplot(GAS, aes(x = Date, y = Cost/Litre)) +
  geom_point() +
  theme_linedraw() +
  labs(subtitle = "gas",
       y = "euro/litre")
if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}
if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}



dbDisconnect(con)



## read old?
testf <- list.files("~/LOGs/BMeasurments/",
                    "*.csv",
                    full.names = T)

testf <- "/home/athan/LOGs/BMeasurments//TAP_2b.csv"
for (af in testf) {
  tmp <- fread(af)
  tmp <- tmp[grepl("Duster", cat1), ] |>
    select(-starts_with("gps"),
           -latitude, -longitude, -accuracy, -altitude) |>
    rename(Date     = timestamp) |>
    rename(value     = number) |>
    rename(variable = cat1)

  test <- rbind(
    tmp  |> mutate(
      Day    = as.Date(Date),
      Source = "csv"),
    DATA |> mutate(Day = as.Date(Date),
                   Source = "DB"),
    fill = T
  )

  test <- test |> filter(
    Day >= test[Source == "csv", range(Day)][1] &
    Day <= test[Source == "csv", range(Day)][2]
  )
  setorder(test, "Date")
}

ggplot(test, aes(x = Date, y = Source)) +
  geom_point()

tac = Sys.time();
cat(sprintf("%s %s@%s %s %f mins\n\n",Sys.time(),Sys.info()["login"],Sys.info()["nodename"],Script.Name,difftime(tac,tic,units="mins")))
