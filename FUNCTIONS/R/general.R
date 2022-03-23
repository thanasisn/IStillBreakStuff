
#### Some general usage functions.



#' Check internet by asking if google.com is available
#'
#' @return Boolean
#' @export
#'
internet <- function() {
  out <- try(is.character( RCurl::getURL("www.google.com"))) == TRUE
  if ( ! out ) {
    warning("No internet!")
    return(FALSE)
    # cat(paste("exit"))
    # quit(save = "no", status = 0)
  }
  else {
    return(TRUE)
  }
}



####    Date Times    ##########################################################



#' Format seconds to " d H:M:S "
#'
#' @param x Number of seconds
#'
#' @return String of seconds as "d H:M:S"
#' @export
#'
seconds.to.hms <- function (x) {
    if (!is.integer(x))
        x <- as.integer(floor(as.numeric(x)))
    hours <- as.integer(trunc(x/3600))
    x <- x - hours * 3600L
    stopifnot(is.integer(x))
    minutes <- as.integer(trunc(x/60))
    seconds <- x - minutes * 60L
    stopifnot(is.integer(seconds))
    ret <- sprintf("%.2d:%.2d:%.2d", hours, abs(minutes), abs(seconds))
    ret[is.na(x)] <- NA
    ret
}



#' @title Convert Time Excel
#' @description Helper function for converting the datetime stamps from Microsoft Excel.
#' @param  x   The object to be converted. Typically a numeric when converting from excel to a POSIXct.
#' @param  tz  The timezone of the epoch used to save the numeric type, almost \emph{ALWAYS} GMT.
#' @param  rev Whether or not the operation should be reversed. This is a lossless operation.
#' @export
conv.time.excel <- function(x, tz = "GMT", rev = FALSE) {
    if (rev) {
        return(as.numeric(difftime(x, as.POSIXct("1899-12-30 00:00:00", tz = 'GMT'), units = 'days')))
    }
    as.POSIXct(x * 86400, origin = "1899-12-30 00:00:00", tz = tz)
}



#' @title Convert Time Unix
#' @description A function used to convert a unix timestamp into a POSIXct object.
#' @description Typical examples of unix timestamps include any POSIX object that has been coerced into a numeric.
#' @param x  The numeric value that will be converted.
#' @param tz The timezone of the epoch used for the timestamp, almost always GMT.
#' @export
conv.time.unix <- function(x, tz='GMT') {
    as.POSIXct(x, origin = "1970-01-01", tz = tz)
}


#' @title Convert Time Matlab
#' @param x The numeric timestamp that will be converted.
#' @export
conv.time.matlab <- function(x, tz = "GMT") {
    as.POSIXct((x - 1) * 86400, origin = "0000-01-01", tz = tz)
}


#' @title Make Datetime Object
#' @description A helper function to generate a datetime object
#' @param  year   Year (e.g. 2016)
#' @param  month  Month (1-12)
#' @param  day    Day (1-31)
#' @param  hour   Hour (0-23)
#' @param  minute Minute (0-59)
#' @param  second Second (0-59)
#' @param  tz     System available timezone
#' @export
make.time <- function(year = NULL, month = 1, day = 1, hour = 0, minute = 0, second = 0, tz = 'GMT') {
  if (is.null(year)) {return(Sys.time())}
  as.POSIXct(paste0(year, '-', month, '-', day, ' ', hour, ':', minute, ':', second), tz = tz)
}


#' @title Which Closest Time
#' @description  Find the indices of the closest times for each entry of x
#' @export
which.closest.time <- function(x, y) {
    if (length(y) > 1) {
        l = c()
        for (i in 1:length(x)) {
            l.new = which.min(as.numeric(difftime(x[i], y, units = 'mins'))^2)
            l = c(l, l.new)
        }
    } else {
        l = which.min(as.numeric(difftime(x, y, units = 'mins'))^2)
    }
    l
}

#' @title Is POSIXct
#' @description A helper function to determine if an object or a vector of objects is POSIX.
#' @keywords Time Helper
#' @export
is.POSIXct <- function(x){inherits(x, "POSIXct")}


#' @title Which Unique
#' @description Find the indices of the unique entries.
#' @keywords
#' @param x A vector of entries.
#' @export
which.unique <- function(x) {
    which(!duplicated(x))
}



#' @title Is Within
#' @author Thomas Bryce Kelly
#' @description Filter a vector of entries with fall between a set of bounds (i.e. on a closed interval).
#' @keywords
#' @param  x      A vector of any type with strict ordering (i.e. where '>' or '<' are valid operators).
#' @param  bounds A vector of two entries, where bounds[1] is the lower bound and bounds[2] is the upper.
#' @export
is.within <- function(x, bounds) {
    x >= bounds[1] & x <= bounds[2]
}




#' @title Which Within
#' @author Thomas Bryce Kelly
#' @description Filter a vector of entries with fall between a set of bounds (i.e. on a closed interval).
#' @keywords
#' @param x A vector of any type with strict ordering (i.e. where '>' or '<' are valid operators).
#' @param bounds A vector of two entries, where bounds[1] is the lower bound and bounds[2] is the upper.
#' @export
which.within <- function(x, bounds) {
  which(is.within(x, bounds))
}




####    Statistics    ##########################################################

#' @title Moving Average
#' @description Calculate the moving average from a series of observations. \emph{NB}: It assumes equally spaced observations
#' @keywords Statistics
#' @param  x   A vector containing equally spaced observations
#' @param  n   The number of samples to include in the moving average.
#' @export
ma <- function(x, n = 5){
    filter(x, rep(1/n, n), sides = 2)
}




