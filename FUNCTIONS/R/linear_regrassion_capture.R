
#### Function to capture some variables of an lm model in R.


#' @param lm An \code{lm()} object.
#'
#' @title
#' Capture coefficients and statistics of a simple linear regression model.
#'
#' @description
#' The function captures some data as an data frame.
#'
#' @return
#' A data frame
#'
#' @export
#'
linear_regression_capture <- function(lm) {
    aa         <- summary(lm)

    data.frame(
        intercept    = lm$coefficients[1]   ,
        slope        = lm$coefficients[2]   ,
        slope.sd     = aa$coefficients[2,2] ,
        slope.t      = aa$coefficients[2,3] ,
        slope.p      = aa$coefficients[2,4] ,
        intercept.sd = aa$coefficients[1,2] ,
        intercept.t  = aa$coefficients[1,3] ,
        intercept.p  = aa$coefficients[1,4] ,
        Rsqrd        = aa$r.squared         ,
        RsqrdAdj     = aa$adj.r.squared
    )
}
