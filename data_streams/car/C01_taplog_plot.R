# /* #!/usr/bin/env Rscript */
# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "Car taplog `r strftime(Sys.time(), '%F %R %Z', tz= 'Europe/Athens')`"
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
####_ Set environment _####
tic <- Sys.time()
Script.Name <- "~/CODE/data_streams/car/C01_taplog_plot.R"
export.file <- "~/Formal/REPORTS/C01_taplog_plot.html"

filenames <- list.files(path       = "~/MISC/a34_export/TapLog",
                        pattern    = "TrackAndGraphBackup.*.db",
                        full.names = T)


if (interactive() ||
    !file.exists(export.file) ||
    file.mtime(export.file)    <= (Sys.time() - 4 * 3600) ||
    max(file.mtime(filenames)) >= file.mtime(export.file)  ) {
  print("Have to run")
} else {
  stop(paste0("\n\n", basename(Script.Name), "\nDon't have to run yet!\n\n"))
}


## __ Document options ---------------------------------------------------------
knitr::opts_chunk$set(out.width  = "100%"   )


require(data.table, quietly = TRUE, warn.conflicts = FALSE)
require(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
require(RSQLite,    quietly = TRUE, warn.conflicts = FALSE)
require(janitor,    quietly = TRUE, warn.conflicts = FALSE)
require(ggplot2,    quietly = TRUE, warn.conflicts = FALSE)
require(plotly,     quietly = TRUE, warn.conflicts = FALSE)
require(htmltools,  quietly = TRUE, warn.conflicts = FALSE)
require(DT,         quietly = TRUE, warn.conflicts = FALSE)
require(htmltools,  quietly = TRUE, warn.conflicts = FALSE)


#+ include=FALSE, echo=FALSE
## init use of ggplot and html tables in loops
tagList(datatable(cars))
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
            by = c("feature_id" = "id")) |>
    select(-feature_id,
           -display_index) |>
    rename(variable = "name"),
  groups,
  by = c("group_id" = "id")
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

try({
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
})


try({
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
})

ANT[year(Date)==2022,]

dbDisconnect(con)


setorder(DTRIP, Date)

A <- DTRIP[variable == "km",                .(Diff_KM      = c(NA, diff(value)), Date) ]
B <- DTRIP[variable == "trip_km",           .(Diff_trip_Km = c(NA, diff(value)), Date) ]
C <- DTRIP[variable == "Consumption_Accum", .(Diff_Cons_L  = c(NA, diff(value)), Date) ]

Diif <- merge(merge(A, B), C)

Diif[, Start  := lag(Date)]
Diif[, Finish := Date]
Diif[, Date  := NULL]


#'
#' ## Changes from on board {-}
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis"
print(
  htmltools::tagList(
    datatable(Diif,
              rownames = FALSE,
              options  = list(pageLength = 30),
              style    = "bootstrap",
              class    = "table-bordered table-condensed")
  )
)


## read old?
testf <- list.files("~/LOGs/BMeasurments/",
                    "*.csv",
                    full.names = T)

testf <- "/home/athan/LOGs/BMeasurments//TAP_2b.csv"
for (af in testf) {
  tmp <- fread(af)
  tmp <- tmp[grepl("Duster", cat1), ] |>
    select(-starts_with("gps")) |>
    rename(Date     = timestamp) |>
    rename(value    = number) |>
    rename(variable = cat1)

  test <- rbind(
    tmp  |> mutate(
      Day    = as.Date(Date),
      Source = "csv"),
    DATA |> mutate(Day = as.Date(Date),
                   Source = "DB") |>
      select(-color_index, -group),
    fill = T
  ) |> select(-Milliseconds )

  test <- test |> filter(
    Day >= test[Source == "csv", range(Day)][1] &
    Day <= test[Source == "csv", range(Day)][2]
  )
  setorder(test, "Date")
  print(tail(test, 55))
}


p <- ggplot(test, aes(x = Date, y = Source)) +
  geom_point()
print(p)



## get last service
LASTSERV <- DATA |> filter(variable == "Service") |> filter(max(Date) == Date)
LASTTRIP <- DTRIP |> filter(variable == "km") |> filter(max(value) == value)
LASTSERV$label <- as.numeric(LASTSERV$label)

warn_tyres <- 5000
warn_servi <- 9000


if (LASTTRIP$value > LASTSERV$label + warn_tyres) {
  summary <- paste0("Brake pads warning over ", LASTTRIP$value - (LASTSERV$label + warn_tyres), "km")
  body    <- paste("Replace brakepads")

  res     <- system(paste0("dunstify -b -u normal -t 0 ",
                           " ' ", summary, "' ' ", body,  "'"),
                    intern = F, wait = F)
}

if (LASTTRIP$value > LASTSERV$label + warn_servi) {
  summary <- paste0("Service warning in ", LASTSERV$label + warn_servi + 10000 - LASTTRIP$value , "km")
  body    <- paste("Replace brakepads")
  res     <- system(paste0("dunstify -b -u normal -t 0 ",
                           " '", summary, "' "),
                    intern = F, wait = F)
}




tac = Sys.time();
cat(sprintf("%s %s@%s %s %f mins\n\n",Sys.time(),Sys.info()["login"],Sys.info()["nodename"],Script.Name,difftime(tac,tic,units="mins")))
