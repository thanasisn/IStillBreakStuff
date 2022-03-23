# /* Copyright (C) 2018 Athanasios Natsis <natsisthanasis@gmail.com> */


####    Relative Optical Mass or Air Mass Factor    ####

#' Relative Optical Mass or Air Mass Factor
#'
#' @param height   The height is the mean ozone layer height above mean sea level.
#' the altitude of the observing station.
#' @param sza      The sza of the sun.
#' @param earth_R  Earth's radius (km).
#'
#' @return         Relative Optical Mass or Air Mass Factor
#' @export
#' @note   https://www.esrl.noaa.gov/gmd/ozwv/dobson/papers/report13/12th.html
#'         WORLD METEOROLOGICAL ORGANIZATION
#'         WMO GLOBAL OZONE RESEARCH AND MONITORING PROJECT
#'         REPORT No. 13
#'         REVIEW OF THE DOBSON SPECTROPHOTOMETER AND ITS ACCURACY
#'
amf <- function(sza, altitude = 0, height = 22, earth_R = 6370 ) {
    require(pracma)
    sec(asin( ( earth_R + altitude ) / ( earth_R + height ) * sind(sza) ))
}



####    Relative optical mass of atmosphere for Rayleigh scattering    ####

#' Relative optical mass of atmosphere for Rayleigh scattering
#'
#' @param sza  The sza of the sun.
#'
#' @return     relative optical mass
#' @export
#'
amR <- function(sza) {
    require(pracma)

    mx = 0.99656 * sind(sza)
    1 /
    ( cosd( atand ( mx / ((1-mx^2)^0.5)) ))
}




####    Relative humidity calculation    ####

#' Relative humidity from temperature and dew point temperature
#'
#' @param Temp      Atmospheric temperature in Kelvin
#' @param Temp_dew  Dew point temperature in Kelvin
#'
#' @return          Relative humidity in percentage
#' @export
#'
RelHum <- function(Temp, Temp_dew) {
    # RH = 100 * es(Td)/es(T)

    a_1 = 611.21   # Pa
    a_3 = 17.502
    a_4 = 32.19    # K
    T_0 = 273.16   # K

    100 * exp( a_3 * ( (Temp_dew - T_0)/(Temp_dew - a_4) - (Temp - T_0)/(Temp - a_4) )  )

}



