
#### Data reshape and cleaning.


#' Vertical flip a matrix
#'
#' @param x Matrix like object
#'
#' @return A matrix with previous data with the last row first
#' @export
#'
flip_matrix_v <- function(x) {
    xx <- as.data.frame(x)
    xx <- rev(xx)
    xx <- as.matrix(xx)
    xx
}



#' Remove columns form data.table by grep pattern
#'
#' @param DT       A data.table object
#' @param pattern  A grep pattern to match columns to remove
#' @details        This will remove all columns form a data.table object that
#'                 match the given pattern. The changes are done in place.
#'                 All warnings are suppressed.
#' @return         Nothing the columns are removed in-place
#' @export
#'
rm.cols.DT <- function( DT , pattern ) {
    message(paste("\nRemoving columns:", grep( pattern , names(DT), value = T) ))
    # cat(paste("\nRemoving columns:", grep( pattern , names(DT), value = T) ),"\n")
    suppressWarnings(
        DT[ , (grep( pattern , names(DT))) := NULL ]
    )
}



#' Remove columns filled with identical elements from data.table
#'
#' @param DT A data.table
#'
#' @return   A new data.table with removed the duplicate filled columns
#' @export
#'
rm.cols.dups.DT <- function( DT ) {
    if (nrow(DT) > 1) {
        dtnames <- names(DT)
        suppressWarnings({
            vec <- vapply(DT, function(x) length(unique(x)) > 1, logical(1L))
            cat(paste("Removed columns:", length(dtnames[!vec]),"\n"))
            print( dtnames[!vec] )
            return( DT[ , ..vec ] )
        })
    } else {
        return(DT)
    }
}


#' Remove columns filled only with NA from data.table
#'
#' @param DT A data.table
#'
#' @return   A new data.table without NA filled columns
#' @export
#'
rm.cols.NA.DT <- function( DT ) {
    if (nrow(DT) > 1) {
        dtnames <- names(DT)
        suppressWarnings({
            vec <- vapply(DT, function(x) ! all(is.na(x)), logical(1L) )
            cat(paste("Removed columns:", length(dtnames[!vec]),"\n"))
            print( dtnames[!vec] )
            return( DT[ , ..vec ] )
        })
    } else {
        return(DT)
    }
}



#' Remove columns filled with identical elements from data.frame
#'
#' @param dataframe A data.frame
#'
#' @return   A new data.table with removed the duplicate filled columns
#' @export
#'
rm.cols.dups.df <- function(dataframe) {
    if (nrow(dataframe) > 1) {
        return(
            dataframe[
                vapply(dataframe,
                       function(x) length(unique(x)) > 1, logical(1L))
            ]
        )
    } else {
        return(dataframe)
    }
}




#' Replace NaN with NA at a data.table inline
#'
#' @param DT   A data frame to replace NaN's
#'
#' @return     Nothing the original DT is changed
#' @export
#'
nan.to.na.DT <- function(DT) {
    for (i in names(DT))
        DT[is.nan(get(i)), (i) := NA]
}



#' Round a number with a defined step
#'
#' @param Data  Data object with numbers
#' @param num   The step of the rounding
#'
#' @return      Rounded data
#' @export
#'
round_by_num <- function( Data, num ) {
    ( Data %/% num ) * num
}



#' @title        'intersect' for multiple input vectors or lists
#'
#' @description  Function to check the intersect within multiple vectors or lists.
#'
#' @param        ... vectors to check for intersect or lists.
#'
#' @return       Returns the intersect of all given inputs.
#' @export
#'
#' @seealso I found this function on this post
#' \href{https://stat.ethz.ch/pipermail/r-help/2006-July/109758.html}{here}
#' and adjusted it a bit.
#'
#' @examples
#' intersect2(list(c(1:3), c(1:4)), list(c(1:2),c(1:3)), c(1:2))
#' # [1] 1 2
#'
#' @author Jakob Gepp
#'
intersect_multiple <- function(...) {
    args  <- list(...)
    nargs <- length(args)

    if (nargs <= 1) {
      if (nargs == 1 && is.list(args[[1]])) {
        do.call("intersect_multiple", args[[1]])
      } else {
        args[[1]]
      }
    } else if (nargs == 2) {
      # check type of list elements
      if (length(unique(sapply(args, typeof))) != 1) {
        warning("different input types will be converted")
      }
      intersect(intersect_multiple(args[[1]]), intersect_multiple(args[[2]]))
    } else {
      intersect(intersect_multiple(args[[1]]), intersect_multiple(args[-1]))
    }
}



#' Create columns if not exist
#'
#' @param data  data structure
#' @param cname Character vector of names to create
#'
#' @return      new data structure
#' @export
#'
fncols <- function(data, cname) {
    add <-cname[!cname%in%names(data)]

    if(length(add)!=0) data[add] <- NA
    data
}

