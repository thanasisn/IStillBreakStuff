
#### Create `make` like rules in R

#'
#' Functions used in R scripts, to create rules similar to `GNU make`
#' logic, where a target depends on data `mtime` or source code hash.
#' The intent is to create a workflow chain for data processing projects.
#'
#' 1. Create and/or test rule output.
#' 2. Do the run or exit?
#' 3. Store rule state for retest after the run was successful
#'
#' Using a common file for the project, to store hashes and dates for the
#' dependencies, in order to detect meaningful changes of source files.
#' Data files always are compared against the last `mtime`.
#' Editing ".R_make.mk" can trigger full executions.
#'


## Will use an environment for some arguments passing
R_make_ <- new.env(parent = emptyenv())


#' Helper function to clean text file from spaces and comments
#'
#' @param file        Source file to parse
#' @param rm.comment  Remove comments default `TRUE`
#' @param rm.space    Remove empty space default `TRUE`
#' @param comment.char  First character of comments default `#`
#'
#' @return            A string
#'
Rmk_detext_source <- function(file,
                           rm.comment   = TRUE,
                           rm.space     = TRUE,
                           comment.char = "#") {
  if (rm.comment == TRUE) {
    res <- paste0(gsub(paste0(comment.char, ".*"),
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
    data.frame(mtime = ceiling(as.numeric(file.mtime(file)) * 1000),
               atime = as.numeric(Sys.time()),
               ptime = as.character(Sys.time()),
               path  = file,
               exist = TRUE,
               type  = "source",
               hash  = digest(
                 Rmk_detext_source(file, ...),
                 algo      = "sha1",
                 serialize = TRUE
               )
    )
  } else {
    data.frame(mtime = NA,
               atime = NA,
               ptime = NA,
               path  = file,
               exist = FALSE,
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

  if (file.exists(file)) {
    data.frame(mtime = ceiling(as.numeric(file.mtime(file))*1000),
               atime = as.numeric(Sys.time()),
               ptime = as.character(Sys.time()),
               path  = file,
               exist = TRUE,
               type  = "data",
               hash  = file.size(file))
  } else {
    data.frame(mtime = NA,
               atime = NA,
               ptime = NA,
               path  = file,
               exist = FALSE,
               type  = "source",
               hash  = NA)
  }
}


#' Helper function to parse the given files
#'
#' @param depend.source
#' @param depend.data
#' @param targets
#'
#' @return
#'
Rmk_parse_files <- function(depend.source = c(),
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


#' Check dependencies and decide if we need to run
#'
#' @param depend.source Source files we depend on (optional)
#' @param depend.data   Data files we depend on (optional)
#' @param targets       Target files we produce with the run (optional)
#' @param data.oldness  Time difference for data mtime check in seconds (optional)
#' @param file          File to store project dependencies (default ".R_make.mk")
#' @param path          Folder to store project dependencies (default "./")
#' @note
#' Use this at the start of the script to check the dependencies rules of the
#' executions. Have to use `Rmk_store_depend` to store the state of the source
#' files. No need if you only care for data files.
#'
#' @return              TRUE: have to run, FALSE: no need to run
#'
Rmk_check_dependencies <- function(depend.source = c(),
                                   depend.data   = c(),
                                   targets       = c(),
                                   data.oldness  = 0.1,
                                   file = ".R_make.mk",
                                   path = "./") {

  ## seconds to milliseconds
  d_mtime_lim <- data.oldness * 1000

  ## Default file to read depend
  Rmkfile <- paste0(path, "/", file)

  ## Store some variables for reuse
  R_make_$file          <- Rmkfile
  R_make_$depend.source <- depend.source
  R_make_$depend.data   <- depend.data
  R_make_$targets       <- targets
  R_make_$RUN           <- FALSE

  ## Parse current dependencies and targets
  new <- Rmk_parse_files(
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

  ## _ Check for Missing targets  -----------------
  mis_tar <- new$type  == "target" & new$exist == FALSE
  if (any(mis_tar)) {
    cat("Not existing targets:\n")
    cat(paste(" < ", new[mis_tar, "path"]), sep = "\n")
    R_make_$RUN <- TRUE
    return(R_make_$RUN)
  }

  ## _ Load Previous runs in make file  -----------------------
  try({
    if (!file.exists(R_make_$file)) {
      cat("No previous make watch file found: ", R_make_$file, "\n")
      R_make_$RUN <- TRUE
      return(R_make_$RUN)
    } else {
      old <- read.csv(R_make_$file)
    }
  }, silent = TRUE)

  ## _ Checks for source files -------------------
  new_s <- new[new$type == "source", c("path", "hash")]
  old_s <- old[old$type == "source", c("path", "hash")]

  if (nrow(new_s) > 0) {
    ## New dependencies
    if (any(!(new_s$path %in% old_s$path))){
      cat("Unrecorded source dependencies !!", "\n")
      R_make_$RUN <- TRUE
      return(R_make_$RUN)
    }

    ## Changed hashes
    for (ii in 1:nrow(new_s)) {
      item <- new_s[ii, ]

      if (any(old_s[item$path == old_s$path, ]$hash == item$hash)) {
        # if (any(duplicated(rbind(item, old_s)))) {
        cat("Not changed: ", item$path, "\n")
      } else {
        cat("UPDATED:     ", item$path, "\n")
        R_make_$RUN <- TRUE
        return(R_make_$RUN)
      }
    }
  }

  ## _ Checks for data files --------------------
  new_d <- new[new$type == "data", c("path", "mtime") ]
  old_d <- old[old$type == "data", c("path", "mtime") ]

  if (nrow(new_d) > 0) {
    ## New dependencies
    if (any(!(new_d$path %in% old_d$path))){
      cat("Unrecorded data dependencies !!", "\n")
      R_make_$RUN <- TRUE
      return(R_make_$RUN)
    }

    ## Changed mtime
    for (ii in 1:nrow(new_d)) {
      item <- new_d[ii, ]

      if (any(abs(old_d[item$path == old_d$path,]$mtime - item$mtime) < d_mtime_lim)) {
        cat("Not changed: ", item$path, "\n")
      } else {
        cat("UPDATED:     ", item$path, "\n")
        R_make_$RUN <- TRUE
        return(R_make_$RUN)
      }
    }
  }

  ## This should return false
  stopifnot(R_make_$RUN == FALSE)
  return(R_make_$RUN)
  # print(R_make_$RUN)
  # return(list(new = new, old = old))
}


#' Store the source files hashes for check against later
#'
#' @param depend.source Source files we depend on (optional)
#' @param depend.data   Data files we depend on (optional)
#' @param targets       Target files we produce with the run (optional)
#' @param file          File to store project dependencies (default ".R_make.mk")
#' @param path          Folder to store project dependencies (default "./")
#' @note
#' Use this at the end to store source files hashes in order to be
#' detected by `Rmk_check_dependencies`. It shouldn't matter for data files,
#' which compared with `mtime` only.
#'
#' @return
#' @export
#'
#' @examples
Rmk_store_dependencies <- function(depend.source = c(),
                                   depend.data   = c(),
                                   targets       = c(),
                                   file = ".R_make.mk",
                                   path = "./") {

  ## Default file to read dependencies
  Rmkfile <- paste0(path, "/", file)

  ## Store some variables for reuse
  R_make_$file <- Rmkfile

  ## update variables if needed
  if (length(depend.source) > 0) R_make_$depend.source <- depend.source
  if (length(depend.data)   > 0) R_make_$depend.data   <- depend.data
  if (length(targets)       > 0) R_make_$targets       <- targets

  ## Parse current dependencies and targets
  new <- Rmk_parse_files(
    depend.source = R_make_$depend.source,
    depend.data   = R_make_$depend.data,
    targets       = R_make_$targets
  )

  ## Read older entries
  try({
    if (file.exists(R_make_$file)) {
      old <- read.csv(R_make_$file)
      new <- rbind(old, new)
    }
  })

  ## Clear entries
  store <- data.frame()
  for (pp in unique(new$path)) {
    temp <- new[new$path == pp, ]
    store <- rbind(store, tail(temp[order(temp$mtime), ], n = 1))
  }

  ## Store entries
  if (nrow(store) > 0){
    write.csv(store, R_make_$file, row.names = FALSE)
    cat("Written `R_make_` file:", R_make_$file, "\n")
  }
}

## self example
# print(Rmk_check_dependencies(depend.source = c("~/CODE/FUNCTIONS/R/make_tools.R") ))
# Rmk_store_dependencies()
