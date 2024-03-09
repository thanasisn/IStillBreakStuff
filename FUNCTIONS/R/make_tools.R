
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
Rmk_detext_source <- function(file,
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
#' @param file    A source file to id with `Rmk_detext_source`
#' @param ...     Parameters passed to `Rmk_detext_source`
#'
#' @return        Data frame
#'
Rmk_id_source <- function(file, ...) {

  require(digest, quietly = TRUE)

  if (file.exists(file)) {
    data.frame(mtime = as.numeric(file.mtime(file)),
               atime = as.numeric(Sys.time()),
               path  = file,
             exist = file.exists(file),
               type  = "source",
               hash  = digest(Rmk_detext_source(file, ...), algo = "sha1", serialize = TRUE))
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
Rmk_id_data <- function(file) {

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




parse_files <- function(depend.source = c(),
                        depend.data   = c(),
                        targets       = c()) {

  ## parse source files
  ss <- data.frame()
  for (sf in depend.source) {
    ss <- rbind(ss, Rmk_id_source(sf))
  }
  ## parse data files
  dd <- data.frame()
  for (df in depend.data) {
    dd <- rbind(dd, Rmk_id_data(df))
  }
  ## parse target files
  tt <- data.frame()
  for (tf in targets) {
    tt <- rbind(tt, Rmk_id_data(tf))
    tt$type <- "target"
  }

  rbind(dd, ss, tt)
}





snap_Rmake <- function(depend.source = c(),
                       depend.data   = c(),
                       file = ".R_make.mk",
                       path = "./") {
  Rmkfile <- paste0(path, "/", file)
}


## Environment to pass make argumets
R_make_ <- new.env(parent = emptyenv())




check_Rmake <- function(depend.source = c(),
                        depend.data   = c(),
                        targets       = c(),
                        file = ".R_make.mk",
                        path = "./") {
  ## default file to read depend
  Rmkfile <- paste0(path, "/", file)

  ## store some variables
  R_make_$file          <- Rmkfile
  R_make_$depend.source <- depend.source
  R_make_$depend.data   <- depend.data
  R_make_$targets       <- targets
  R_make_$RUN           <- FALSE

  ## parse dependencies and targets
  new <- parse_files(
    depend.source = depend.source,
    depend.data   = depend.data,
    targets       = targets
  )

  ## Inform and ignore missing dependencies
  mis_dep <- new$type %in% c("source", "data") & new$exist == FALSE
  if (any(mis_dep)) {
    cat("Ignoring missing dependencies:\n")
    cat(paste(" > ", new[mis_dep, "path"]), sep = "\n")
    warning("Ignoring missing dependencies: ", new[mis_dep, "path"])
    new <- new[!mis_dep, ]
  }

  ## Check if we missing targets
  mis_tar <- new$type  == "target" & new$exist == FALSE
  if (any(mis_tar)) {
    cat("Not existing targets:\n")
    cat(paste(" < ", new[mis_tar, "path"]), sep = "\n")
    cat("\nHAVE TO RUN\n\n")
    R_make_$RUN <- TRUE
    ## return
  }

  ## Check if we know of previous runs
  if (!file.exists(Rmkfile)) {
    cat("No previous watch file found: ", Rmkfile, "\n")
    cat("\nHAVE TO RUN\n\n")
    R_make_$RUN <- TRUE
  } else {
    old <- read.csv(Rmkfile)
  }


  print(R_make_$RUN)

  return(list(new = new, old = old))


  ## Source hash changed from previous run
  ## Source hash not existk
  ## Data date changed from previous run
  ## Data target not exist




}


out <- check_Rmake(depend.source = c("~/CODE/FUNCTIONS/R/make_tools.R"),
                   depend.data  = c("~/DATA/Broad_Band/Broad_Band_DB_metadata.parquet"),
                   targets      = c("~/ZHOST/testfile", "~/ZHOST/testfile2") )
out


out <- check_Rmake(depend.source = c("~/CODE/FUNCTIONS/R/make_tools.R"),
                   depend.data  = c("~/DATA/Broad_Band/Broad_Band_DB_metadata.parquet")
                   )
(out)

new <- out$new
old <- out$old

## check for changes in source



new_s <- new[new$type == "source", ]

old_s <- old[old$type == "source", ]


read.csv(R_make_$file)


store_Rmake <- function() {
  write.csv(new, R_make_$file, row.names = FALSE)
}
store_Rmake()

print(R_make_$file)


write.csv(1, "~/ZHOST/testfile")


Rmk_id_source("function.R", rm.commend = F)
Rmk_id_source("dfdsfs")
Rmk_id_data("./_targets/objects/drop_zeros")
