
#### Function to capture some variables of an lm model in R.


#' @param lm An \code{lm()} object.
#'
#' @param confidence_interval Compute interval for this level of confidence.
#'  The level 0.95 is always computed
#'
#' @title
#' Capture coefficients and statistics of a simple linear regression model.
#'
#' @description
#' The function captures some data as a data frame, and calculate the
#' margin of error of the coefficient for different level of confidence.
#'
#' It is only tested for simple linear fit with one dependent variable.
#'
#' @return
#' A data frame with statistics for the slope.\* the intercept.\* and the fit model.
#'
#' @export
#'
linear_fit_stats <- function(lm, confidence_interval) {

    ## compute confidence intervals
    default_confint   <- 0.95
    standard          <- data.frame(confint(lm, level = default_confint))
    standard$interval <- ( standard[,2] - standard[,1] ) / 2
    tt                <- data.frame(t(standard$interval))
    names(tt)         <- paste0(c("intercept","slope"),
                                  ".ConfInt_",
                                  default_confint)

    if (!missing(confidence_interval)) {
        extra_confint  <- confidence_interval
        extra          <- data.frame(confint(lm, level = extra_confint))
        extra$interval <- ( extra[,2] - extra[,1] ) / 2
        ss             <- data.frame(t(extra$interval))
        names(ss)      <- paste0(c("intercept","slope"),
                                 ".ConfInt_",
                                 extra_confint)
        tt <- cbind(tt,ss)
    }

    ## get more statistics
    aa         <- summary(lm)

    ## export this
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
        RsqrdAdj     = aa$adj.r.squared,
        tt
    )
}








