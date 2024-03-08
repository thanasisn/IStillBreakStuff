
#' Clean source from non info
#'
#' @param file        Source file to parse
#' @param rm.commend  Remove comments default `TRUE`
#' @param rm.space    Remove empty space default `TRUE`
#' @param commend.ch  First character of comments default `#`
#'
#' @return            A string
#'
detext_source <- function(file,
                           rm.commend = TRUE,
                           rm.space   = TRUE,
                           commend.ch = "#") {
  if (rm.commend == TRUE) {
    res <- paste0(gsub(paste0(commend.ch, ".*"),
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


#' Id a source file
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
               hash  = digest(detext_source(file, ...), algo = "sha1", serialize = TRUE))
  } else {
    data.frame(mtime = NA,
               atime = NA,
               path  = file,
               hash  = NA)
  }
}


#' Id a data file
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
               hash  = digest(file, algo = "sha1", serialize = TRUE))
  } else {
    data.frame(mtime = NA,
               atime = NA,
               path  = file,
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



snap_Rmake <- function(source.files = c(),
                       data.files   = c(),
                       file = "_Rmake.mc",
                       path = "./") {
  Rmkfile <- paste0(path, "/", file)
}


check_Rmake <- function(source.files = c(),
                        data.files   = c(),
                        file = "_Rmake.mc",
                        path = "./") {
  Rmkfile <- paste0(path, "/", file)

  ss <- data.frame()
  for (sf in source.files) {
    ss <- rbind(ss, id_source(sf))
  }
  dd <- data.frame()
  for (df in data.files) {
    dd <- rbind(dd, id_source(df))
  }
  new <- rbind(dd, ss)


  write.csv(new, Rmkfile, row.names = FALSE)


  return(new)

}


check_Rmake(source.files = c("_targets/objects/drop_zeros", "function.R"))

