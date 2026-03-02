# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "Car Scanner `r strftime(Sys.time(), '%F %R %Z', tz= 'Europe/Athens')`"
#' author: ""
#' output:
#'   html_document:
#'     toc:             true
#'     keep_md:         no
#' date: ""
#' ---
#+ echo=F, include=F


# TODO
# https://business-science.github.io/tidyquant/index.html

#+ echo=F, include=F
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/data_streams/car/C02_CarScannerParse.R"

## __ Document options ---------------------------------------------------------
knitr::opts_chunk$set(out.width  = "100%"   )

## __  Set environment ---------------------------------------------------------
suppressMessages({
  library(data.table, quietly = TRUE, warn.conflicts = FALSE)
  library(janitor,    quietly = TRUE, warn.conflicts = FALSE)
  library(ggplot2,    quietly = TRUE, warn.conflicts = FALSE)
  library(plotly,     quietly = TRUE, warn.conflicts = FALSE)
  library(DT,         quietly = TRUE, warn.conflicts = FALSE)
  library(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
  library(htmltools,  quietly = TRUE, warn.conflicts = FALSE)
  library(purrr,      quietly = TRUE, warn.conflicts = FALSE)
  library(lubridate,  quietly = TRUE, warn.conflicts = FALSE)
})

#+ include=FALSE, echo=FALSE
## init use of ggplot and html tables in loops
tagList(datatable(cars))
tagList(ggplotly(ggplot()))


infolder <- "~/MISC/a34_export/CarScanner/"
outfolder <- "~/DATA_RAW/Other/CarScanner"

drivecyclefl <- paste0(outfolder, "/DriveCycles.Rds")
driverecorfl <- paste0(outfolder, "/DriveRecords.Rds")

dir.create(outfolder, showWarnings = F)


tosave <- list.files(infolder,
                     pattern = "driveC.*days.csv",
                     full.names = TRUE)

for (af in tosave) {
  newfile <- paste0(outfolder, "/DriveCycles_", strftime(file.mtime(tosave), "%F_%T"), ".csv")
  file.copy(af, newfile, copy.date = TRUE)
}


##  Parse Summary  -------------------------------------------------------------
#'
#' # Parse Summary {-}
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis"


drivc <- list.files(outfolder,
                    pattern    = "DriveCycles.*.csv",
                    full.names = TRUE)

DC <- rbindlist(
  lapply(drivc, fread),
  use.names = TRUE,
  fill = TRUE) |>
  distinct()
DC <- remove_empty(DC, which = c("cols"))
setorder(DC, Started)
saveRDS(DC, drivecyclefl)


##  Parse Records  -------------------------------------------------------------
#'
#' # Parse Records {-}
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis"


recor <- list.files(infolder,
                    pattern    = "[0-9]{4}-.*.csv",
                    full.names = TRUE)

## parse all existing csv files
existdata <- data.table()
for (af in recor) {
  tmp          <- fread(af)
  tmp          <- remove_empty(tmp, which = c("cols"))

  dada     <- ymd(sub(".[0-9]{4}.[0-9]{2}.[0-9]{2}.csv$", "", basename(af)))
  tmp$Date <- ymd_hms(paste(dada, tmp$time))

  tmp$Basename <- basename(af)
  existdata    <- rbind(existdata, tmp, fill = TRUE)
}


if (file.exists(driverecorfl)) {
  DR <- readRDS(driverecorfl)
} else {
  DR <- data.table()
}

DR <- rbind(DR, existdata, fill = T) |> distinct()

saveRDS(DR, driverecorfl)


stats <- DR |>
  group_by(Basename) |>
  summarise(
    Start = min(Date, na.rm = T),
    Until = max(Date, na.rm = T),
    Average_fuel_consumption                   = last(`Average fuel consumption (L/100km)`, na_rm = TRUE),
    Average_fuel_consumption_Today             = last(`Average fuel consumption (Today) (L/100km)`, na_rm = TRUE ),
    Average_fuel_consumption_total             = last(`Average fuel consumption (total) (L/100km)`, na_rm = TRUE ),
    Average_fuel_consumption_Week              = last(`Average fuel consumption (Week) (L/100km)`, na_rm = TRUE ),
    Average_fuel_consumption_10sec             = last(`Average fuel consumption 10 sec (L/100km)`, na_rm = TRUE ),
    Calculated_engine_load_value_mean          = mean(DR$`Calculated engine load value (%)`, na.rm = T),
    Calculated_engine_load_value_median        = median(DR$`Calculated engine load value (%)`, na.rm = T),
    Calculated_instant_fuel_consumption_mean   = mean(`Calculated instant fuel consumption (L/100km)`, na_rm = TRUE ),
    Calculated_instant_fuel_consumption_median = median(`Calculated instant fuel consumption (L/100km)`, na_rm = TRUE ),
    Calculated_instant_fuel_rate_mean          = mean(`Calculated instant fuel rate (L/h)`, na_rm = TRUE ),
    Calculated_instant_fuel_rate_median        = median(`Calculated instant fuel rate (L/h)`, na_rm = TRUE ),
    Distance_travelled_km                      = last(`Distance travelled (km)`, na_rm = TRUE ),
    Fuel_used                                  = last(`Fuel used (L)`, na_rm = TRUE ),
  ) |>
  select(-Basename) |>
  arrange(Start) |>
  data.table()

stats <- stats |> remove_empty(which = "cols")

print(
  htmltools::tagList(
    datatable(
      stats,
      rownames = FALSE,
      options  = list(pageLength = 30),
      style    = "bootstrap",
      class    = "table-bordered table-condensed")
  )
)

DC[, Started  := round_date(Started,  unit = "minutes")]
DC[, Finished := round_date(Finished, unit = "minutes")]

print(
  htmltools::tagList(
    datatable(
      DC,
      rownames = FALSE,
      options  = list(pageLength = 30),
      style    = "bootstrap",
      class    = "table-bordered table-condensed")
  )
)



#+ include=T, echo=F, results="asis"
tac <- Sys.time()
cat(sprintf("**END** %s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
