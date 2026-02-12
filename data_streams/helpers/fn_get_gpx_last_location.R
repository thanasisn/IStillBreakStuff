
require(sf,        quietly = TRUE)
require(lubridate, quietly = TRUE)
require(dplyr,     quietly = TRUE)

#' Get a robust last location from a gpx file
#'
#' @param gpx_file     Path of a gpx file
#' @param last_minutes Include last n minutes in the calculations
#' @param min_points   Include last n points in the calculations
#'
#' @returns            A sf object with statistical difined lat, lon, elevation
#' @export
#'
get_gpx_last_location <- function(gpx_file, last_minutes, min_points = 5) {
  # Read GPX file
  gpx <- sf::st_read(gpx_file, layer = "track_points", quiet = TRUE)

  # Extract time and coordinates
  gpx <- gpx %>%
    mutate(
      time      = ymd_hms(time),  # Convert to datetime
      lat       = st_coordinates(.)[, "Y"],
      lon       = st_coordinates(.)[, "X"],
      elevation = as.numeric(ele)
    ) %>%
    select(time, lat, lon, elevation)

  # Get current time (or most recent time in data)
  current_time <- max(gpx$time, na.rm = TRUE)

  # Filter for last 10 minutes
  ten_min_ago  <- current_time - minutes(last_minutes)
  last_minutes <- gpx %>%
    filter(time >= ten_min_ago)

  # get last points regardless of time
  last_by_count <- gpx %>%
    arrange(desc(time)) %>%
    slice_head(n = min_points)

  last_points <- bind_rows(last_minutes, last_by_count) %>%
    distinct() %>%
    arrange(time)

  # Calculate mean location
  mean_location <- last_points %>%
    summarise(
      mean_lat        = mean(  lat, na.rm = TRUE),
      mean_lon        = mean(  lon, na.rm = TRUE),
      median_lat      = median(lat, na.rm = TRUE),
      median_lon      = median(lon, na.rm = TRUE),
      start_time      = min(   time, na.rm = TRUE),
      end_time        = max(   time, na.rm = TRUE),
      mean_time       = mean(  time, na.rm = TRUE),
      median_time     = median(time, na.rm = TRUE),
      mean_altitude   = mean(  elevation, na.rm = TRUE),
      median_altitude = median(elevation, na.rm = TRUE),
      min_altitude    = min(   elevation, na.rm = TRUE),
      max_altitude    = max(   elevation, na.rm = TRUE),
      n_points        = n()
    )

  return(mean_location)
}
