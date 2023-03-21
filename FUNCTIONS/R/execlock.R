
#'
#' Create an R script lock file
#'
#' @param file A file name *.stopfile to use as a lock flag
#'
#' @details Create a file to use as an execution lock.
#'          Have to have an '.stopfile' extension for security.
#'
#' @export
#'
mylock <- function(file) {
    if (!exists("Script.Name")) {
        Script.Name <- "UNKNOWN SCRIPT"
    }
    if (file.exists(file)) {
        cat("\nLock file exist ", file, "\n")
        cat(readLines(DB_lock), "\n")
        stop("\nLock file: ", file)
    } else {
        cat("\nIssue Lock file ", file, "\n")
        cat(format(Sys.time()), " by: ", Script.Name, "\n",
            file = file)
    }
}


#'
#' Remove a lock file
#'
#' @param file A file name created by  `mylock`
#'
#' @details Will delete the lock file if have the .stopfile extension
#'
#' @export
#'
myunlock <- function(file) {
    if (file.exists(file)) {
        cat("\nLock file exist ", file, "\n")
        cat(readLines(file), "\n")
        if (grepl(".*\\.stopfile$", file)) {
            cat("Remove lock file ", file, "\n\n")
            file.remove(file)
        }
    } else {
        cat("\nNo lock file ", file, "\n")
    }
}

