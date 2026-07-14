# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "Training Models `r strftime(Sys.time(), '%F %R %Z', tz= 'Europe/Athens')`"
#' author: ""
#' output:
#'   html_document:
#'     toc:              true
#'     number_sections:  false
#'     fig_width:        7
#'     fig_height:       4
#'     keep_md:          no
#' date: ""
#' ---

#+ echo=F, include=F

#### Human Performance plots and data for GC data for different uses

# Data from main json
# Normal plots
# Unified plots
# Mobile phone plot
# Conky desktop plot

####_ Set environment _####
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/data_streams/GC_status/GC04_more_plots_rides_db.R"
export.file <- paste0("~/Formal/REPORTS/", sub(".R", ".html", basename(Script.Name)))

require(caTools,    quietly = TRUE, warn.conflicts = FALSE)
require(data.table, quietly = TRUE, warn.conflicts = FALSE)
require(dplyr,      quietly = TRUE, warn.conflicts = FALSE)
require(ggplot2,    quietly = TRUE, warn.conflicts = FALSE)
require(htmltools,  quietly = TRUE, warn.conflicts = FALSE)
require(lubridate,  quietly = TRUE, warn.conflicts = FALSE)
require(pander,     quietly = TRUE, warn.conflicts = FALSE)
require(plotly,     quietly = TRUE, warn.conflicts = FALSE)
require(plyr,       quietly = TRUE, warn.conflicts = FALSE)
require(tidyr,      quietly = TRUE, warn.conflicts = FALSE)

source("~/CODE/FUNCTIONS/R/data.R")
source("~/CODE/data_streams/GC_status/GC00_DEFINITIONS.R")

unifiedpdf   <- paste0("~/LOGs/training_status/", basename(sub("\\.R$","", Script.Name)), "_unified.pdf")
loadtables   <- "~/LOGs/training_status/Load_tables.md"
lastactivit  <- "~/LOGs/training_status/Last_Activities.md"

DEBUG <- FALSE

plot_show <- function(plot) {
  if (knitr::is_latex_output()) {
    print(plot)
  } else if (interactive()) {
    ggplotly(plot)
  } else if (knitr::is_html_output()) {
    htmltools::tagList(ggplotly(plot)) %>% print()
  } else {
    print(plot)
  }
}

#+ include=FALSE, echo=FALSE
## init use of ggplot and html tables in loops
# tagList(datatable(cars))
tagList(ggplotly(ggplot()))


#### Load last data to plot ----------------------------------------------------
metrics <- readRDS(storagefl)
metrics <- metrics[as.Date(Date) > Sys.Date() - daysback, ]
metrics <- metrics[Sport %in% c("Run", "Bike")]

epoc_extra <- fread("~/CODE/training_analysis/epoc.next", col.names = "value")


#### Models parameters  ------------------------------------------------------
fATL1 <- 1 / 7             ## Short term days variable
fATL2 <- 1 - exp(-fATL1)
fCTL1 <- 1 / 42            ## Long term days variable
fCTL2 <- 1 - exp(-fCTL1)

#### Define models  ----------------------------------------------------------

# fitness = 0;
# for(i=0, i < count(TRIMP); i++) {
#     fitness = fitness * exp(-1/r1) + TRIMP[i];
#     fatigue = fatigue * exp(-1/r2) + TRIMP[i];
#     performance = fitness * k1 - fatigue * k2;
# }
# k1=1.0, k2=1.8-2.0, r1=49-50, r2=11.
banister <- function(fitness, fatigue, trimp, k1 = 1.0, k2 = 1.8, r1 = 49, r2 = 11) {
  fitness     <- fitness * exp(-1 / r1) + trimp
  fatigue     <- fatigue * exp(-1 / r2) + trimp
  performance <- fitness * k1 - fatigue * k2

  list(fitness     = fitness,
       fatigue     = fatigue,
       performance = performance)
}

busso <- function(fitness, fatigue, trimp, par2 , k1 = 0.031, k3 = 0.000035, r1 = 30.8, r2 = 16.8, r3 = 2.3) {
  fitness     <- fitness * exp(-1 / r1) + trimp
  fatigue     <- fatigue * exp(-1 / r2) + trimp
  par2        <- fatigue * exp(-1 / r3) + par2
  k2          <- k3      * par2
  performance <- fitness * k1 - fatigue * k2

  list(fitness     = fitness,
       fatigue     = fatigue,
       performance = performance,
       par2        = par2)
}



## select metrics for pdf
wecare <- c("Trimp_Points", "Trimp_Zonal_Points", "EPOC", "Load_2", "TrimpModWeighed")
shortn <- c(          "TP",                 "TZ",   "EP",     "L2",              "TW")
extend <- 30
pdays  <- c(100, 450, daysback)


if (interactive()) pdays <- c(100)

### compute metrics for all models  ------------------------------------------
gather <- data.table()
for (ii in 1:length(wecare)) {
  avar <- wecare[ii]
  snam <- shortn[ii]

  ## get each variable
  pp   <- data.table(time            = metrics$Date,
                     value           = metrics[[avar]],
                     VO2max_Detected = metrics$VO2max_Detected,
                     Pch             = round(median(metrics$Pch)))
  pp   <- pp[, .(value           = sum(value, na.rm = TRUE),
                 VO2max_Detected = mean(VO2max_Detected, na.rm = TRUE)),
             by = .(Date = as.Date(time))]
  last <- pp[ Date == max(Date), ]
  pp   <- merge(
    data.table(Date = seq.Date(from = min(pp$Date),
                               to   = max(pp$Date) + extend,
                               by   = "day")),
    pp, all = T)
  pp[is.na(value), value := 0]

  ## test future program
  if (avar == "EPOC") {
    epoc_extra$Date <- Sys.Date()
    epoc_extra$Date <- epoc_extra$Date + 1:nrow(epoc_extra)
    ## assuming everything is sorted witout gaps
    pp[ Date %in% epoc_extra$Date, value := epoc_extra$value ]
  }

  names(pp)[names(pp) == "value"]  <- paste0(snam,".","VAL")

  pp[[paste0(snam,".","PMC_FAT")]] <- pp[[paste0(snam,".","VAL")]][1]
  pp[[paste0(snam,".","PMC_FIT")]] <- pp[[paste0(snam,".","VAL")]][1]
  pp[[paste0(snam,".","PMC_PER")]] <- 0

  pp[[paste0(snam,".","BAN_FAT")]] <- 0
  pp[[paste0(snam,".","BAN_FIT")]] <- 0
  pp[[paste0(snam,".","BAN_PER")]] <- 0

  pp[[paste0(snam,".","BUS_FAT")]] <- 0
  pp[[paste0(snam,".","BUS_FIT")]] <- 0
  pp[[paste0(snam,".","BUS_PER")]] <- 0
  pp[[paste0(snam,".","BUS_pr2")]] <- 1

  for (nr in 2:nrow(pp)) {
    ## calculate impulse
    pp[[paste0(snam,".","PMC_FAT")]][nr] <-
      fATL1 * pp[[paste0(snam,".","VAL")]][nr] + (1 - fATL1) * pp[[paste0(snam,".","PMC_FAT")]][nr - 1]
    pp[[paste0(snam,".","PMC_FIT")]][nr] <-
      fCTL1 * pp[[paste0(snam,".","VAL")]][nr] + (1 - fCTL1) * pp[[paste0(snam,".","PMC_FIT")]][nr - 1]
    ## calculate banister
    res <- banister(fitness = pp[[paste0(snam,".","BAN_FIT")]][nr-1],
                    fatigue = pp[[paste0(snam,".","BAN_FAT")]][nr-1],
                    trimp   = pp[[paste0(snam,".","VAL")]][nr] )
    pp[[paste0(snam,".","BAN_FAT")]][nr] <- res$fatigue
    pp[[paste0(snam,".","BAN_FIT")]][nr] <- res$fitness
    pp[[paste0(snam,".","BAN_PER")]][nr] <- res$performance
    ## calculate busso
    res <- busso(fitness = pp[[paste0(snam,".","BUS_FIT")]][nr-1],
                 fatigue = pp[[paste0(snam,".","BUS_FAT")]][nr-1],
                 par2    = pp[[paste0(snam,".","BUS_pr2")]][nr-1],
                 trimp   = pp[[paste0(snam,".","VAL")]][nr] )
    pp[[paste0(snam,".","BUS_FAT")]][nr] <- res$fatigue
    pp[[paste0(snam,".","BUS_FIT")]][nr] <- res$fitness
    pp[[paste0(snam,".","BUS_PER")]][nr] <- res$performance
    pp[[paste0(snam,".","BUS_pr2")]][nr] <- res$par2
  }

  pp[[paste0(snam,".","BAN_VAL")]] <- pp[[paste0(snam,".","VAL")]]
  pp[[paste0(snam,".","BUS_VAL")]] <- pp[[paste0(snam,".","VAL")]]
  pp[[paste0(snam,".","PMC_VAL")]] <- pp[[paste0(snam,".","VAL")]]
  pp[[paste0(snam,".","VAL")]]     <- NULL

  pp[[paste0(snam,".","BUS_pr2")]] <- NULL
  pp[[paste0(snam,".","PMC_PER")]] <- pp[[paste0(snam,".","PMC_FIT")]] -
    pp[[paste0(snam,".","PMC_FAT")]]

  if (ii == 1) {
    gather <- pp
  } else {
    gather <- merge(pp, gather, by = c("Date","VO2max_Detected") )
  }
}


#'
#' # Performance Models
#'
#+ echo=F, include=T, results="asis", warning=F

####  Normal plot of all vars and models  ------------------------------------
for (days in pdays) {

  cat(paste0("\n\n## ", days, " days\n\n"))

  ## limit graphs to last days
  pppppp <- gather[ Date >= max(Date) - days - extend, ]
  pppppp <- data.table(pppppp)
  models <- c("PMC", "BAN", "BUS")

  ####  each day bar plot of metrics  ----------------------------------------
  wwca <- c("EP.BAN_VAL", "TZ.BAN_VAL", "TP.BAN_VAL")
  ylim <- range(pppppp[ , ..wwca ], na.rm = T)


  # Reshape data for ggplot
  plot_data <- melt(pppppp,
                    id.vars = "Date",
                    measure.vars = c("EP.BAN_VAL", "TZ.BAN_VAL", "TP.BAN_VAL"),
                    variable.name = "metric",
                    value.name = "value")

  # Add time offsets for positioning
  plot_data[, plot_time := as.POSIXct(Date)]
  plot_data[metric == "TZ.BAN_VAL", plot_time := plot_time + hours(3)]
  plot_data[metric == "TP.BAN_VAL", plot_time := plot_time + hours(9)]

  # Create factor with proper labels and order
  plot_data[, metric := factor(metric,
                               levels = c("EP.BAN_VAL", "TZ.BAN_VAL", "TP.BAN_VAL"),
                               labels = c("EPOC",       "TRIMP ZN",   "TRIMP"))]

  # Create the plot
  p <- ggplot(plot_data, aes(x = plot_time, y = value, fill = metric, color = metric)) +
    # Add bars
    geom_col(width = 3600 * 2, position = position_dodge(width = 0), alpha = 0.7) +
    # Scale and theme settings
    scale_y_continuous(sec.axis = dup_axis(name = "")) +
    labs(x = "", y = "", fill = "", color = "") +
    theme_bw() +
    theme(
      legend.position = "top",
      legend.direction = "horizontal",
      legend.title = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      panel.grid.major.y = element_line(color = "grey", linetype = "dotted", linewidth = 0.2),
      panel.grid.minor.y = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.margin = margin(10, 10, 10, 10)
    ) +
    guides(fill = guide_legend(nrow = 1))
  plot_show(p)


  ####  each week metrics bar plot  ------------------------------------------
  weekly  <- pppppp[, .(EP.BAN_VAL = sum(EP.BAN_VAL, na.rm = TRUE),
                        TZ.BAN_VAL = sum(TZ.BAN_VAL, na.rm = TRUE),
                        TP.BAN_VAL = sum(TP.BAN_VAL, na.rm = TRUE)),
                    by = .(Date = floor_date(Date, unit = "week", week_start = 1) )]


  # Define the metrics
  wwca <- c("EP.BAN_VAL", "TZ.BAN_VAL", "TP.BAN_VAL")
  ylim <- range(weekly[, ..wwca], na.rm = TRUE)

  # Reshape data for ggplot
  plot_data <- melt(weekly,
                    id.vars = "Date",
                    measure.vars = c("EP.BAN_VAL", "TZ.BAN_VAL", "TP.BAN_VAL"),
                    variable.name = "metric",
                    value.name = "value")

  # Add day offsets for positioning (0, 1, 2 days offset)
  plot_data[, plot_date := Date]
  plot_data[metric == "TZ.BAN_VAL", plot_date := Date + days(1)]
  plot_data[metric == "TP.BAN_VAL", plot_date := Date + days(2)]

  # Create factor with proper labels and order
  plot_data[, metric := factor(metric,
                               levels = c("EP.BAN_VAL", "TZ.BAN_VAL", "TP.BAN_VAL"),
                               labels = c("EPOC",       "TRIMP ZN",   "TRIMP"))]

  # Create the plot
  p <- ggplot(plot_data, aes(x = plot_date, y = value, fill = metric, color = metric)) +
    # Add bars
    geom_col(width = 0.7, position = position_dodge(width = 0), alpha = 0.8, linewidth = 0) +
    # Scale and theme settings
    scale_y_continuous(sec.axis = dup_axis(name = "")) +
    labs(x = "", y = "", fill = "", color = "") +
    theme_bw() +
    theme(
      legend.position = "top",
      legend.direction = "horizontal",
      legend.title = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      panel.grid.major.y = element_line(color = "grey", linetype = "dotted", linewidth = 0.2),
      panel.grid.minor.y = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.margin = margin(10, 10, 10, 10)
    ) +
    guides(fill = guide_legend(nrow = 1))
  plot_show(p)


  #### normalize data  -------------------------------------------------------
  wecare <- grep("Date|VO2max", names(pppppp), invert = T, value = T)
  for (ac in wecare) {
    pppppp[[ac]] <- 100 * scale(x      = pppppp[[ac]],
                                center = min(pppppp[[ac]]),
                                scale  = diff(range(pppppp[[ac]])))
  }


  ####  Plot for each metric and model  --------------------------------------
  for (va in shortn) {
    for (mo in models) {

      cat(paste0("\n\n### ", va, " ", mo, "\n\n"))

      wp <- c(grep(paste0(va,".",mo), names(pppppp), value = TRUE),
              "Date", "VO2max_Detected")
      pp <- pppppp[, ..wp]
      ## easy names
      vfit <- grep("FIT", wp, value = T)
      vfat <- grep("FAT", wp, value = T)
      vper <- grep("PER", wp, value = T)
      vval <- grep("VAL", wp, value = T)

      ## Training Impulse model plot
      par("mar" = c(2,0,2,0), xpd = TRUE)

      pp[[vval]][pp[[vval]] == 0] <- NA

      # ----- Precompute values -----

      pp[[vval]][is.na(pp[[vval]])] <- 0

      pp <- pp %>%
        dplyr::mutate(
          load_scaled   = .data[[vval]] / 4,
          load_runmean  = caTools::runmean(.data[[vval]], k = 9, align = "right") / 2,
          fat           = .data[[vfat]],
          fit           = .data[[vfit]],
          per           = .data[[vper]]
        )

      prediction <- pp %>% filter(Date > last$Date)
      best       <- prediction %>% slice_max(per, n = 1)

      today_val_per <- pp$per[pp$Date == Sys.Date()]
      today_val_fit <- pp$fit[pp$Date == Sys.Date()]
      today_val_fat <- pp$fat[pp$Date == Sys.Date()]

      # Axis breaks
      mondays  <- pp %>% filter(wday(Date) == 2) %>% pull(Date)
      month_1  <- pp %>% filter(mday(Date) == 1)


      # ---- Precompute ----
      pp <- pp %>%
        dplyr::mutate(
          load_scaled  = .data[[vval]] / 3,
          load_runmean = caTools::runmean(.data[[vval]], k = 9, align = "right") / 2,
          fat = .data[[vfat]],
          fit = .data[[vfit]],
          per = .data[[vper]]
        )

      prediction <- pp %>% filter(Date > last$Date)
      best <- prediction %>% slice_max(per, n = 1)

      today <- Sys.Date()

      today_val_per <- pp$per[pp$Date == today]
      today_val_fit <- pp$fit[pp$Date == today]
      today_val_fat <- pp$fat[pp$Date == today]

      # ---- Plot ----

      p <- plot_ly(pp, x = ~Date)

      # Load bars
      p <- p %>%
        add_bars(
          y      = ~load_scaled,
          name   = "Load",
          marker = list(color = "rgba(113,113,113,0.4)")
        )

      # Runmean
      p <- p %>%
        add_lines(
          y    = ~load_runmean,
          name = "Load 9d mean",
          line = list(color = "rgba(113,113,113,0.7)", width = 1)
        )

      # VO2max
      p <- p %>%
        add_markers(
          y = ~VO2max_Detected,
          name = "VO2max",
          marker = list(color = "#EEA9B8", symbol = "line-ew-open", size = 10)
        )

      # Fatigue / Fitness / Performance
      p <- p %>%
        add_lines(y = ~fat, name = "Fatigue",
                  line = list(color = "green", width = 1)) %>%
        add_lines(y = ~fit, name = "Fitness",
                  line = list(color = "purple", width = 2.5)) %>%
        add_lines(y = ~per, name = "Performance",
                  line = list(color = "orange", width = 2.5))

      # ---- Reference Lines ----

      p <- p %>%
        layout(
          shapes = list(
            # Today vertical
            list(type = "line",
                 x0 = today, x1 = today,
                 y0 = 0, y1 = 1,
                 xref = "x", yref = "paper",
                 line = list(color = "green", dash = "dash")),

            # Best prediction vertical
            list(type = "line",
                 x0 = best$Date, x1 = best$Date,
                 y0 = 0, y1 = 1,
                 xref = "x", yref = "paper",
                 line = list(color = "yellow", dash = "dash")),

            # Best prediction horizontal
            list(type = "line",
                 x0 = min(pp$Date), x1 = max(pp$Date),
                 y0 = best$per, y1 = best$per,
                 line = list(color = "yellow", dash = "dash"))
          )
        )

      # ---- Annotations ----

      p <- p %>%
        add_annotations(
          x = best$Date,
          y = best$per,
          text = paste("Best:", round(best$per)),
          showarrow = TRUE,
          arrowhead = 2
        ) %>%
        add_annotations(
          x = today,
          y = today_val_per,
          text = paste("Today:", round(today_val_per)),
          showarrow = FALSE
        )

      # ---- Layout styling ----

      # p <- p %>%
      #   layout(
      #     title = paste(days, "d", va, mo, "best:", best$Date),
      #     legend = list(orientation = "h", x = 0.1, y = 1.1),
      #     xaxis = list(title = "", showgrid = FALSE),
      #     yaxis = list(title = "", zeroline = FALSE),
      #     barmode = "overlay"
      #   )

      p <- p %>%
        layout(
          title = paste(days, "d", va, mo, "best:", best$Date),
          legend = list(
            orientation = "h",
            x = 0.5,
            xanchor = "center",
            y = -0.20
          ),
          margin = list(b = 100),   # add bottom margin so legend isn't cut off
          xaxis = list(title = "", showgrid = FALSE),
          yaxis = list(title = "", zeroline = FALSE),
          barmode = "overlay"
        )

      plot_show(p)

    }
  }
}

#'
#' # Unified Performance Models
#'
#' All models is the daily mean of PMC, Banister and Busson models
#'
#+ echo=F, include=T, results="asis", warning=F


####  Plot of unified vars and models  ---------------------------------------
# days <- pdays[1]
for (days in pdays) {


  ## limit graph to last days
  pppppp <- gather[ Date >= max(Date) - days - extend, ]
  pppppp <- data.table(pppppp)
  models <- c("PMC", "BAN", "BUS")

  ## normalize data
  wecare <- grep("Date|VO2max", names(pppppp), invert = T, value = T)
  for (ac in wecare) {
    pppppp[[ac]] <- 100 * scale(x      = pppppp[[ac]],
                                center = min(pppppp[[ac]]),
                                scale  = diff(range(pppppp[[ac]])))
  }


  cat(paste0("\n\n## ", days, " days mean of models for each metric\n\n"))

  #### unified by model  -----------------------------------------------------
  unifid <- pppppp[, .(Date, VO2max_Detected)]
  for (met in c("EP","TZ","TP")) {
    for (mod in c("PER","FAT","FIT")) {
      wem <- grep(paste0(met,".*",mod), names(pppppp), value = T)
      unifid[[paste0(met,"_",mod)]] <- rowMeans( pppppp[,  ..wem ] )
    }
  }


  # Prepare the data for ggplot
  plot_data <- unifid %>%
    select(Date, EP_PER, EP_FAT, EP_FIT) %>%
    pivot_longer(cols = c(EP_PER, EP_FAT, EP_FIT),
                 names_to = "variable",
                 values_to = "value")

  # Create the plot
  g <- ggplot(plot_data, aes(x = Date, y = value, color = variable)) +
    geom_line(size = 0.8) +
    scale_color_manual(values = c("EP_PER" = "cyan3",
                                  "EP_FAT" = "green3",
                                  "EP_FIT" = "purple")) +
    scale_y_continuous(limits = c(0, 100)) +
    labs(title = "EPOC all models",
         x = NULL,
         y = NULL) +
    theme_minimal() +
    theme(
      plot.margin = margin(5, 5, 5, 0),
      legend.position = c(0.9, 0.9),
      legend.title = element_blank(),
      panel.grid.minor = element_blank()
    ) +
    # vertical line for today
    geom_vline(xintercept = Sys.Date(), color = "green", linetype = "dashed") +
    # Customize x-axis with monthly ticks and labels
    scale_x_date(
      date_breaks = "1 month",
      date_labels = "%b",
      minor_breaks = NULL
    ) +
    # weekly ticks (minor breaks)
    annotation_logticks(sides = "b",
                        outside = TRUE,
                        short = unit(0.1, "cm"),
                        mid = unit(0.2, "cm"),
                        long = unit(0.3, "cm")) +
    # Override to get weekly tick marks
    geom_rug(data = subset(unifid, wday(Date) == 2),
             aes(x = Date),
             sides = "b",
             length = unit(0.1, "cm"),
             color = "black",
             inherit.aes = FALSE)

  plot_show(g)





  # Prepare the data for ggplot
  plot_data <- unifid %>%
    select(Date, TZ_PER, TZ_FAT, TZ_FIT) %>%
    pivot_longer(cols = c(TZ_PER, TZ_FAT, TZ_FIT),
                 names_to = "variable",
                 values_to = "value")

  # Create the plot
  g <- ggplot(plot_data, aes(x = Date, y = value, color = variable)) +
    geom_line(size = 0.8) +
    scale_color_manual(values = c("TZ_PER" = "cyan3",
                                  "TZ_FAT" = "green3",
                                  "TZ_FIT" = "purple")) +
    scale_y_continuous(limits = c(0, 100)) +
    labs(title = "TRIMP Zonal all models",
         x = NULL,
         y = NULL) +
    theme_minimal() +
    theme(
      plot.margin = margin(5, 5, 5, 0),
      legend.position = c(0.9, 0.9),
      legend.title = element_blank(),
      panel.grid.minor = element_blank()
    ) +
    # vertical line for today
    geom_vline(xintercept = Sys.Date(), color = "green", linetype = "dashed") +
    # Customize x-axis with monthly ticks and labels
    scale_x_date(
      date_breaks = "1 month",
      date_labels = "%b",
      minor_breaks = NULL
    ) +
    # weekly ticks (minor breaks)
    annotation_logticks(sides = "b",
                        outside = TRUE,
                        short = unit(0.1, "cm"),
                        mid = unit(0.2, "cm"),
                        long = unit(0.3, "cm")) +
    # Override to get weekly tick marks
    geom_rug(data = subset(unifid, wday(Date) == 2),
             aes(x = Date),
             sides = "b",
             length = unit(0.1, "cm"),
             color = "black",
             inherit.aes = FALSE)

  plot_show(g)



  # Prepare the data for ggplot
  plot_data <- unifid %>%
    select(Date, TP_PER, TP_FAT, TP_FIT) %>%
    pivot_longer(cols = c(TP_PER, TP_FAT, TP_FIT),
                 names_to = "variable",
                 values_to = "value")

  # Create the plot
  g <- ggplot(plot_data, aes(x = Date, y = value, color = variable)) +
    geom_line(size = 0.8) +
    scale_color_manual(values = c("TP_PER" = "cyan3",
                                  "TP_FAT" = "green3",
                                  "TP_FIT" = "purple")) +
    scale_y_continuous(limits = c(0, 100)) +
    labs(title = "TRIMP all models",
         x = NULL,
         y = NULL) +
    theme_minimal() +
    theme(
      plot.margin = margin(5, 5, 5, 0),
      legend.position = c(0.9, 0.9),
      legend.title = element_blank(),
      panel.grid.minor = element_blank()
    ) +
    # vertical line for today
    geom_vline(xintercept = Sys.Date(), color = "green", linetype = "dashed") +
    # Customize x-axis with monthly ticks and labels
    scale_x_date(
      date_breaks = "1 month",
      date_labels = "%b",
      minor_breaks = NULL
    ) +
    # weekly ticks (minor breaks)
    annotation_logticks(sides = "b",
                        outside = TRUE,
                        short = unit(0.1, "cm"),
                        mid = unit(0.2, "cm"),
                        long = unit(0.3, "cm")) +
    # Override to get weekly tick marks
    geom_rug(data = subset(unifid, wday(Date) == 2),
             aes(x = Date),
             sides = "b",
             length = unit(0.1, "cm"),
             color = "black",
             inherit.aes = FALSE)

  plot_show(g)




  cat(paste0("\n\n## ", days, " days, daily mean of metric for each model\n\n"))

  #### unified by metric  ----------------------------------------------------
  unifid <- pppppp[, .(Date, VO2max_Detected)]
  for (met in c("BUS","BAN","PMC")) {
    for (mod in c("PER","FAT","FIT")) {
      wem <- grep(paste0(met,"_",mod), names(pppppp), value = T)
      unifid[[paste0(met,"_",mod)]] <- rowMeans(pppppp[, ..wem])
    }
  }


  # Prepare the data for EPOC
  epoc_data <- unifid %>%
    select(Date, PMC_PER, PMC_FAT, PMC_FIT) %>%
    pivot_longer(cols = c(PMC_PER, PMC_FAT, PMC_FIT),
                 names_to = "variable",
                 values_to = "value")

  # Create EPOC plot
  epoc_plot <- ggplot(epoc_data, aes(x = Date, y = value, color = variable)) +
    geom_line(size = 0.8) +
    scale_color_manual(values = c("PMC_PER" = "cyan3",
                                  "PMC_FAT" = "green3",
                                  "PMC_FIT" = "purple")) +
    scale_y_continuous(limits = c(0, 100)) +
    labs(title = "PMC all metrics",
         x = NULL,
         y = NULL) +
    theme_minimal() +
    theme(
      plot.margin = margin(5, 5, 5, 0),
      legend.position = c(0.9, 0.9),
      legend.title = element_blank(),
      panel.grid.minor = element_blank()
    ) +
    # vertical line for today
    geom_vline(xintercept = Sys.Date(), color = "green", linetype = "dashed") +
    # Customize x-axis with monthly ticks and labels
    scale_x_date(
      date_breaks = "1 month",
      date_labels = "%b",
      minor_breaks = NULL
    ) +
    # weekly ticks (minor breaks)
    annotation_logticks(sides = "b",
                        outside = TRUE,
                        short = unit(0.1, "cm"),
                        mid = unit(0.2, "cm"),
                        long = unit(0.3, "cm")) +
    # Override to get weekly tick marks
    geom_rug(data = subset(unifid, wday(Date) == 2),
             aes(x = Date),
             sides = "b",
             length = unit(0.1, "cm"),
             color = "black",
             inherit.aes = FALSE)

  # Display EPOC plot
  plot_show(epoc_plot)




  # Prepare the data for Banister
  ban_data <- unifid %>%
    select(Date, BAN_PER, BAN_FAT, BAN_FIT) %>%
    pivot_longer(cols = c(BAN_PER, BAN_FAT, BAN_FIT),
                 names_to = "variable",
                 values_to = "value")

  # Create EPOC plot
  ban_plot <- ggplot(ban_data, aes(x = Date, y = value, color = variable)) +
    geom_line(size = 0.8) +
    scale_color_manual(values = c("BAN_PER" = "cyan3",
                                  "BAN_FAT" = "green3",
                                  "BAN_FIT" = "purple")) +
    scale_y_continuous(limits = c(0, 100)) +
    labs(title = "Banister all metrics",
         x = NULL,
         y = NULL) +
    theme_minimal() +
    theme(
      plot.margin = margin(5, 5, 5, 0),
      legend.position = c(0.9, 0.9),
      legend.title = element_blank(),
      panel.grid.minor = element_blank()
    ) +
    # vertical line for today
    geom_vline(xintercept = Sys.Date(), color = "green", linetype = "dashed") +
    # Customize x-axis with monthly ticks and labels
    scale_x_date(
      date_breaks = "1 month",
      date_labels = "%b",
      minor_breaks = NULL
    ) +
    # weekly ticks (minor breaks)
    annotation_logticks(sides = "b",
                        outside = TRUE,
                        short = unit(0.1, "cm"),
                        mid = unit(0.2, "cm"),
                        long = unit(0.3, "cm")) +
    # Override to get weekly tick marks
    geom_rug(data = subset(unifid, wday(Date) == 2),
             aes(x = Date),
             sides = "b",
             length = unit(0.1, "cm"),
             color = "black",
             inherit.aes = FALSE)

  # Display EPOC plot
  plot_show(ban_plot)






  # Prepare the data for Busson
  buss_data <- unifid %>%
    select(Date, BUS_PER, BUS_FAT, BUS_FIT) %>%
    pivot_longer(cols = c(BUS_PER, BUS_FAT, BUS_FIT),
                 names_to = "variable",
                 values_to = "value")

  # Create EPOC plot
  buss_plot <- ggplot(buss_data, aes(x = Date, y = value, color = variable)) +
    geom_line(size = 0.8) +
    scale_color_manual(values = c("BUS_PER" = "cyan3",
                                  "BUS_FAT" = "green3",
                                  "BUS_FIT" = "purple")) +
    scale_y_continuous(limits = c(0, 100)) +
    labs(title = "Busson all metrics",
         x = NULL,
         y = NULL) +
    theme_minimal() +
    theme(
      plot.margin = margin(5, 5, 5, 0),
      legend.position = c(0.9, 0.9),
      legend.title = element_blank(),
      panel.grid.minor = element_blank()
    ) +
    # vertical line for today
    geom_vline(xintercept = Sys.Date(), color = "green", linetype = "dashed") +
    # Customize x-axis with monthly ticks and labels
    scale_x_date(
      date_breaks = "1 month",
      date_labels = "%b",
      minor_breaks = NULL
    ) +
    # weekly ticks (minor breaks)
    annotation_logticks(sides = "b",
                        outside = TRUE,
                        short = unit(0.1, "cm"),
                        mid = unit(0.2, "cm"),
                        long = unit(0.3, "cm")) +
    # Override to get weekly tick marks
    geom_rug(data = subset(unifid, wday(Date) == 2),
             aes(x = Date),
             sides = "b",
             length = unit(0.1, "cm"),
             color = "black",
             inherit.aes = FALSE)

  # Display EPOC plot
  plot_show(buss_plot)


}




##TODO Yearly
##TODO make it an html table

capture.output({
  metrics <- metrics[as.Date(Date) > Sys.Date() - 400, ]
  weekly  <- metrics[, .(TRIMP_Points       = round(sum(Trimp_Points,       na.rm = TRUE)),
                         TRIMP_Zonal_Points = round(sum(Trimp_Zonal_Points, na.rm = TRUE)),
                         EPOC               = round(sum(EPOC,               na.rm = TRUE)),
                         Load_2             = round(sum(Load_2,             na.rm = TRUE)),
                         TrimpModWeighed    = round(sum(TrimpModWeighed,    na.rm = TRUE)),
                         Total_Distance     = round(sum(Total_Distance,     na.rm = TRUE)),
                         Calories           = round(sum(Total_Kcalories,    na.rm = TRUE))),
                     by = .(Year = year(Date), Week = isoweek(Date) )]
  weekly[ , Date := as.Date(paste(Year, Week, 1, sep="-"), "%Y-%U-%u") ]
  setorder(weekly, Date)

  monthly <- metrics[, .(TRIMP_Points       = round(sum(Trimp_Points,       na.rm = TRUE)),
                         TRIMP_Zonal_Points = round(sum(Trimp_Zonal_Points, na.rm = TRUE)),
                         EPOC               = round(sum(EPOC,               na.rm = TRUE)),
                         Load_2             = round(sum(Load_2,             na.rm = TRUE)),
                         TrimpModWeighed    = round(sum(TrimpModWeighed,    na.rm = TRUE)),
                         Total_Distance     = round(sum(Total_Distance,     na.rm = TRUE)),
                         Calories           = round(sum(Total_Kcalories,    na.rm = TRUE))),
                     by = .(Year = year(Date), month = month(Date))]
  monthly[ , Date := as.Date(paste(Year, month, 1, sep="-"), "%Y-%m-%d") ]
  setorder(monthly, Date)

  cat("\n\n## WEEKLY SUMS\n\n")
  panderOptions("table.split.table", 200)
  panderOptions("table.style", "simple")
  pander(weekly)
  pander(weekly[1,])
  # cat(paste( names(weekly), collapse = "\t" ), "\n" )

  cat("\n\n## MONTHLY SUMS\n\n")
  pander(monthly)
  pander(monthly[1,])
  # cat(paste(  names(montly), collapse = "\t" ), "\n" )

}, file = loadtables)





# Prepare the data - take last 10 weeks
weekly_data <- tail(weekly, 10) %>%
  select(Date,
         TRIMP_Points,
         TRIMP_Zonal_Points,
         EPOC,
         Load_2,
         TrimpModWeighed,
         Calories) %>%
  # Scale the data to match the original plot
  mutate(
    TrimpModWeighed_scaled = TrimpModWeighed / 100,
    Calories_scaled = Calories / 10
  )

# Check the actual scaling - if Calories/10 was used in original, use that
# weekly_data$Calories_scaled <- weekly_data$Calories / 10  # Uncomment if /10 is correct

# Reshape for ggplot
plot_data <- weekly_data %>%
  pivot_longer(cols = c(TRIMP_Points, TRIMP_Zonal_Points, EPOC,
                        Load_2, TrimpModWeighed_scaled, Calories_scaled),
               names_to = "variable",
               values_to = "value")

# Create the plot
weekly_plot <- ggplot(plot_data, aes(x = Date, y = value, color = variable, group = variable)) +
  geom_line(size = 1.2) +
  scale_color_manual(
    values = c(
      "TRIMP_Points" = "blue",
      "TRIMP_Zonal_Points" = "green3",
      "EPOC" = "red",
      "Load_2" = "purple",
      "TrimpModWeighed_scaled" = "orange",
      "Calories_scaled" = "cyan3"
    ),
    labels = c(
      "TRIMP_Points" = "TRIMP",
      "TRIMP_Zonal_Points" = "TRIMP Zoned",
      "EPOC" = "EPOC",
      "Load_2" = "Load_2",
      "TrimpModWeighed_scaled" = "TrimpModWeighed/100",
      "Calories_scaled" = "Calories/10"
    )
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0.05, 0.05))
  ) +
  labs(
    title = NULL,
    x = NULL,
    y = NULL
  ) +
  theme_minimal() +
  theme(
    plot.margin = margin(5, 5, 5, 5),
    legend.position = "top",
    legend.justification = "left",
    legend.title = element_blank(),
    legend.text = element_text(size = 8),
    legend.key.width = unit(0.5, "cm"),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1)
  ) +
  # Scale x-axis to show all dates
  scale_x_date(
    date_breaks = "1 week",
    date_labels = "%b %d"
  )

# Display the plot
plot_show(weekly_plot)







if (!interactive()) dev.off()



capture.output({
  wecare <- names(metrics)
  wecare <- grep("Average_Heart_Rate", wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Average_Temp",       wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Change_History",     wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Device",             wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Elevation_Gain",     wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Equipment_Weight",   wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Feel",               wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("File_Format",        wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Filename",           wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("GPS_errors",         wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Left_Right",         wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Month",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Notes",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Spike_Time",         wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("SubSport",           wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("RPE",                wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Swim",               wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Temperature",        wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("W_bal",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Year",               wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^Best",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^Bike",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^HI",                wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^H[0-9]",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^LI",                wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^L[0-9]",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^PI",                wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^P[0-9]",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^Pch|^Col",          wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^Spikes",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^W[0-9]",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^X[0-9]",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("^pN",                wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("_Carrying",          wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("xPower",             wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("aPower",             wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("aBike",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("parsed",             wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("critical",           wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("peak",               wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("time_in",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("in_zone",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("dropout",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("present",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("overrides",          wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Calendar_Text",      wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Weekday",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("Calories",           wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("_temp",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("pace_row",           wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("_V2$",               wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("_V3$",               wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("compatibility_",     wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("shoes",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("daniels",            wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)
  wecare <- grep("govss",              wecare, invert = TRUE, value = TRUE, ignore.case = TRUE)


  export <- metrics[, ..wecare]
  export <- rm.cols.dups.DT(export)
  export <- rm.cols.NA.DT(export)
  names(export)

  cat("\n\n## Activities\n\n")
  panderOptions("table.split.table", 2000)
  panderOptions("table.style", "simple")
  pander(export)
  pander(export[1,])

}, file = lastactivit)



#### For mobile png 720 x 1520  ----------------------------------------------
days <- 100

## limit graph to last days
 pppppp <- gather[ Date >= max(Date) - days - extend, ]
 pppppp <- pppppp[ Date <= Sys.Date() + 10 ]
 pppppp <- data.table(pppppp)
 models <- c("PMC", "BAN", "BUS")

 ## each day plot
 shortn <- c(        "TP",         "TZ",         "EP")
 wwca   <- c("EP.BAN_VAL", "TZ.BAN_VAL", "TP.BAN_VAL")
 ylim   <- range(pppppp[ , ..wwca ], na.rm = T)

 ## normalize data
 wecare <- grep("Date|VO2max", names(pppppp), invert = T, value = T)
 for (ac in wecare) {
   pppppp[[ac]] <- 100 * scale(x      = pppppp[[ac]],
                               center = min(pppppp[[ac]]),
                               scale  = diff(range(pppppp[[ac]])))
 }

 wecc <- grep( "^RP" ,names(pppppp), invert = T, value = T)
 pppppp <- pppppp[, ..wecc ]


 for (va in shortn) {

   png(paste0("/home/athan/LOGs/training_status/", va, ".png"), width = 720, height = 1520, units = "px", bg = "transparent")

   layout(matrix(c(5,1,1,1,1,2,2,2,2,3,3,3,3,4,4), 15, 1, byrow = TRUE))
   # layout.show(4)

   for (mo in models) {
     wp <- c(grep(paste0(va,".",mo), names(pppppp), value = TRUE),
             "Date", "VO2max_Detected")
     pp <- pppppp[, ..wp]
     ## easy names
     vfit <- grep("FIT",wp,value = T)
     vfat <- grep("FAT",wp,value = T)
     vper <- grep("PER",wp,value = T)
     vval <- grep("VAL",wp,value = T)

     #### Training Impulse model plot  ----------------------------------------
     par("mar" = c(2,0,1,0),
         xpd = FALSE,
         col      = "grey",
         col.axis = "grey",
         col.lab  = "grey",
         yaxt     = "n")

     pp[[vval]][pp[[vval]] == 0] <- NA
     plot(pp$Date, pp[[vval]]/4, ylim = range(0, pp[[vval]], na.rm = T), type = "h", bty = "n", lwd = 4, col = "#959595" )
     pp[[vval]][is.na(pp[[vval]])] <- 0
     lines(pp$Date, caTools::runmean(pp[[vval]], k = 9, align = "right")/2, col = "#959595", lwd = 2)
     box(col="white")
     par(new = T)
     ylim <-range( 45,53, pp$VO2max_Detected, na.rm = T)
     plot( pp$Date, pp$VO2max_Detected, ylim = ylim, col = "pink", pch = "-", cex = 4 )
     box(col="white")
     par(new = T)
     ylim    <- range(pp[[vfit]], pp[[vfat]], pp[[vper]], na.rm = T)
     ylim[2] <- ylim[2] * 1.09
     plot(pp$Date, pp[[vfat]], col = 3, lwd = 2, "l", yaxt = "n", ylim = ylim)
     abline(v=Sys.Date(),col="green",lty=2)
     box(col="white")
     par(new = T)
     plot(pp$Date, pp[[vfit]], col = 5, lwd = 4, "l", yaxt = "n", ylim = ylim)
     box(col="white")
     par(new = T)
     plot(pp$Date, pp[[vper]], col = 6, lwd = 4, "l", yaxt = "n", ylim = ylim)

     # legend("top", bty = "n", ncol = 3, lty = 1, inset = c(0, -0.01),
     #        cex = 0.7, text.col = "grey",
     #        legend = c("Fatigue", "Fitness","Performance"),
     #        col    = c(    3 ,     5 ,    6 ) )

     legend("topleft", bty = "n", title = paste(va, mo, best$Date), legend = c(""), cex = 4)

     prediction <- pp[ Date > last$Date, ]
     best       <- prediction[ which.max(prediction[[vper]]) ]
     abline(v = best$Date,    col = "yellow", lty = 2, lwd = 2)
     abline(h = best[[vper]], col = "yellow", lty = 2, lwd = 2)

     abline(h = pp[[vper]][ pp$Date == Sys.Date() ], col = 6, lty = 2, lwd = 2)
     text(pp[ which.max(pp[[vper]]), Date ], pp[[vper]][which.max(pp[[vper]])],
          labels = round(pp[[vper]][which.max(pp[[vper]])]), col = 6, pos = 3, cex = 2 )
     text(Sys.Date(), pp[[vper]][pp$Date == Sys.Date()],
          labels = round(pp[[vper]][pp$Date == Sys.Date()]), col = 6, pos = 4, cex = 2 )

     abline(h = pp[[vfit]][ pp$Date == Sys.Date() ], col = 5, lty = 2, lwd = 2)
     text(pp[ which.max(pp[[vfit]]), Date ], pp[[vfit]][which.max(pp[[vfit]])],
          labels = round(pp[[vfit]][which.max(pp[[vfit]])]), col = 5, pos = 3, cex = 2 )
     text(Sys.Date(), pp[[vfit]][pp$Date == Sys.Date()],
          labels = round(pp[[vfit]][pp$Date == Sys.Date()]), col = 5, pos = 4, cex = 2 )

     # abline(h = pp[[vfat]][ pp$Date == Sys.Date() ], col = 3, lty = 2)
     text(pp[ which.max(pp[[vfat]]), Date ], pp[[vfat]][which.max(pp[[vfat]])],
          labels = round(pp[[vfat]][which.max(pp[[vfat]])]), col = 3, pos = 3, cex = 2 )
     text(Sys.Date(), pp[[vfat]][pp$Date == Sys.Date()],
          labels = round(pp[[vfat]][pp$Date == Sys.Date()]), col = 3, pos = 4, cex = 2 )

     axis(1, at = pp[wday(Date) == 2, Date ], labels = F, col = "grey", col.ticks = "grey")
     axis(1, at = pp[mday(Date) == 1, Date ], labels = format(pp[mday(Date) == 1, Date ], "%b"), col = "grey", col.ticks = "grey", lwd.ticks = 3)

   }
   dev.off()
 }




####_ END _####
tac <- Sys.time()
cat(sprintf("\n\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
