
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
             exist = file.exists(file),
               type  = "source",
               hash  = digest(detext_source(file, ...), algo = "sha1", serialize = TRUE))
  } else {
    data.frame(mtime = NA,
               atime = NA,
               path  = file,
             exist = file.exists(file),
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

  data.frame(mtime = as.numeric(file.mtime(file)),
             atime = as.numeric(Sys.time()),
             path  = file,
             exist = file.exists(file),
             type  = "data",
             hash  = NA)
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


## Environment to pass make argumets
R_make_ <- new.env(parent = emptyenv())

check_Rmake <- function(depend.source = c(),
                        depend.data   = c(),
                        targets       = c(),
                        file = "_Rmake.mc",
                        path = "./") {
  ## default file to read depend
  Rmkfile <- paste0(path, "/", file)

  ## srore some variables
  R_make_$file          <- Rmkfile
  R_make_$depend.source <- depend.source
  R_make_$depend.data   <- depend.data
  R_make_$targets       <- targets
  R_make_$RUN           <- FALSE

  ## parse source files
  ss <- data.frame()
  for (sf in depend.source) {
    ss <- rbind(ss, id_source(sf))
  }
  ## parse data files
  dd <- data.frame()
  for (df in depend.data) {
    dd <- rbind(dd, id_data(df))
  }
  ## parse target files
  tt <- data.frame()
  for (tf in targets) {
    dd <- rbind(dd, id_source(tf))
    dd$type <- "target"
  }

  new <- rbind(dd, ss, tt)

  write.csv(new, Rmkfile, row.names = FALSE)






  return(new)


  ## Source hash changed from previous run
  ## Source hash not existk
  ## Data date changed from previous run
  ## Data target not exist




}


new <- check_Rmake(depend.source = c( "function.R", "~/CODE/FUNCTIONS/R/make_tools.R"),
                   depend.data  = c("~/DATA/Broad_Band/Broad_Band_DB_metadata.parquet"),
                   targets      = c("~/ZHOST/testfile") )


new$type == "target"

store_Rmake <- function() {
  return(R_make_$depend.data)
}

store_Rmake()

write.csv(1, "~/ZHOST/testfile")
