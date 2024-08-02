#!/usr/bin/env Rscript
# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */

####  Log directories sizes on multiple depths
## Use full names

rm(list = (ls()[ls() != ""]))
Script.Name <- "/home/athan/CODE/system_tools/Folders_size_log.R"
Sys.setenv(TZ = "UTC")
tic <- Sys.time()

## load `du` function
source("/home/athan/CODE/FUNCTIONS/R/system.R")

## data storage path
data_fl      <- paste0("/home/athan/LOGs/SYSTEM_LOGS/Log_folders_size_", Sys.info()["nodename"], ".Rds")

## folders to monitor
root_folders <- c("/")
# root_folders <- c("/home/athan/DATA/")   ## test

## ignore small folders
size_limit   <- 200 * 1024^2

## Use incremental data storage mostly for debbuging
INCREMENTAL_STORAGE <- FALSE
INCREMENTAL_STORAGE <- TRUE

## just to count the analysed folders
cnf <- 0
lev <- 0

#' Get the size of a folder under condition
#'
#' @param path  Path to run `du`
#' @param slim  Ignore folder with less than this size
#'
#' @return      A data.frame row with the data
#' @export
#'
get_size <- function(path, slim = size_limit) {
  if (file.exists(path)) {
    ## create a record
    res <- data.frame(file = path,
                      size = Sys.du(path),
                      Date = as.numeric(Sys.Date()))
    ## output only relevant
    res[res$size > slim, ]
  }
}


#' Save data to file with deduplication
#'
#' @param data  A data frame to save
#' @param file  A path for the .Rds file
#'
#' @return      Nothing, writes to disk
#'
store_data <- function(data, file) {
  data <- data[!duplicated(data[c("file", "Date")]),]
  saveRDS(data, file = file)
  Sys.chmod(file, "777", use_umask = FALSE)
  cat(nrow(data), "Folder sizes logged! ->", file, "\n\n")
}


#' Recursive function to log sizes of folders under conditions
#'
#' @param paths The root paths of folders to monitor
#'
#' @return      A data.frame and/or a `.Rds` with the results
#' @export
#'
log.dirs.size <- function(paths, data_store, use_data_store = FALSE) {
  res <-
    unique(
      sub("/[/]+", "/",
          list.dirs(paths, recursive = FALSE)
      )
    )

  ## prune dirs
  res <- grep(".git/.*", res, value = T, invert = TRUE)
  res <- grep("^/media", res, value = T, invert = TRUE)
  res <- grep("^/mnt",   res, value = T, invert = TRUE)
  res <- grep("^/proc",  res, value = T, invert = TRUE)
  res <- grep("^/sys",   res, value = T, invert = TRUE)
  res <- grep("^/dev",   res, value = T, invert = TRUE)
  res <- grep("^/run",   res, value = T, invert = TRUE)

  ## get results on this level as a data.frame
  get <- do.call(rbind, lapply(res, get_size))
  cnf <<- cnf + length(res)
  lev <<- lev + 1
  ## Display this level results
  # print(get)
  cat("Depth:", lev, " Checked:", cnf, " Gathered", nrow(get),"\n")

  ## incremental store on every level no need to return data from function
  if (use_data_store) {
    if (file.exists(data_store)) {
      DATA <- rbind(readRDS(data_store), get, fill = T)
      store_data(data = DATA, file = data_store)
    } else {
      store_data(data = get, file = data_store)
    }
  }

  ## get results on the next level
  ## FIXME the return of the data frame may not be needed if incremental storage in use

  if (length(get$file) > 0) {

    nextfl <- get$file[file.exists(get$file)]
    # cat(nextfl, "\n\n")
    if (length(nextfl) > 0) {
      # cat(depth, "run again\n")
      add <- log.dirs.size(paths          = nextfl,
                           data_store     = data_store,
                           use_data_store = use_data_store)
      if (!use_data_store) { return(rbind(get, add)) }
    } else {
      # cat(depth, "run last\n")
      if (!use_data_store) { return(get) }
    }
  } else {
    # cat(depth, "run last\n")
    if (!use_data_store) { return(get) }
  }
}


##  Log sizes !! ---------------------------------------------------------------
cat("\nRoot dirs:\n")
cat(paste("            ", root_folders), sep = "\n")
cat("\n")

DATA <- log.dirs.size(paths      = root_folders,
                     data_store     = data_fl,
                     use_data_store = INCREMENTAL_STORAGE)

# DATA <- log.dirs.size(paths          = c("/home/athan/ZHOST"),
#                      data_store     = data_fl,
#                      use_data_store = INCREMENTAL_STORAGE)

if (!INCREMENTAL_STORAGE) {
  if (nrow(new) > 0) {
    if (file.exists(data_fl)) {
      DATA <- rbind(readRDS(data_fl), DATA, fill = T)
      store_data(data = DATA, file = data_fl)
    } else {
      store_data(data = DATA, file = data_fl)
    }
  }
}


## END ##
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
