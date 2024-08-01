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


#' Recursive function to log sizes of folders under conditions
#'
#' @param paths The root paths of folders to monitor
#'
#' @return      A data.frame and/or a `.Rds` with the results
#' @export
#'
log.dirs.size <- function(paths, data_store) {
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

  ## incremental store on every level
  ## remove and use return of fuction
  #; if (file.exists(data_store)) {
  #;   DATA <- rbind(readRDS(data_store), get, fill = T)
  #;   DATA <- DATA[!duplicated(DATA[c("file", "Date")]),]
  #;   saveRDS(DATA, file = data_store)
  #;   Sys.chmod(data_store, "777", use_umask = FALSE)
  #;   cat(nrow(DATA), "Folder sizes logged! ->", data_store, "\n\n")
  #; } else {
  #;   DATA <- unique(get)
  #;   saveRDS(DATA, file = data_store)
  #;   Sys.chmod(data_store, "777", use_umask = FALSE)
  #;   cat(nrow(DATA), "Folder sizes logged! ->", data_store, "\n\n")
  #; }

  ## get results on the next level
  ## FIXME the return of the data frame may not be needed
  if (sum(file.exists(get$file)) > 0) {
    # cat(depth, "run again\n")
    add <- log.dirs.size(paths      = get$file,
                         data_store = data_store)
    ## Function output
    rbind(get, add)
  } else {
    # cat(depth, "run last\n")
    ## Function output
    get
  }
}


##  Log sizes !! ---------------------------------------------------------------
cat("\nRoot dirs:\n")
cat(paste("            ", root_folders), sep = "\n")
cat("\n")

new <- log.dirs.size(paths      = root_folders,
                     data_store = data_fl)


if (nrow(new) > 0) {
  if (file.exists(data_fl)) {
    DATA <- rbind(readRDS(data_fl), new, fill = T)
    DATA <- DATA[!duplicated(DATA[c("file", "Date")]),]
    saveRDS(DATA, file = data_fl)
    Sys.chmod(data_fl, "777", use_umask = FALSE)
    cat(nrow(DATA), "Folder sizes logged! ->", data_fl, "\n\n")
  } else {
    DATA <- unique(new)
    saveRDS(DATA, file = data_fl)
    Sys.chmod(data_fl, "777", use_umask = FALSE)
    cat(nrow(DATA), "Folder sizes logged! ->", data_fl, "\n\n")
  }
}


## END ##
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
