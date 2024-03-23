#!/usr/bin/env Rscript

#### Golden Cheetah plot total trends

## Used inside Golden Cheetah software

####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/training_analysis/GC_target_estimation.R"

out_file <- paste0("~/LOGs/training_status/", basename(sub("\\.R$", ".pdf", Script.Name)))
in_file  <- "~/DATA/Other/GC_json_ride_data_2.Rds"

##  Check if have to run  ------------------------------------------------------
if (!file.exists(out_file) |
    file.mtime(out_file) < file.mtime(in_file) |
    interactive()) {
  cat("Have to run\n")
} else {
  cat("Not have to run\n")
  stop("Not have to run")
}

if (!interactive()) {
  pdf(file = out_file)
}

##  Load parsed data
metrics <- readRDS(in_file)

####  Copy for GC below  -------------------------------------------------------
library(data.table)
library(scales)

##  Load parsed data
metrics <- data.table(readRDS(in_file))
metrics <- metrics[Sport %in% c("Run", "Bike"), ]
metrics <- janitor::remove_constant(metrics)


cols <- c(
  "#f22e2e", "#d9b629", "#30ff83", "#3083ff", "#f22ee5", "#33161e", "#e6a89e",
  "#bbbf84", "#1d995f", "#324473", "#cc8dc8", "#59111b", "#b25c22", "#b1f22e",
  "#9ee6d7", "#482ef2", "#66465b", "#33200a", "#385911", "#24a0bf", "#270f4d",
  "#731647", "#664a13", "#414d35", "#22444d", "#6b1880", "#ff70a9")

## plot params
cex <- 1


table(metrics$Sport, metrics$Workout_Code)

metrics[Sport == "Run" & Workout_Code == "HRV", Date]

## aggregate data for load estimation
metrics[, Duration := Workout_Time / 3600 ]
DATA <- metrics[ , .(Distance = sum(Total_Distance,  na.rm = T),
                     Duration = sum(Duration,        na.rm = T),
                     Ascent   = sum(Elevation_Gain,  na.rm = T),
                     Descent  = sum(Elevation_Loss,  na.rm = T),
                     Calories = sum(Total_Kcalories, na.rm = T)),
                 by = .( date = as.Date((as.numeric(as.Date(metrics$Date)) %/% 7) * 7, origin = "1970-01-01"),
                         sport = Sport) ]

## by year
for (ay in sort(unique(year(DATA$date)), decreasing = T)) {
  ## by sport
  for (as in na.omit(unique(DATA$sport))) {

    data      <- DATA[year(date) == ay & sport == as, ]

    if (nrow(data) < 2) next()

    lastdate  <- as.Date(paste0(year(max(data$date)),"-12-31"))
    firstdate <- as.Date(paste0(year(max(data$date)),"-01-01"))

    ## prepare cusums by week
    data[, Cum_Dist := cumsum(Distance) ]
    data[, Cum_Dura := cumsum(Duration) ]
    data[, Cum_Asce := cumsum(Ascent  ) ]
    data[, Cum_Desc := cumsum(Descent ) ]
    data[, Cum_Calo := cumsum(Calories) ]

    ## create all days
    data <- merge(data,
                  data.table(date = seq(firstdate, lastdate, by = "day")),
                  all = TRUE)

    data$Pre_Dist <- tryCatch(
      data[, predict(lm(Cum_Dist ~ date, data = data[sport == as]), date)],
      error = function(x) rep(NA, data[, .N])
    )
    data$Pre_Dura <- tryCatch(
      data[, predict(lm(Cum_Dura ~ date, data = data[sport == as]), date)],
      error = function(x) rep(NA, data[, .N])
    )
    data$Pre_Asce <- tryCatch(
      data[, predict(lm(Cum_Asce ~ date, data = data[sport == as]), date)],
      error = function(x) rep(NA, data[, .N])
    )
    data$Pre_Desc <- tryCatch(
      data[, predict(lm(Cum_Desc ~ date, data = data[sport == as]), date)],
      error = function(x) rep(NA, data[, .N])
    )
    data$Pre_Calo <- tryCatch(
      data[, predict(lm(Cum_Calo ~ date, data = data[sport == as]), date)],
      error = function(x) rep(NA, data[, .N])
    )

    assign(paste0("PP_", as), data)
  }
  rm(data)

  ## plots
  layout(matrix(c(1,2,3,4), 4, 1, byrow = TRUE))

  xlim <- range(PP_Bike$date, na.rm = T)
  par(mar = c(2, 3, 1, 3))
  par(xpd = TRUE)


  ## Distance plot  ------------------------------------------------------------
  ylimW <- range(0, PP_Bike$Distance, PP_Run$Distance, na.rm = T)
  ylimD <- range(PP_Bike$Cum_Dist, PP_Bike$Pre_Dist,
                 PP_Run$Cum_Dist,  PP_Run$Pre_Dist,
                 na.rm = T)
  if (ylimD[1] < 0) ylimD[1] <- 0

  ## _ Bike  -------------------------------------------------------------------
  cc <- 4

  ## week distance
  plot(
    PP_Bike$date + 3,
    PP_Bike$Distance,
    "h",
    xlab     = "",
    ylab     = "",
    axes     = FALSE,
    bty      = "n",
    lty      = "12",
    cex.axis = cex,
    lwd      = 4,
    col      = alpha(cols[cc], 0.7),
    xlim     = xlim,
    ylim     = c(ylimW[1], ylimW[2] * 1.1 ) )

  abline(
    h   = mean(PP_Bike$Distance, na.rm = T),
    col = alpha(cols[cc], 0.7),
    lty = 3,
    lwd = 2
  )
  text(
    x      = last(PP_Bike$date),
    y      = mean(PP_Bike$Distance, na.rm = T),
    labels = round(mean(PP_Bike$Distance, na.rm = T)),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )
  mtext(
    "Weekly Distance",
    side = 4,
    line = 2,
    col  = 1,
    cex  = 0.7
  )
  axis(
    side     = 4,
    at       = pretty(range(c(PP_Run$Distance, PP_Bike$Distance), na.rm = T)),
    cex.axis = cex,
    col.axis = 1
  )

  title(ay)

  ## cumulative distance
  par(new = TRUE)
  plot(
    PP_Bike[!is.na(Cum_Dist), Cum_Dist, date],
    "s",
    xlab     = "",
    ylab     = "",
    cex.axis = cex,
    bty      = "n",
    lwd      = 3,
    col      = alpha(cols[cc], 0.7),
    col.axis = 1,
    xlim     = xlim,
    ylim     = ylimD
  )
  ## current line
  endp <- last(PP_Bike[!is.na(Cum_Dist), Cum_Dist, date])
  lines(x   = c(endp$date, as.Date(paste0(year(endp$date),"-12-31"))),
        y   = c(endp$Cum_Dist, endp$Cum_Dist), lty = 2, lwd = 1,
        col = alpha(cols[cc], 0.7))
  text(
    x      = as.Date(paste0(year(endp$date),"-12-31")),
    y      = endp$Cum_Dist,
    labels = round(endp$Cum_Dist),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )



  axis(
    side = 1,
    at = pretty(range(c(PP_Run$Cum_Dist, PP_Bike$Cum_Dist), na.rm = T)),
    cex.axis = cex,
    col.axis = cols[cc]
  )
  mtext(
    "Total Distance",
    side = 2,
    line = 2,
    col = 1,
    cex = 0.7
  )

  ## lm line
  lines(
    PP_Bike[, Pre_Dist, date],
    lwd = 3,
    col = alpha(cols[cc], 0.7),
    lty = 3
  )
  text(
    x      = last(PP_Bike$date),
    y      = last(PP_Bike$Pre_Dist),
    labels = round(last(PP_Run$Pre_Dist)),
    pos    = 4,
    col    = alpha(cols[cc], 0.7)
  )




  ## _ Run  --------------------------------------------------------------------

  ## week distance
  par(new = TRUE)
  cc <- 8
  plot(
    PP_Run$date,
    PP_Run$Distance,
    "h",
    xlab     = "",
    ylab     = "",
    axes     = FALSE,
    bty      = "n",
    cex.axis = cex,
    lwd      = 4,
    col      = alpha(cols[cc], 0.7),
    xlim     = xlim,
    ylim     = c(ylimW[1], ylimW[2] * 1.1 )
  )

  abline(
    h   = mean(PP_Run$Distance, na.rm = T),
    col = alpha(cols[cc], 0.7),
    lty = 3,
    lwd = 2
  )
  text(
    x      = last(PP_Bike$date),
    y      = mean(PP_Run$Distance, na.rm = T),
    labels = round(mean(PP_Run$Distance, na.rm = T)),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )

  ## cumulative distance
  par(new = TRUE)
  plot(
    PP_Run[!is.na(Cum_Dist), Cum_Dist, date],
    "s",
    xlab     = "",
    ylab     = "",
    cex.axis = cex,
    lwd      = 3,
    bty      = "n",
    col      = alpha(cols[cc], 0.7),
    col.axis = 1,
    xlim     = xlim,
    ylim     = ylimD
  )
  ## current line
  endp <- last(PP_Run[!is.na(Cum_Dist), Cum_Dist, date])
  lines(x   = c(endp$date, as.Date(paste0(year(endp$date),"-12-31"))),
        y   = c(endp$Cum_Dist, endp$Cum_Dist), lty = 2, lwd = 1,
        col = alpha(cols[cc], 0.7))
  text(
    x      = as.Date(paste0(year(endp$date),"-12-31")),
    y      = endp$Cum_Dist,
    labels = round(endp$Cum_Dist),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )



  ## lm line
  lines(
    PP_Run[, Pre_Dist, date],
    lwd = 3,
    col = alpha(cols[cc], 0.7),
    lty = 3
  )
  text(
    x      = last(PP_Run$date),
    y      = last(PP_Run$Pre_Dist),
    labels = round(last(PP_Run$Pre_Dist)),
    pos    = 4,
    col    = alpha(cols[cc], 0.7)
  )

  ## current
  cc <- 3
  abline(
    v   = Sys.Date(),
    lty = 3,
    lwd = 3,
    col = alpha(cols[cc], 0.7)
  )





  ## Duration plot  ------------------------------------------------------------
  ylimW <- range(0, PP_Bike$Duration, PP_Run$Duration, na.rm = T)
  ylimD <- range(PP_Bike$Cum_Dura, PP_Bike$Pre_Dura,
                 PP_Run$Cum_Dura,  PP_Run$Pre_Dura,
                 na.rm = T)
  if (ylimD[1] < 0) ylimD[1] <- 0

  ## _ Bike  -------------------------------------------------------------------
  cc <- 5

  ## week Duration
  plot(
    PP_Bike$date + 3,
    PP_Bike$Duration,
    "h",
    xlab     = "",
    ylab     = "",
    axes     = FALSE,
    bty      = "n",
    lty      = "12",
    cex.axis = cex,
    lwd      = 4,
    col      = alpha(cols[cc], 0.7),
    xlim     = xlim,
    ylim     = c(ylimW[1], ylimW[2] * 1.1 ) )

  abline(
    h   = mean(PP_Bike$Duration, na.rm = T),
    col = alpha(cols[cc], 0.7),
    lty = 3,
    lwd = 2
  )
  text(
    x      = last(PP_Bike$date),
    y      = mean(PP_Bike$Duration, na.rm = T),
    labels = round(mean(PP_Bike$Duration, na.rm = T)),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )
  mtext(
    "Weekly Duration",
    side = 4,
    line = 2,
    col  = 1,
    cex  = 0.7
  )
  axis(
    side     = 4,
    at       = pretty(range(c(PP_Run$Duration, PP_Bike$Duration), na.rm = T)),
    cex.axis = cex,
    col.axis = 1
  )


  ## cumulative duration
  par(new = TRUE)
  plot(
    PP_Bike[!is.na(Cum_Dura), Cum_Dura, date],
    "s",
    xlab     = "",
    ylab     = "",
    cex.axis = cex,
    bty      = "n",
    lwd      = 3,
    col      = alpha(cols[cc], 0.7),
    col.axis = 1,
    xlim     = xlim,
    ylim     = ylimD
  )
  ## current line
  endp <- last(PP_Bike[!is.na(Cum_Dura), Cum_Dura, date])
  lines(x   = c(endp$date, as.Date(paste0(year(endp$date),"-12-31"))),
        y   = c(endp$Cum_Dura, endp$Cum_Dura), lty = 2, lwd = 1,
        col = alpha(cols[cc], 0.7))
  text(
    x      = as.Date(paste0(year(endp$date),"-12-31")),
    y      = endp$Cum_Dura,
    labels = round(endp$Cum_Dura),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )


  axis(
    side = 1,
    at = pretty(range(c(PP_Run$Cum_Dura, PP_Bike$Cum_Dura), na.rm = T)),
    cex.axis = cex,
    col.axis = cols[cc]
  )
  mtext(
    "Total Duration",
    side = 2,
    line = 2,
    col = 1,
    cex = 0.7
  )

  ## lm line
  lines(
    PP_Bike[, Pre_Dura, date],
    lwd = 3,
    col = alpha(cols[cc], 0.7),
    lty = 3
  )
  text(
    x      = last(PP_Bike$date),
    y      = last(PP_Bike$Pre_Dura),
    labels = round(last(PP_Run$Pre_Dura)),
    pos    = 4,
    col    = alpha(cols[cc], 0.7)
  )




  ## _ Run  --------------------------------------------------------------------

  ## week distance
  par(new = TRUE)
  cc <- 9
  plot(
    PP_Run$date,
    PP_Run$Duration,
    "h",
    xlab     = "",
    ylab     = "",
    axes     = FALSE,
    bty      = "n",
    cex.axis = cex,
    lwd      = 4,
    col      = alpha(cols[cc], 0.7),
    xlim     = xlim,
    ylim     = c(ylimW[1], ylimW[2] * 1.1 )
  )

  abline(
    h   = mean(PP_Run$Duration, na.rm = T),
    col = alpha(cols[cc], 0.7),
    lty = 3,
    lwd = 2
  )
  text(
    x      = last(PP_Bike$date),
    y      = mean(PP_Run$Duration, na.rm = T),
    labels = round(mean(PP_Run$Duration, na.rm = T)),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )

  ## cumulative distance
  par(new = TRUE)
  plot(
    PP_Run[!is.na(Cum_Dura), Cum_Dura, date],
    "s",
    xlab     = "",
    ylab     = "",
    cex.axis = cex,
    lwd      = 3,
    bty      = "n",
    col      = alpha(cols[cc], 0.7),
    col.axis = 1,
    xlim     = xlim,
    ylim     = ylimD
  )
  ## current line
  endp <- last(PP_Run[!is.na(Cum_Dura), Cum_Dura, date])
  lines(x   = c(endp$date, as.Date(paste0(year(endp$date),"-12-31"))),
        y   = c(endp$Cum_Dura, endp$Cum_Dura), lty = 2, lwd = 1,
        col = alpha(cols[cc], 0.7))
  text(
    x      = as.Date(paste0(year(endp$date),"-12-31")),
    y      = endp$Cum_Dura,
    labels = round(endp$Cum_Dura),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )


  ## lm line
  lines(
    PP_Run[, Pre_Dura, date],
    lwd = 3,
    col = alpha(cols[cc], 0.7),
    lty = 3
  )
  text(
    x      = last(PP_Run$date),
    y      = last(PP_Run$Pre_Dura),
    labels = round(last(PP_Run$Pre_Dura)),
    pos    = 4,
    col    = alpha(cols[cc], 0.7)
  )

  ## current
  cc <- 3
  abline(
    v   = Sys.Date(),
    lty = 3,
    lwd = 3,
    col = alpha(cols[cc], 0.7)
  )







  ## Ascent plot  --------------------------------------------------------------
  ylimW <- range(0, PP_Bike$Ascent, PP_Run$Ascent, na.rm = T)
  ylimD <- range(PP_Bike$Cum_Asce, PP_Bike$Pre_Asce,
                 PP_Run$Cum_Asce,  PP_Run$Pre_Asce,
                 na.rm = T)
  if (ylimD[1] < 0) ylimD[1] <- 0

  ## _ Bike  -------------------------------------------------------------------
  cc <- 6

  ## week Ascent
  plot(
    PP_Bike$date + 3,
    PP_Bike$Ascent,
    "h",
    xlab     = "",
    ylab     = "",
    axes     = FALSE,
    bty      = "n",
    lty      = "12",
    cex.axis = cex,
    lwd      = 4,
    col      = alpha(cols[cc], 0.7),
    xlim     = xlim,
    ylim     = c(ylimW[1], ylimW[2] * 1.1 ) )

  abline(
    h   = mean(PP_Bike$Ascent, na.rm = T),
    col = alpha(cols[cc], 0.7),
    lty = 3,
    lwd = 2
  )
  text(
    x      = last(PP_Bike$date),
    y      = mean(PP_Bike$Ascent, na.rm = T),
    labels = round(mean(PP_Bike$Ascent, na.rm = T)),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )
  mtext(
    "Weekly Ascent",
    side = 4,
    line = 2,
    col  = 1,
    cex  = 0.7
  )
  axis(
    side     = 4,
    at       = pretty(range(c(PP_Run$Ascent, PP_Bike$Ascent), na.rm = T)),
    cex.axis = cex,
    col.axis = 1
  )


  ## cumulative ascend
  par(new = TRUE)
  plot(
    PP_Bike[!is.na(Cum_Asce), Cum_Asce, date],
    "s",
    xlab     = "",
    ylab     = "",
    cex.axis = cex,
    bty      = "n",
    lwd      = 3,
    col      = alpha(cols[cc], 0.7),
    col.axis = 1,
    xlim     = xlim,
    ylim     = ylimD
  )
  ## current line
  endp <- last(PP_Bike[!is.na(Cum_Asce), Cum_Asce, date])
  lines(x   = c(endp$date, as.Date(paste0(year(endp$date),"-12-31"))),
        y   = c(endp$Cum_Asce, endp$Cum_Asce), lty = 2, lwd = 1,
        col = alpha(cols[cc], 0.7))
  text(
    x      = as.Date(paste0(year(endp$date),"-12-31")),
    y      = endp$Cum_Asce,
    labels = round(endp$Cum_Asce),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )

  axis(
    side = 1,
    at = pretty(range(c(PP_Run$Cum_Asce, PP_Bike$Cum_Asce), na.rm = T)),
    cex.axis = cex,
    col.axis = cols[cc]
  )
  mtext(
    "Total Ascent",
    side = 2,
    line = 2,
    col = 1,
    cex = 0.7
  )

  ## lm line
  lines(
    PP_Bike[, Pre_Asce, date],
    lwd = 3,
    col = alpha(cols[cc], 0.7),
    lty = 3
  )
  text(
    x      = last(PP_Bike$date),
    y      = last(PP_Bike$Pre_Asce),
    labels = round(last(PP_Run$Pre_Asce)),
    pos    = 4,
    col    = alpha(cols[cc], 0.7)
  )




  ## _ Run  --------------------------------------------------------------------

  ## week ascent
  par(new = TRUE)
  cc <- 10
  plot(
    PP_Run$date,
    PP_Run$Ascent,
    "h",
    xlab     = "",
    ylab     = "",
    axes     = FALSE,
    bty      = "n",
    cex.axis = cex,
    lwd      = 4,
    col      = alpha(cols[cc], 0.7),
    xlim     = xlim,
    ylim     = c(ylimW[1], ylimW[2] * 1.1 )
  )
  abline(
    h   = mean(PP_Run$Ascent, na.rm = T),
    col = alpha(cols[cc], 0.7),
    lty = 3,
    lwd = 2
  )
  text(
    x      = last(PP_Bike$date),
    y      = mean(PP_Run$Ascent, na.rm = T),
    labels = round(mean(PP_Run$Ascent, na.rm = T)),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )

  ## cumulative ascent
  par(new = TRUE)
  plot(
    PP_Run[!is.na(Cum_Asce), Cum_Asce, date],
    "s",
    xlab     = "",
    ylab     = "",
    cex.axis = cex,
    lwd      = 3,
    bty      = "n",
    col      = alpha(cols[cc], 0.7),
    col.axis = 1,
    xlim     = xlim,
    ylim     = ylimD
  )
  ## current line
  endp <- last(PP_Run[!is.na(Cum_Asce), Cum_Asce, date])
  lines(x   = c(endp$date, as.Date(paste0(year(endp$date),"-12-31"))),
        y   = c(endp$Cum_Asce, endp$Cum_Asce), lty = 2, lwd = 1,
        col = alpha(cols[cc], 0.7))
  text(
    x      = as.Date(paste0(year(endp$date),"-12-31")),
    y      = endp$Cum_Asce,
    labels = round(endp$Cum_Asce),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )


  ## lm line
  lines(
    PP_Run[, Pre_Asce, date],
    lwd = 3,
    col = alpha(cols[cc], 0.7),
    lty = 3
  )
  text(
    x      = last(PP_Run$date),
    y      = last(PP_Run$Pre_Asce),
    labels = round(last(PP_Run$Pre_Asce)),
    pos    = 4,
    col    = alpha(cols[cc], 0.7)
  )

  ## current
  cc <- 3
  abline(
    v   = Sys.Date(),
    lty = 3,
    lwd = 3,
    col = alpha(cols[cc], 0.7)
  )












  ## Calories plot  ------------------------------------------------------------
  ylimW <- range(0, PP_Bike$Calories, PP_Run$Calories, na.rm = T)
  ylimD <- range(PP_Bike$Cum_Calo, PP_Bike$Pre_Calo,
                 PP_Run$Cum_Calo,  PP_Run$Pre_Calo,
                 na.rm = T)
  if (ylimD[1] < 0) ylimD[1] <- 0


  ## _ Bike  -------------------------------------------------------------------
  cc <- 7

  ## week Calories
  plot(
    PP_Bike$date + 3,
    PP_Bike$Calories,
    "h",
    xlab     = "",
    ylab     = "",
    axes     = FALSE,
    bty      = "n",
    lty      = "12",
    cex.axis = cex,
    lwd      = 4,
    col      = alpha(cols[cc], 0.7),
    xlim     = xlim,
    ylim     = c(ylimW[1], ylimW[2] * 1.1 ) )

  abline(
    h   = mean(PP_Bike$Calories, na.rm = T),
    col = alpha(cols[cc], 0.7),
    lty = 3,
    lwd = 2
  )
  text(
    x      = last(PP_Bike$date),
    y      = mean(PP_Bike$Calories, na.rm = T),
    labels = round(mean(PP_Bike$Calories, na.rm = T)),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )
  mtext(
    "Weekly Calories",
    side = 4,
    line = 2,
    col  = 1,
    cex  = 0.7
  )
  axis(
    side     = 4,
    at       = pretty(range(c(PP_Run$Calories, PP_Bike$Calories), na.rm = T)),
    cex.axis = cex,
    col.axis = 1
  )


  ## cumulative calories
  par(new = TRUE)
  plot(
    PP_Bike[!is.na(Cum_Calo), Cum_Calo, date],
    "s",
    xlab     = "",
    ylab     = "",
    cex.axis = cex,
    bty      = "n",
    lwd      = 3,
    col      = alpha(cols[cc], 0.7),
    col.axis = 1,
    xlim     = xlim,
    ylim     = ylimD
  )
  ## current line
  endp <- last(PP_Bike[!is.na(Cum_Calo), Cum_Calo, date])
  lines(x   = c(endp$date, as.Date(paste0(year(endp$date),"-12-31"))),
        y   = c(endp$Cum_Calo, endp$Cum_Calo), lty = 2, lwd = 1,
        col = alpha(cols[cc], 0.7))
  text(
    x      = as.Date(paste0(year(endp$date),"-12-31")),
    y      = endp$Cum_Calo,
    labels = round(endp$Cum_Calo),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )

  axis(
    side = 1,
    at = pretty(range(c(PP_Run$Cum_Calo, PP_Bike$Cum_Calo), na.rm = T)),
    cex.axis = cex,
    col.axis = cols[cc]
  )
  mtext(
    "Total Calories",
    side = 2,
    line = 2,
    col = 1,
    cex = 0.7
  )

  ## lm line
  lines(
    PP_Bike[, Pre_Calo, date],
    lwd = 3,
    col = alpha(cols[cc], 0.7),
    lty = 3
  )
  text(
    x      = last(PP_Bike$date),
    y      = last(PP_Bike$Pre_Calo),
    labels = round(last(PP_Run$Pre_Calo)),
    pos    = 4,
    col    = alpha(cols[cc], 0.7)
  )




  ## _ Run  --------------------------------------------------------------------

  ## week distance
  par(new = TRUE)
  cc <- 11
  plot(
    PP_Run$date,
    PP_Run$Calories,
    "h",
    xlab     = "",
    ylab     = "",
    axes     = FALSE,
    bty      = "n",
    cex.axis = cex,
    lwd      = 4,
    col      = alpha(cols[cc], 0.7),
    xlim     = xlim,
    ylim     = c(ylimW[1], ylimW[2] * 1.1 )
  )

  abline(
    h   = mean(PP_Run$Calories, na.rm = T),
    col = alpha(cols[cc], 0.7),
    lty = 3,
    lwd = 2
  )
  text(
    x      = last(PP_Bike$date),
    y      = mean(PP_Run$Calories, na.rm = T),
    labels = round(mean(PP_Run$Calories, na.rm = T)),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )

  ## cumulative calories
  par(new = TRUE)
  plot(
    PP_Run[!is.na(Cum_Calo), Cum_Calo, date],
    "s",
    xlab     = "",
    ylab     = "",
    cex.axis = cex,
    lwd      = 3,
    bty      = "n",
    col      = alpha(cols[cc], 0.7),
    col.axis = 1,
    xlim     = xlim,
    ylim     = ylimD
  )
  ## current line
  endp <- last(PP_Run[!is.na(Cum_Calo), Cum_Calo, date])
  lines(x   = c(endp$date, as.Date(paste0(year(endp$date),"-12-31"))),
        y   = c(endp$Cum_Calo, endp$Cum_Calo), lty = 2, lwd = 1,
        col = alpha(cols[cc], 0.7))
  text(
    x      = as.Date(paste0(year(endp$date),"-12-31")),
    y      = endp$Cum_Calo,
    labels = round(endp$Cum_Calo),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )




  ## lm line
  lines(
    PP_Run[, Pre_Calo, date],
    lwd = 3,
    col = alpha(cols[cc], 0.7),
    lty = 3
  )
  text(
    x      = last(PP_Run$date),
    y      = last(PP_Run$Pre_Calo),
    labels = round(last(PP_Run$Pre_Calo)),
    pos    = 4,
    col    = alpha(cols[cc], 0.7)
  )

  ## current
  cc <- 3
  abline(
    v   = Sys.Date(),
    lty = 3,
    lwd = 3,
    col = alpha(cols[cc], 0.7)
  )
}


####_ END _####
tac <- Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
