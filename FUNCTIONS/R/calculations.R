
#### Functions to calculate specific quantities.


#' Get the last Sunday of a year
#'
#' @param year The year numeric or string
#'
#' @return     A vector with as.Date dates of the last Sunday of each month of the year
#' @export
#'
last_sundays <- function(year) {
    mm <- c()
    for (month in 1:12) {
        if (month == 12) {
            date <- as.Date(paste0(year,"-",12,"-",31))
        } else {
            date <- as.Date(paste0(year,"-",month+1,"-",1))-1
        }
        while (weekdays(date, abbreviate = F) != "Sunday") {
            date <- date - 1
        }
        mm <- c(mm, date)
        # print(date)
    }
    return(mm)
}



#' Age in decimal years
#'
#' @param Birthday  Date of birth
#' @param Now       Date in which we want the age.
#'
#' @return          Years of age.
#' @export
#'
Age_y <- function(Birthday = as.Date("1982-07-27"),
                  Now      = Sys.time() ){
    as.numeric( difftime( Now, Birthday, unit="days"))/365.25
}




#' Calculate the consumption of energy during an activity
#'
#' @param HR_avg     Heart rate average for the activity
#' @param Weigh_KG   Body weight in kg
#' @param Time_mins  Activity duration in minutes
#' @param Now        Date of the activity
#' @param Birthday   Birthday of the athlete
#' @param Male       Gender of the athlete
#'
#' @return           KCals consumed during the activity
#' @export
#'
Calories <- function( HR_avg, Weigh_KG, Time_mins,
                      Now      = Sys.time(),
                      Birthday = as.Date("1982-07-27"),
                      Male     = TRUE ) {

    Age <- Age_y( Birthday = Birthday,
                  Now      = Now)

    ## MEN
    if (Male) {
        cals <- ( ( -55.0969 + ( 0.6309 * HR_avg ) + ( 0.1988 * Weigh_KG ) + ( 0.2017 * Age ) ) / 4.184 ) * Time_mins
    }

    ## WOMEN
    if (!Male) {
        cals <- ( ( -22.4022 + ( 0.4472 * HR_avg ) - ( 0.1263 * Weigh_KG ) + ( 0.074 * Age ) ) / 4.184 ) * Time_mins
    }
    if (!is.na(cals) & cals < 0) cals <- 0
    return(cals)
}
