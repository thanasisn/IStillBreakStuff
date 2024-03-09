
#### Create `make` like rules in R

#'
#' Functions used in R scripts, to create rules similar to `GNU make`
#' logic, where a target depends on data "mtime" or source code hash.
#' The intent is to create a workflow chain for data processing projects.
#'
#' 1. Create and/or test rule output.
#' 2. Do work...
#' 3. Store rule state for retest
#'


#' Helper function to clean text file from spaces and comments
#'
#' @param file        Source file to parse
#' @param rm.comment  Remove comments default `TRUE`
#' @param rm.space    Remove empty space default `TRUE`
#' @param commend.ch  First character of comments default `#`
#'
#' @return            A string
#'
detext_source <- function(file,
                           rm.comment = TRUE,
                           rm.space   = TRUE,
                           comment.ch = "#") {
  if (rm.comment == TRUE) {
    res <- paste0(gsub(paste0(comment.ch, ".*"),
                       "",
                       readLines(file, warn = FALSE)),
                  collapse = "")
  } else {
    res <- paste0(readLines(file, warn = FALSE),
                  collapse = "")
  }
  if (rm.space == TRUE) {
    res <- gsub("[ \t]*", "", res)
  }
  return(res)
}


#' Helper function to id a "source" file by hash
#'
#' @param file    A source file to id with `detext_source`
#' @param ...     Parameters passed to `detext_source`
#'
#' @return        Data frame
#'
id_source <- function(file, ...) {

  require(digest, quietly = TRUE)

  if (file.exists(file)) {
    data.frame(mtime = as.numeric(file.mtime(file)),
               atime = as.numeric(Sys.time()),
               path  = file,
               type  = "source",
               hash  = digest(detext_source(file, ...), algo = "sha1", serialize = TRUE))
  } else {
    data.frame(mtime = NA,
               atime = NA,
               path  = file,
               type  = "source",
               hash  = NA)
  }
}


#' Helper function to id a "data" file by mtime
#'
#' @param file   A data file to id
#'
#' @return       A data frame
#'
id_data <- function(file) {

  require(digest, quietly = TRUE)

  if (file.exists(file)) {
    data.frame(mtime = as.numeric(file.mtime(file)),
               atime = as.numeric(Sys.time()),
               path  = file,
               type  = "data",
               # hash  = digest(file, algo = "sha1", serialize = TRUE)
               hash  = NA)
  } else {
    data.frame(mtime = NA,
               atime = NA,
               path  = file,
               type  = "data",
               hash  = NA)
  }
}



## Function to store options
## all was good
## - read rmk
## - read input
## - clean input
## - store input


## Function to check options
## - read
## - compare input
## - T/F


## Create and read lock file

## store common option for input



read_Rmake <- function(file = "_Rmake.mc",
                       path = "./") {
  Rmkfile <- paste0(path, "/", file)
}


write_Rmake <- function(file = "_Rmake.mc",
                        path = "./") {
  Rmkfile <- paste0(path, "/", file)
}

read_Rmake()



id_source("function.R", rm.commend = F)
id_source("dfdsfs")
id_data("./_targets/objects/drop_zeros")



snap_Rmake <- function(depend.source = c(),
                       depend.data   = c(),
                       file = "_Rmake.mc",
                       path = "./") {
  Rmkfile <- paste0(path, "/", file)
}


check_Rmake <- function(depend.source = c(),
                        depend.data   = c(),
                        target.source = c(),
                        file = "_Rmake.mc",
                        path = "./") {
  ## file to read depend
  Rmkfile <- paste0(path, "/", file)

  ## parse source files
  ss <- data.frame()
  for (sf in depend.source) {
    ss <- rbind(ss, id_source(sf))
  }
  ## parse data files
  dd <- data.frame()
  for (df in depend.data) {
    dd <- rbind(dd, id_source(df))
  }
  new <- rbind(dd, ss)
  ## parse target files
  tt <- data.frame()
  for (tf in target.source) {
    dd <- rbind(dd, id_source(tf))
    dd$type <- "targer"
  }


  write.csv(new, Rmkfile, row.names = FALSE)


  return(new)


  ## Source hash changed from previous run
  ## Source hash not exist
  ## Data date changed from previous run
  ## Data target not exist

}


check_Rmake(depend.source = c("_targets/objects/drop_zeros", "function.R"))

