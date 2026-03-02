
require(httr,     quietly = TRUE)
require(jsonlite, quietly = TRUE)

#' Get reverse geocode of lat, lon coordinates
#'
#' @param lat  Latitude
#' @param lon  Longigude
#'
#' @returns
#' @export
#'
reverse_geocode_osm <- function(lat, lon) {
  tryCatch({
    # Nominatim API endpoint
    url <- "https://nominatim.openstreetmap.org/reverse"

    # Make request with polite parameters
    response <- GET(
      url,
      query = list(
        lat            = lat,
        lon            = lon,
        format         = "json",
        zoom           = 18,  # Street level detail
        addressdetails = 1
      ),
      add_headers(`User-Agent` = "R_GPX_Analysis/1.0")
    )

    # Check if request was successful
    if (status_code(response) == 200) {
      content <- fromJSON(rawToChar(response$content), flatten = TRUE)

      # Extract address components
      if (!is.null(content$address)) {
        address <- content$address

        result <- list(
          full_address = content$display_name,

          number   = ifelse(!is.null(address$house_number), address$house_number, NA),
          road     = ifelse(!is.null(address$road        ), address$road,         NA),
          city     = ifelse(!is.null(address$city        ), address$city,
                            ifelse(!is.null(address$town ), address$town,
                                   ifelse(!is.null(address$village), address$village, NA))),
          state    = ifelse(!is.null(address$state             ), address$state,      NA),
          country  = ifelse(!is.null(address$country           ), address$country,    NA),
          postcode = ifelse(!is.null(address$postcode          ), address$postcode,   NA),
          neighbourhood = ifelse(!is.null(address$neighbourhood), address$neighbourhood,
                                 ifelse(!is.null(address$suburb), address$suburb,     NA)),
          lat    = lat,
          lon    = lon,
          source = "OpenStreetMap"
        )
        return(result)
      }
    }
    return(NULL)
  }, error = function(e) {
    message("Reverse geocoding error: ", e$message)
    return(NULL)
  })
}

