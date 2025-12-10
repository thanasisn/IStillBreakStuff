#!/usr/bin/env Rscript
# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */

rm(list = (ls()[ls() != ""]))
Script.Name <- "~/CODE/R_MISC/nanopool_scrap.R"
Sys.setenv(TZ = "UTC")
tic <- Sys.time()

## __  Set environment ---------------------------------------------------------
require(data.table, quietly = TRUE, warn.conflicts = FALSE)
require(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
require(httr,       quietly = TRUE, warn.conflicts = FALSE)
library(tidyr,      quietly = TRUE, warn.conflicts = FALSE)

source("/home/athan/Formal/KEYS/nanopool")
storagePre <- "~/DATA/Other/Nanopool_"


# Miner - Account Balance
# https://api.nanopool.org/v1/xmr/balance/:address
#
# Miner - Average Hashrate
# https://api.nanopool.org/v1/xmr/avghashrate/:address
#
# Miner - Chart Data
# https://api.nanopool.org/v1/xmr/hashratechart/:address
#
# Miner - Current Hashrate
# https://api.nanopool.org/v1/xmr/hashrate/:address
#
# Miner - Hashrate History
# https://api.nanopool.org/v1/xmr/history/:address
#
# Miner - List of Worker
# https://api.nanopool.org/v1/xmr/workers/:address
#
# Miner - Share Rate History
# https://api.nanopool.org/v1/xmr/shareratehistory/:address


# tags <- c(
#   # "balance",
#   # "avghashrate",
#   # "hashratechart",
#   # "hashrate",
#   # "history",
#   # "workers",
#   "shareratehistory",
#   NULL
# )
#
# for (at in tags) {
#   url <- paste0("https://api.nanopool.org/v1/xmr/",
#                 at, "/",
#                 ADDRESS)
#   cat(url, "\n")
#   res <- GET(url, accept_json())
#   print(content(res, type="application/json"))
# }

## read json from site
read_tag <- function(tag) {
  content(
    GET(
      paste0("https://api.nanopool.org/v1/xmr/",
             tag,
             "/",
             ADDRESS),
      accept_json()),
    type = "application/json")
}

## read json and make a table or variable
read_data <- function(tag) {
  res <- read_tag(tag)
  if (res[["status"]]) {
    cat("Got:", tag, "\n")
    if (is.list(res[["data"]])) {
      DT_tmp           <- data.frame(t(list2DF(res[["data"]])))
      names(DT_tmp)    <- names(res[["data"]][[1]])
      rownames(DT_tmp) <- NULL
      tblname          <<- paste0(tag, "_DT")
      assign(tblname, DT_tmp, envir = .GlobalEnv)
      cat("Created:", tblname, "\n")
    } else {
      tblname          <<- paste0(tag, "_Value")
      assign(tblname, res[["data"]], envir = .GlobalEnv)
      cat("Created:", tblname, "\n")
    }
  } else {
    cat("No response for", tag, "\n")
  }
}

##  Parse and store what we care for  ---------------

try({
  filest <- paste0(storagePre, "Status.Rds")
  read_data("balance")
  read_data("hashrate")
  if (!exists("balance_Value"))  {balance_Value <- NA}
  if (!exists("hashrate_Value")) {hashrate_Value <- NA}
  current <- data.frame(Date     = Sys.time(),
                        Balande  = balance_Value,
                        Hashrate = hashrate_Value)
  if (file.exists(filest)) {
    STATUS <- readRDS(filest)
    STATUS <- rbind(STATUS, current)
  } else {
    STATUS <- current
  }
  saveRDS(STATUS, filest)
})

try({
  filest <- paste0(storagePre, "Hashratechart.Rds")
  read_data(                   "hashratechart")
  if (file.exists(filest)) {
    STATUS <- readRDS(filest)
    STATUS <- rbind(STATUS,     hashratechart_DT)
  } else {
    STATUS <-                   hashratechart_DT
  }
  STATUS <- unique(STATUS)
  saveRDS(STATUS, filest)
})

try({
  filest <- paste0(storagePre, "History.Rds")
  read_data(                   "history")
  if (file.exists(filest)) {
    STATUS <- readRDS(filest)
    STATUS <- rbind(STATUS,     history_DT)
  } else {
    STATUS <-                   history_DT
  }
  STATUS <- unique(STATUS)
  saveRDS(STATUS, filest)
})

try({
  filest <- paste0(storagePre, "Workers.Rds")
  read_data(                   "workers")
  workers_DT$Date <- Sys.time()
  if (file.exists(filest)) {
    STATUS <- readRDS(filest)
    STATUS <- rbind(STATUS,     workers_DT, fill = T)
  } else {
    STATUS <-                   workers_DT
  }
  saveRDS(STATUS, filest)
  STATUS <- data.table(
    LastShare = as.POSIXct(unlist(STATUS$lastShare), origin = "1970-01-01"),
    Rating    = unlist(STATUS$rating),
    ID        = unlist(STATUS$id),
    UID       = unlist(STATUS$uid),
    Date      = unlist(STATUS$Date),
    Hashrate  = unlist(STATUS$hashrate)
  )
  STATUS <- unique(STATUS)

  exp <- STATUS   |>
    group_by(UID) |>
    filter(Date == max(Date, na.rm = T)) |>
    data.frame() |>
    select(ID, Hashrate, Rating, LastShare)

  # exp           <- data.frame(WORK[Date == max(Date), .(ID, Hashrate, Rating, LastShare)])
  exp$LastShare <- as.POSIXct(exp$LastShare, tz = "Europe/Athens")
  exp           <- data.frame(exp)
  exp[]         <- lapply(exp, as.character)
  ## export flat table
  exp           <- rbind(colnames(exp), exp)
  gdata::write.fwf(x        = exp,
                   colnames = FALSE,
                   file     = "/dev/shm/nanopool.status")
})

try({
  filest <- paste0(storagePre, "Shareratehistory.Rds")
  read_data(                   "shareratehistory")
  if (file.exists(filest)) {
    STATUS <- readRDS(filest)
    STATUS <- rbind(STATUS,     shareratehistory_DT)
  } else {
    STATUS <-                   shareratehistory_DT
  }
  STATUS <- unique(STATUS)
  saveRDS(STATUS, filest)
})



try({
  filest <- paste0(storagePre, "Avghashrateworkers.Rds")
  tag <- "avghashrateworkers"
  res <- read_tag(tag)

  hcol <- names(res[["data"]])
  avghashrateworkers_DT <- list2DF(res[["data"]]) |>
    mutate(
      across(all_of(hcol),
             ~ lapply(., function(x) setNames(data.frame(t(c(x[[1]], x[[2]]))), c("Host", "Hashrate"))))) |>
    pivot_longer(
      cols      = hcol,
      names_to  = "time_interval",
      values_to = "data"
    ) |>
    unnest(data) |>
    mutate(
      Hashrate = as.numeric(Hashrate),
      Date     = Sys.time()
    )

  if (file.exists(filest)) {
    STATUS <- readRDS(filest)
    STATUS <- rbind(STATUS,     avghashrateworkers_DT)
  } else {
    STATUS <-                   avghashrateworkers_DT
  }
  STATUS <- unique(STATUS)
  saveRDS(STATUS, filest)
})



# source("~/CODE/R_MISC/nanopool_plot.R")


#+ include=T, echo=F, results="asis"
tac <- Sys.time()
cat(sprintf("**END** %s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
