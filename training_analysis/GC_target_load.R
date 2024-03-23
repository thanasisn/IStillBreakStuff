#!/usr/bin/env Rscript

#### Golden Cheetah plot training load yearly summary

## Used inside Golden Cheetah software

####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/training_analysis/GC_target_load.R"

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

cols <- c(
  "#f22e2e", "#d9b629", "#30ff83", "#3083ff", "#f22ee5", "#33161e", "#e6a89e",
  "#bbbf84", "#1d995f", "#324473", "#cc8dc8", "#59111b", "#b25c22", "#b1f22e",
  "#9ee6d7", "#482ef2", "#66465b", "#33200a", "#385911", "#24a0bf", "#270f4d",
  "#731647", "#664a13", "#414d35", "#22444d", "#6b1880", "#ff70a9")

## plot params
cex <- 1



## for all years
years <- sort(unique(year(metrics$Date)), decreasing = T)

for (ay in years) {

  ## aggregate data for load estimation
  temp <- metrics[year(Date) == ay, ]
  data <- temp[year(Date) == ay,
                  .(TRIMP_Points       = sum(Trimp_Points,       na.rm = T),
                    TRIMP_Zonal_Points = sum(Trimp_Zonal_Points, na.rm = T),
                    TriScore           = sum(Triscore,           na.rm = T),
                    EPOC               = sum(EPOC,               na.rm = T),
                    Descent            = sum(Elevation_Loss,     na.rm = T)),
                  by = .(date = as.Date((as.numeric(as.Date(Date)) %/% 7) * 7, origin = "1970-01-01")) ]

  lastdate <- as.Date( paste0(year(max(data$date)),"-12-31") )


  ## prepare data to plot
  data[ , Cum_Dist := cumsum(TRIMP_Points ) ]
  data[ , Cum_Dura := cumsum(TRIMP_Zonal_Points ) ]
  data[ , Cum_Asce := cumsum(TriScore   ) ]
  data[ , Cum_Desc := cumsum(Descent    ) ]
  data[ , Cum_EPOC := cumsum(EPOC       ) ]

  ## predict
  lmDist <- lm(Cum_Dist ~ as.numeric(date), data)
  lmDura <- lm(Cum_Dura ~ as.numeric(date), data)
  lmAsce <- lm(Cum_Asce ~ as.numeric(date), data)
  lmDesc <- lm(Cum_Desc ~ as.numeric(date), data)
  lmEPOC <- lm(Cum_EPOC ~ as.numeric(date), data)


  alw <- seq(min(data$date), lastdate, by = "week")
  alw <- data.frame(date = alw)

  alw$Pred_Dist <- predict(lmDist, alw)
  alw$Pred_Dura <- predict(lmDura, alw)
  alw$Pred_Asce <- predict(lmAsce, alw)
  alw$Pred_Desc <- predict(lmDesc, alw)
  alw$Pred_EPOC <- predict(lmEPOC, alw)


  ## plots
  layout(matrix(c(1,2,3), 3, 1, byrow = TRUE))

  xlim <- range(data$date, lastdate, na.rm = T)
  par(mar = c(2,3,1,3))
  par(xpd = TRUE)


  ## TRIMP_Points plot  --------------------------------------------------------

  ## week TRIMP_Points
  cc <- 4
  ylim <- range(0, data$TRIMP_Points, na.rm = T)
  plot(data$date, data$TRIMP_Points, "h",
       xlab = "", ylab = "", axes = FALSE, bty = "n",
       cex.axis = cex, lwd = 4, col = alpha(cols[cc], 0.7),
       xlim = xlim, ylim = c(ylim[1], ylim[2]*2 ) )
  axis(side=4, at = pretty(range(data$TRIMP_Points)),
       cex.axis = cex, col.axis = cols[cc] )
  mtext("Weekly TRIMP_Points", side = 4, line = 2, col = cols[cc])

  ## mean line
  abline(h = mean(data$TRIMP_Points, na.rm = T),
         col = alpha(cols[cc], 0.7), lty = 3, lwd = 2)
  text(
    x      = last(data$date) + 9,
    y      = mean(data$TRIMP_Points, na.rm = T),
    labels = round(mean(data$TRIMP_Points, na.rm = T)),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )


  title(ay)

  ## cumulative TRIMP_Points
  par(new = TRUE)
  cc <- 1
  ylim <- range(0, data$Cum_Dist, alw$Pred_Dist, na.rm = T)
  plot(data$date, data$Cum_Dist, "s",
       xlab = "", ylab = "",
       cex.axis = cex, lwd = 3, col = alpha(cols[cc], 0.7),
       col.axis = cols[cc],
       xlim = xlim, ylim = ylim)
  mtext("TRIMP_Points", side = 2, line = 2, col = cols[cc])
  ## current line
  endp <- last(data[!is.na(Cum_Dist), Cum_Dist, date])
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
  cc <- 2
  lines( alw$date, alw$Pred_Dist,
         lwd = 3, col = alpha(cols[cc], 0.7)  )
  text( x = last(alw$date), y = last(alw$Pred_Dist), labels = round(last(alw$Pred_Dist)),
        pos = 4, col = alpha(cols[cc], 0.7)    )

  ## current
  cc <- 3
  abline(v = Sys.Date(),
         lty = 3, lwd = 3, col = alpha(cols[cc], 0.7) )


  # ## TriScore plot ####
  #
  # ## week TriScore
  # cc <- 7
  # ylim <- range(data$TriScore, na.rm = T)
  # plot(data$date, data$TriScore, "h",
  #      xlab = "", ylab = "", axes = FALSE, bty = "n",
  #      cex.axis = cex, lwd = 4, col = alpha(cols[cc], 0.7),
  #      xlim = xlim, ylim = c(ylim[1], ylim[2]*2 ) )
  # axis(side=4, at = pretty(range(data$TriScore)),
  #      cex.axis = cex, col.axis = cols[cc] )
  # mtext("Weekly TriScore ", side=4, line = 2, col = cols[cc])
  # abline(h = mean(data$TriScore, na.rm = T),
  #        col = alpha(cols[cc], 0.7), lty = 3, lwd = 2)
  #
  #
  # ## cumulative TriScore
  # par(new=TRUE)
  # cc <- 5
  # ylim <- range(data$Cum_TriScore, alw$Pred_TriScore, na.rm = T)
  # plot(data$date, data$Cum_TriScore, "s",
  #      xlab = "", ylab = "",
  #      cex.axis = cex, lwd = 3, col = alpha(cols[cc], 0.7),
  #      col.axis = cols[cc],
  #      xlim = xlim, ylim = ylim)
  # mtext("TriScore", side=2, line=2, col = cols[cc])
  #
  # ## lm line
  # cc <- 13
  # lines( alw$date, alw$Pred_TriScore,
  #        lwd = 3, col = alpha(cols[cc], 0.7)  )
  # text( x = last(alw$date), y = last(alw$Pred_TriScore), labels = round(last(alw$Pred_TriScore)),
  #       pos = 4, col = alpha(cols[cc], 0.7)    )
  #
  # ## current
  # cc <- 3
  # abline(v = Sys.Date(),
  #        lty = 3, lwd = 3, col = alpha(cols[cc], 0.7) )



  ## EPOC plot  ----------------------------------------------------------------

  ## week EPOC
  cc <- 7
  ylim <- range(0, data$EPOC, na.rm = T)
  plot(data$date, data$EPOC, "h",
       xlab = "", ylab = "", axes = FALSE, bty = "n",
       cex.axis = cex, lwd = 4, col = alpha(cols[cc], 0.7),
       xlim = xlim, ylim = c(ylim[1], ylim[2]*2 ) )
  axis(side=4, at = pretty(range(data$EPOC)),
       cex.axis = cex, col.axis = cols[cc] )
  mtext("Weekly EPOC ", side=4, line = 2, col = cols[cc])

  ## mean line
  abline(h = mean(data$EPOC, na.rm = T),
         col = alpha(cols[cc], 0.7), lty = 3, lwd = 2)
  text(
    x      = last(data$date) + 9,
    y      = mean(data$EPOC, na.rm = T),
    labels = round(mean(data$EPOC, na.rm = T)),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )


  ## cumulative EPOC
  par(new=TRUE)
  cc <- 5
  ylim <- range(0, data$Cum_EPOC, alw$Pred_EPOC, na.rm = T)
  plot(data$date, data$Cum_EPOC, "s",
       xlab = "", ylab = "",
       cex.axis = cex, lwd = 3, col = alpha(cols[cc], 0.7),
       col.axis = cols[cc],
       xlim = xlim, ylim = ylim)
  mtext("EPOC", side = 2, line = 2, col = cols[cc])
  ## current line
  endp <- last(data[!is.na(Cum_EPOC), Cum_EPOC, date])
  lines(x   = c(endp$date, as.Date(paste0(year(endp$date),"-12-31"))),
        y   = c(endp$Cum_EPOC, endp$Cum_EPOC), lty = 2, lwd = 1,
        col = alpha(cols[cc], 0.7))
  text(
    x      = as.Date(paste0(year(endp$date),"-12-31")),
    y      = endp$Cum_EPOC,
    labels = round(endp$Cum_EPOC),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )

  ## lm line
  cc <- 13
  lines( alw$date, alw$Pred_EPOC,
         lwd = 3, col = alpha(cols[cc], 0.7)  )
  text( x = last(alw$date), y = last(alw$Pred_EPOC), labels = round(last(alw$Pred_EPOC)),
        pos = 4, col = alpha(cols[cc], 0.7)    )

  ## current
  cc <- 3
  abline(v = Sys.Date(),
         lty = 3, lwd = 3, col = alpha(cols[cc], 0.7) )




  ## TRIMP_Zonal_Points plot  --------------------------------------------------

  ## week TRIMP_Zonal_Points
  cc <- 8
  ylim <- range(0, data$TRIMP_Zonal_Points, na.rm = T)
  plot(data$date, data$TRIMP_Zonal_Points, "h",
       xlab = "", ylab = "", axes = FALSE, bty = "n",
       cex.axis = cex, lwd = 4, col = alpha(cols[cc], 0.7),
       xlim = xlim, ylim = c(ylim[1], ylim[2]*2 ) )
  axis(side=4, at = pretty(range(data$TRIMP_Zonal_Points)),
       cex.axis = cex, col.axis = cols[cc] )
  mtext("Weekly TRIMP_Zonal_Points", side=4, line = 2, col = cols[cc])

  ## mean line
  abline(h = mean(data$TRIMP_Zonal_Points, na.rm = T),
         col = alpha(cols[cc], 0.7), lty = 3, lwd = 2)
  text(
    x      = last(data$date) + 9,
    y      = mean(data$TRIMP_Zonal_Points, na.rm = T),
    labels = round(mean(data$TRIMP_Zonal_Points, na.rm = T)),
    pos    = 3,
    col    = alpha(cols[cc], 0.7)
  )



  ## cumulative TRIMP_Zonal_Points
  par(new=TRUE)
  cc <- 10
  ylim <- range(0, data$Cum_Dura, alw$Pred_Dura, na.rm = T)
  plot(data$date, data$Cum_Dura, "s",
       xlab = "", ylab = "",
       cex.axis = cex, lwd = 3, col = alpha(cols[cc], 0.7),
       col.axis = cols[cc],
       xlim = xlim, ylim = ylim)
  mtext("TRIMP_Zonal_Points", side=2, line=2, col = cols[cc])
  ## current line
  endp <- last(data[!is.na(Cum_Dura), Cum_Dura, date])
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
  cc <- 11
  lines( alw$date, alw$Pred_Dura,
         lwd = 3, col = alpha(cols[cc], 0.7)  )
  text( x = last(alw$date), y = last(alw$Pred_Dura), labels = round(last(alw$Pred_Dura)),
        pos = 4, col = alpha(cols[cc], 0.7)    )

  ## current
  cc <- 3
  abline(v = Sys.Date(),
         lty = 3, lwd = 3, col = alpha(cols[cc], 0.7) )

}


####_ END _####
tac <- Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
