# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "My weather `r strftime(Sys.time(), '%F %R %Z', tz= 'Europe/Athens')`"
#' author: ""
#' output:
#'   html_document:
#'     toc:             true
#'     number_sections: false
#'     fig_width:       6
#'     fig_height:      4
#'     keep_md:         no
#' date: ""
#' ---

#+ echo=F, include=F
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/data_streams/weather/W01_location_forecast.R"
export.file <- "~/Formal/REPORTS/W01_location_forecast.html"

if (interactive() ||
    !file.exists(export.file) ||
    file.mtime(export.file) <= (Sys.time() - 0.5 * 3600)) {
  print("Have to run")
} else {
  stop(paste0("\n\n", basename(Script.Name), "\nDon't have to run yet!\n\n"))
}

##  Set environment  -----------------------------------------------------------
require(data.table, quietly = TRUE, warn.conflicts = FALSE)
require(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
require(ggplot2,    quietly = TRUE, warn.conflicts = FALSE)
require(htmltools,  quietly = TRUE, warn.conflicts = FALSE)
require(janitor,    quietly = TRUE, warn.conflicts = FALSE)
require(DT,         quietly = TRUE, warn.conflicts = FALSE)
require(lubridate,  quietly = TRUE, warn.conflicts = FALSE)
require(plotly,     quietly = TRUE, warn.conflicts = FALSE)
require(purrr,      quietly = TRUE, warn.conflicts = FALSE)
require(reticulate, quietly = TRUE, warn.conflicts = FALSE)
require(tidyr,      quietly = TRUE, warn.conflicts = FALSE)

source("~/CODE/data_streams/DEFINITIONS.R")
source("~/CODE/data_streams/helpers/fn_get_gpx_last_location.R")
source("~/CODE/data_streams/helpers/fn_reverse_geocode_osm.R")


if (file.exists(pyenv_python)) {
  use_python(pyenv_python, required = TRUE)
} else {
  stop("pyenv Python not found")
}

source_python("~/CODE/data_streams/helpers/fn_get_open_meteo_forecasts.py")

#+ include=FALSE, echo=FALSE
## init use of ggplot and html tables in loops
tagList(datatable(cars))
tagList(ggplotly(ggplot()))

##  Get data  ------------------------------------------------------------------
filelist <- list.files(path        = gpx_dir,
                       pattern     = "*.gpx",
                       full.names  = TRUE,
                       ignore.case = TRUE)

DT <- data.table(File = filelist,
                 mtime = file.mtime(filelist))

DT[, Date := ymd(sub("\\..*", "", sub("^.*_", "", basename(File))))]

setorder(DT, mtime)

## select last updated file
File <- DT[mtime == max(mtime), File ]

# select last date file
File <- DT[Date == max(Date), File ]

# get location
myloc    <- get_gpx_last_location(File, last_minutes = last_gpx_mins, min_points = last_gpx_points)

# get address
myadd   <- reverse_geocode_osm(lat = myloc$median_lat, lon =  myloc$median_lon)
address <- paste(myadd$road, myadd$number, sub("Δημοτική Ενότητα |Δήμος ", "", myadd$city))
gpx_old <- difftime(Sys.time(), myloc$median_time, units = "mins")

# get forecasts
forcasts <- get_open_meteo_forecasts(myloc$median_lat, myloc$mean_lon)


clean_weather_df <- function(df) {
  df %>%
    # Convert to tibble
    as_tibble() %>%
    # Unnest list columns
    mutate(across(where(is.list), ~{
      if (all(lengths(.) == 1)) {
        unlist(.)
      } else {
        map_chr(., paste, collapse = ", ")
      }
    })) %>%
    # Fix column types
    transmute(
      Model     = as.character(model),
      Variable  = as.character(variable),
      Value     = as.numeric(value),
      Latitude  = as.numeric(latitude),
      Longitude = as.numeric(longitude),
      Timezone  = stringr::str_remove_all(timezone, "b'|'"),
      DateLoc   = ymd_hms(date) %>% force_tz(tz = first(stringr::str_remove_all(timezone, "b'|'")))
    )
}

daily    <- forcasts$daily  %>% clean_weather_df()
hourly   <- forcasts$hourly %>% clean_weather_df()
timezone <- unique(hourly$Timezone)

## apply some data limits
hourly <- hourly |>
  filter(DateLoc >= Sys.time() - 1.5 * 24 * 3600) |>
  filter(DateLoc <= Sys.time() +  10 * 24 * 3600)

daily <- daily |>
  filter(DateLoc >= Sys.time() -  1 * 24 * 3600)

#'
#' # `r address` `r paste(round(gpx_old), "mins")`
#'
#+ echo=F, include=T, results="asis", warning=F

myadd[["timezone"]] <- timezone
addr_names <- grep("full_address|source", names(myadd), invert = TRUE, value = TRUE)
pander::pander(myadd[addr_names])


##  Function  ------------------------------------------------------------------

## get vars to plot
get_variables <- function(data,
                          exclude_patterns = c("is_day", "radiation", "irradiance")) {
  # Start with all unique variables
  vars <- unique(data$Variable)

  # Exclude each pattern
  for (pattern in exclude_patterns) {
    vars <- grep(pattern, vars, value = TRUE, invert = TRUE)
  }
  return(vars)
}

## remove similar data
remove_similar_models <- function(data, variable_name, correlation_threshold = 0.99) {

  # Pivot to wide format for correlation analysis
  wide_data <- data %>%
    filter(Variable == variable_name) %>%
    select(DateLoc, Model, Value) %>%
    pivot_wider(names_from = Model, values_from = Value)

  # Calculate correlation matrix
  model_cors <- wide_data %>%
    select(-DateLoc) %>%
    cor(use = "pairwise.complete.obs")

  # Find models to remove (keep first of each highly correlated pair)
  models_to_keep <- c()
  models_to_remove <- c()

  for (i in 1:ncol(model_cors)) {
    model_i <- colnames(model_cors)[i]
    if (!model_i %in% models_to_remove) {
      models_to_keep <- c(models_to_keep, model_i)

      # Find highly correlated models
      highly_correlated <- names(which(model_cors[i, ] > correlation_threshold))
      highly_correlated <- setdiff(highly_correlated, model_i)
      models_to_remove <- c(models_to_remove, highly_correlated)
    }
  }

  # Filter data
  data %>%
    filter(Variable == variable_name, Model %in% models_to_keep)
}

## consistent arrange of vars
arrange_variables <- function(vars) {
  # Define pattern groups in order of priority
  temp_vars   <- grep("temperature|temp", vars, value = TRUE, ignore.case = TRUE)
  precip_vars <- grep("precipitation|rain|showers", vars, value = TRUE, ignore.case = TRUE)
  wind_vars   <- grep("wind", vars, value = TRUE, ignore.case = TRUE)

  # Get the rest (excluding those already matched)
  rest_vars <- setdiff(vars, c(temp_vars, precip_vars, wind_vars))

  # Sort each group alphabetically
  temp_vars   <- sort(temp_vars)
  precip_vars <- sort(precip_vars)
  wind_vars   <- sort(wind_vars)
  rest_vars   <- sort(rest_vars)

  # Combine in desired order
  c(temp_vars, precip_vars, wind_vars, rest_vars)
}

## get the time diff from the UTC based on a timezone
offset_to_seconds <- function(ref_date, offset_str) {

  offset_str <- format(with_tz(ref_date, timezone), "%z")

  # Extract sign, hours, and minutes
  sign    <- substr(offset_str, 1, 1)
  hours   <- as.numeric(substr(offset_str, 2, 3))
  minutes <- as.numeric(substr(offset_str, 4, 5))

  # Calculate total seconds
  total_seconds <- hours * 3600 + minutes * 60

  # Apply sign
  total_seconds <- ifelse(sign == "-", -total_seconds, total_seconds)

  return(total_seconds)
}

## create a proper date for use with respect to timezone
daily <- daily |>
  mutate(DateLocO = as.Date(DateLoc + offset_to_seconds(DateLoc, Timezone), tz = timezone))


##  Plot data  -----------------------------------------------------------------

#'
#' # Best model plot
#'
#+ echo=F, include=T, results="asis", warning=F

best <- hourly %>%
  filter(grepl("best", Model, ignore.case = TRUE)) %>%
  select(-Model, -Latitude, -Longitude, -Timezone) %>%
  group_by(Variable)                               %>%
  filter(!all(as.numeric(Value) == 0))

variables <- get_variables(best) %>% arrange_variables()
for (avar in variables) {
  ## my locale for display
  Sys.setlocale("LC_TIME", "el_GR.UTF-8")

  g <- best                  %>%
    filter(Variable == avar) %>%
    filter(!is.na(Value))

  p <- ggplot(g, aes(x = DateLoc, y = Value)) +
    geom_vline(xintercept = as.numeric(Sys.time()), linewidth = 0.7, linetype = "dashed", color = "green") +
    geom_line(color = "blue", linewidth = 0.7) +
    xlab("") +
    ylab("") +
    labs(title = paste(avar)) +
    scale_x_datetime(
      date_breaks = "1 day",
      date_labels = "%a\n%d/%m",
    ) +
    theme_bw()

  p <- ggplotly(p)

  if (isTRUE(getOption('knitr.in.progress'))) {
    # In R Markdown, wrap in htmltools::tagList for plotly
    # print(htmltools::tagList(ggplotly(g)))
    print(htmltools::tagList(p))
  } else if (interactive()) {
    # In interactive mode
    print(ggplotly(p))
    # print(p)
  } else {
    # For static plots
    print(p)
  }
}


#'
#' # All model plot
#'
#+ echo=F, include=T, results="asis", warning=F

variables <- get_variables(hourly) %>% arrange_variables()
for (avar in variables) {
  Sys.setlocale("LC_TIME", "el_GR.UTF-8")

  ## reduce to useful data only
  g <- hourly                %>%
    filter(Variable == avar) %>%
    filter(!is.na(Value))    %>%
    remove_similar_models(avar, correlation_threshold = 0.99)

  g <- g |> group_by(Model) |>
    filter(!all(as.numeric(Value) == 0))

  if (nrow(g) <= 1) { next() }

  p <- ggplot()

  if (!any(g$Model == "best_match")) {
    p <- p +
      # Other models - thinner lines
      geom_line(data = g,
                aes(x = DateLoc, y = Value, colour = Model),
                linewidth = 0.5)
  }

  else {
    p <- p +
      geom_line(data = filter(g, Model != "best_match"),
                aes(x = DateLoc, y = Value, colour = Model),
                linewidth = 0.5)
      # Best match - thicker line on top
      geom_line(data = filter(g, Model == "best_match"),
                aes(x = Date, y = Value, colour = Model),
                linewidth = 1.5)
  }

  p <- p  +
    geom_vline(xintercept = as.numeric(Sys.time()),              linetype = "dashed", color = "green") +
    xlab("") +
    ylab("") +
    labs(title = paste(avar)) +
    scale_x_datetime(
      date_breaks = "1 day",
      date_labels = "%a\n%d/%m",
    ) +
    theme_bw()

  # p <- ggplotly(p)
  p <- ggplotly(p) %>%
    layout(legend = list(
      orientation = "h",
      x = 0,
      y = -0.8)
    )

  if (isTRUE(getOption('knitr.in.progress'))) {
    # In R Markdown, wrap in htmltools::tagList for plotly
    print(htmltools::tagList(p))
  } else if (interactive()) {
    # In interactive mode
    print(ggplotly(p))
    # print(p)
  } else {
    # For static plots
    print(p)
  }
}


#'
#' # Daily table
#'
#+ echo=F, include=T, results="asis", warning=F


pp <- daily |>
  select(-Latitude, -Longitude, -Timezone, -DateLoc) |>
  mutate(Value = round(Value, 2)) |>
  pivot_wider(
    id_cols     = c(Model, DateLocO),
    names_from  = Variable,
    values_from = Value
  )

as.POSIXlt(pp$DateLoc)
strftime(as.POSIXlt(pp$DateLoc), "%z")

print(
  htmltools::tagList(
    datatable(pp,
              rownames = FALSE,
              options  = list(pageLength = 500),
              style    = "bootstrap",
              class    = "table-bordered table-condensed")
  )
)



#+ include=T, echo=F, results="asis"
tac <- Sys.time()
cat(sprintf("**END** %s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
