
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
rm.cols.DT <- function(DT, pattern, quiet = FALSE ) {
    if (quiet == FALSE) {
        message(paste("\nRemoving columns:", grep(pattern ,names(DT), value = T)))
    }
    suppressWarnings(
        DT[ , (grep(pattern, names(DT))) := NULL]
    )
}



#' Remove columns filled with identical elements from data.table
#'
#' @param DT A data.table
#'
#' @return   A new data.table with removed the duplicate filled columns
#' @export
#'
rm.cols.dups.DT <- function(DT) {
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
rm.cols.NA.DT <- function(DT) {
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



#' Remove columns filled only with NA from data.frame
#'
#' @param DF A data.table
#'
#' @return   A new data.frame without NA filled columns
#' @export
#'
rm.cols.NA.df <- function(DF) {
    if (nrow(DF) > 1) {
        dtnames <- names(DF)
        suppressWarnings({
            vec <- vapply(DF, function(x) ! all(is.na(x)), logical(1L) )
            cat(paste("Removed columns:", length(dtnames[!vec]),"\n"))
            print( dtnames[!vec] )
            return( DF[ , vec ] )
        })
    } else {
        return(DF)
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



#' Finds consecutive instances of the same number.
#'
#' @param avector A vector to search for consecutive values
#' @param limit Consecutive values threshold to be included in the output
#'
#' @return A list of vectors:
#'     lengths: how many consecutive values were found
#'     values:  the consecutive value found
#'     starts:  the starting index of each of the consecutive set
#'     ends:    the ending index of each of the consecutive set
#' @export
#' @family data manipulation functions
#'
find_freezed_measurements <- function(avector, limit) {
    ## count repetitions
    runs = rle(avector)
    if (length( runs$lengths ) <= 0) print("Can not count repetitions")

    ## find repetitions by limit
    myruns = which( runs$lengths >= limit )
    if (length(myruns) <= 0) print("No consecutive values found")

    ## find indexes of ends of repetitions
    runs.lengths.cumsum = cumsum(runs$lengths)
    ends = runs.lengths.cumsum[myruns]

    ## find indexes of start of repetitions
    newindex = ifelse(myruns > 1, myruns - 1, 0)
    starts = runs.lengths.cumsum[newindex] + 1
    if (0 %in% newindex) starts = c(1, starts)

    ## results
    return(
        list( lengths = runs$lengths,
              values  = runs$values,
              starts  = starts,
              ends    = ends)
    )
}



#' Find nearest numbers between vectors.
#'
#' @description Return an array `i` of indexes into `target`, parallel to array `probe`.
#'              For each index `j` in `target`, `probe[i[j]]` is nearest to `target[j]`.
#'              From: https://stats.stackexchange.com/questions/161379/quickly-finding-nearest-time-observation
#'
#' @param probe  A vector
#' @param target A vector
#'
#' @return Indexes of `target` matching `probe` data.
#' @export
#' @family data manipulation functions
#'
#' @examples
#' ## Graphical illustration.
#' set.seed(17)
#' x <- sort(round(runif(8), 3))
#' y <- sort(round(runif(12), 1))
#' i <- nearest(x, y)
#' plot(c(0,1), c(3/4,9/4), type="n", bty="n", yaxt="n", xlab="Values", ylab="")
#' abline(v = (y[-1] + y[-length(y)])/2, col="Gray", lty=3)
#' invisible(apply(rbind(x, y[i]), 2, function(a) arrows(a[1], 1, a[2], 2, length=0.15)))
#' points(x, rep(1, length(x)), pch=21, bg="Blue")
#' points(y, rep(2, length(y)), pch=21, bg="Red", cex=sqrt(table(y)[as.character(y)]))
#' text(c(1,1), c(1,2), c("x","y"), pos=4)
#'
nearest <- function(probe, target, ends=c(-Inf,Inf)) {
    # Both `probe` and `target` must be vectors of numbers in ascending order.
    if ( is.unsorted(probe ) ) { stop("Probe is not sorted") }
    if ( is.unsorted(target) ) { stop("Target is not sorted") }

    glb <- function(u, v) {
        n <- length(v)
        z <- c(v, u)
        j <- i <- order(z)
        j[j > n] <- -1
        k <- cummax(j)
        return(k[i > n])
    }
    y <- c(ends[1], target, ends[2])

    i.lower <- glb(probe, y)
    i.upper <- length(y) + 1 - rev(glb(rev(-probe), rev(-y)))
    y.lower <- y[i.lower]
    y.upper <- y[i.upper]
    lower.nearest <- probe - y.lower < y.upper - probe
    i <- ifelse(lower.nearest, i.lower, i.upper) - 1
    i[i < 1 | i > length(target)] <- NA
    return(i)
}






