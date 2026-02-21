#!/usr/bin/env Rscript
# /* Copyright (C) 2022-2025 Athanasios Natsis <natsisphysicist@gmail.com> */

## __ Set environment  ---------------------------------------------------------
closeAllConnections()
Sys.setenv(TZ = "UTC")

library(rmarkdown)



#### Run all regular data process for GoldenCheetah

dir.create("/dev/shm/CONKY", showWarnings = FALSE, recursive = TRUE)

try({
  source("~/CODE/data_streams/GC_status/GC01_read_rides_db_json.R")
})

try({
  render(input         = "~/CODE/data_streams/GC_status/GC02_plot_all_vars.R",
         output_format = bookdown::html_document2(),
         output_dir    = "~/Formal/REPORTS/")
})

try({
  render(input         = "~/CODE/data_streams/GC_status/GC03_plot_last_vars.R",
         output_format = bookdown::html_document2(),
         output_dir    = "~/Formal/REPORTS/")
})

stop("SSSS wait")

try({
  source("~/CODE/training_analysis/GC_data_proccess/GC_more_plots_rides_db.R")
})

try({
  source("~/CODE/training_analysis/GC_data_proccess/GC_conky_plots_rides_db.R")
})


# todo
try({
  source("~/CODE/training_analysis/GC_data_proccess/GC_shoes_usage_duration.R")
})


try({
  source("~/CODE/training_analysis/GC_shoes_usage_timeseries.R")
})

try({
  source("~/CODE/training_analysis/GC_target_load.R")
})

try({
  source("~/CODE/training_analysis/GC_target_estimation.R")
})



