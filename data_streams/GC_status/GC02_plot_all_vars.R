# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "GC `r strftime(Sys.time(), '%F %R %Z', tz= 'Europe/Athens')`"
#' author: ""
#' output:
#'   html_document:
#'     toc:             true
#'     number_sections: false
#'     fig_width:       7
#'     fig_height:      4
#'     keep_md:         no
#' date: ""
#' ---

#+ echo=F, include=F

#### Golden Cheetah read activities summary directly from rideDB.json

## - Applies some filters
## - Creates some new variables
## - Stores parsed data
## - Plots almost all variables

####_ Set environment _####
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/data_streams/GC_status/GC02_plot_all_vars.R"
export.file <- paste0("~/Formal/REPORTS/", sub(".R", ".html", basename(Script.Name)))

require(data.table, quietly = TRUE, warn.conflicts = FALSE)
require(lubridate,  quietly = TRUE, warn.conflicts = FALSE)
require(plyr,       quietly = TRUE, warn.conflicts = FALSE)
require(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
require(ggplot2,    quietly = TRUE, warn.conflicts = FALSE)
require(plotly,     quietly = TRUE, warn.conflicts = FALSE)
require(DT,         quietly = TRUE, warn.conflicts = FALSE)
require(htmltools,  quietly = TRUE, warn.conflicts = FALSE)
library(slider)

source("~/CODE/data_streams/GC_status/GC00_DEFINITIONS.R")

source("~/CODE/FUNCTIONS/R/data.R")


## choose loess criterion for span
LOESS_CRITERIO <-  c("aicc", "gcv")[1]

DEBUG     <- FALSE
# DEBUG     <- TRUE

if (DEBUG) {
  warning("Debug is active!!")
}

if (!file.exists(storagefl)) { stop("Have to parse GC data first") }

if (
  DEBUG ||
  interactive() ||
  !file.exists(storagefl) ||
  file.mtime(storagefl) < file.mtime(export.file)
) {
  cat(paste("\n\n",  basename(Script.Name), "have to run!\n\n"))
} else {
  stop(paste("\n\n", basename(Script.Name), "Don't have to run!\n\n"))
}


#+ include=FALSE, echo=FALSE
## init use of ggplot and html tables in loops
tagList(datatable(cars))
tagList(ggplotly(ggplot()))


##  LOAD DATA  ------------------------------------------------------------
DT <- data.table(readRDS(storagefl))
DT <- janitor::remove_empty(DT, "cols")

## __ Don't plot some metrics  ---------------------------------------------
PP <- DT |> select(
  -matches("^[0-9]s"),
  -matches("^[0-9]m"),
  -matches("^[0-9][0-9]s"),
  -matches("^[0-9][0-9]m"),
  -matches("^[0-9][0-9][0-9]m"),
  -matches("_V1$"),
  -matches("_V2$"),
  -matches("Best_[0-9][0-9]m"),
  -matches("Best_[0-9][0-9][0-9]m"),
  )
PP |> colnames()


## _ Plot some data specific ---------
#'
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis", warning=F

ggplot(PP |> filter(!is.na(EPOC)),
       aes(
         x      = EPOC,
         y      = Trimp_Points,
         colour = Workout_Code,
         alpha  = Date)) +
  geom_point() +
  labs(
    x = "EPOC",
    y = "TRIMP"
  ) +
  theme_bw()

ggplot(PP |> filter(!is.na(EPOC)),
       aes(
         x      = EPOC,
         y      = Trimp_Zonal_Points,
         colour = Workout_Code,
         alpha  = Date)) +
  geom_point() +
  labs(
    x = "EPOC",
    y = "TRIMP Zonal"
  ) +
  theme_bw()

ggplot(PP |> filter(!is.na(Trimp_Points)),
       aes(
         x      = Trimp_Points,
         y      = Trimp_Zonal_Points,
         colour = Workout_Code,
         alpha  = Date)) +
  geom_point() +
  labs(
    x = "TRIMP",
    y = "TRIMP Zonal"
  ) +
  theme_bw()

ggplot(PP |> filter(!is.na(Trimp_Points)),
       aes(
         x      = Trimp_Points,
         y      = Trimp_Zonal_Points,
         colour = Workout_Code,
         alpha  = Date)) +
  geom_point() +
  labs(
    x = "TRIMP",
    y = "TRIMP Zonal"
  ) +
  theme_bw()

ggplot(PP |> filter(!is.na(Trimp_Points)),
       aes(
         x      = Total_Kcalories,
         y      = Trimp_Points,
         colour = Workout_Code,
         alpha  = Date)) +
  geom_point() +
  labs(
    x = "Total calories",
    y = "TRIMP"
  ) +
  theme_bw()

ggplot(PP |> filter(!is.na(Trimp_Zonal_Points)),
       aes(
         x      = Total_Kcalories,
         y      = Trimp_Zonal_Points,
         colour = Workout_Code,
         alpha  = Date)) +
  geom_point() +
  labs(
    x = "Total calories",
    y = "TRIMP zonal"
  ) +
  theme_bw()


ggplot(PP |> filter(!is.na(EPOC)),
       aes(
         x      = Total_Kcalories,
         y      = EPOC,
         colour = Workout_Code,
         alpha  = Date)) +
  geom_point() +
  labs(
    x = "Total calories",
    y = "EPOC"
  ) +
  theme_bw()

ggplot(PP |> filter(!is.na(EPOC)),
       aes(
         x      = Workout_Time,
         y      = Trimp_Points / EPOC,
         colour = Workout_Code,
         alpha  = Date)) +
  geom_point() +
  labs(
    x = "Workout Time",
    y = "Trimp_Points / EPOC"
  ) +
  theme_bw()



## __ Plot all variables ---------------------------------------------------
wecare <- PP |>
  select(
    where(is.numeric) &
    where(~ sum(!is.na(.)) > DATA_PLOT_LIMIT)
  ) |>
  select(
    -matches(
      "date|filename|parsed|Col|Pch|sport|bike|shoes|CP_setting|workout_code|Year|Duration|Time_Moving|Dropout_Time|Distance_Swim|Heartbeats",
      ignore.case = TRUE)
  ) |>
  colnames() |>
  sort()


for (avar in wecare) {

  df <- DT %>%
    filter(!is.na(.data[[avar]])) |>
    arrange(Date) %>%
    mutate(
      value = .data[[avar]],
      rm    = slide_dbl(value,
                        ~ mean(.x, na.rm = TRUE),
                        .before = 29,
                        .complete = FALSE),
      year  = year(Date),
      month = month(Date)
    )

  # ---- yearly regression segments ----
  seg_df <- df %>%
    filter(!is.na(value)) %>%
    group_by(year, month) %>%
    filter(n() > 1) %>%
    group_modify(~ {
      mlm <- lm(value ~ Date, data = .x)

      Dstart <- as.POSIXct(sprintf("%s-%s-01", .y$year, .y$month))
      Dend   <- Dstart %m+% months(1)

      pred <- predict(mlm,
                      newdata = data.frame(Date = c(Dstart, Dend)))

      tibble(
        x = Dstart,
        xend = Dend,
        y = pred[1],
        yend = pred[2]
      )
    }) %>%
    ungroup()

  month_lines <- unique(floor_date(df$Date, "month"))


  p <- ggplot(df, aes(Date, value)) +

    geom_point(aes(color = Workout_Code)) +
    scale_shape_manual(values = c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)) +

    geom_line(aes(y = rm),
              color = "green",
              linewidth = 0.8,
              na.rm = TRUE) +

    geom_segment(data = seg_df,
                 aes(x = x, xend = xend,
                     y = y, yend = yend),
                 inherit.aes = FALSE,
                 color = "cyan")  +

    geom_smooth(method = "loess",
                formula = y ~ x,
                se = FALSE,
                color = "magenta",
                linewidth = 1,
                na.rm = TRUE)  +

    labs(title = avar, x = NULL, y = NULL) +

    theme_bw()

  print(p)
}


####_ END _####
tac <- Sys.time()
cat(sprintf("\n\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
