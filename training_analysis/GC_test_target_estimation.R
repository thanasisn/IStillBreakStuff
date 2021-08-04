#!/usr/bin/env Rscript

#### Golden Cheetah plot shoes usage total distance vs time
## Used inside Golden Cheetah software
## Plot a line for each shoe usage


####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()
if(!interactive()) {
    pdf(file=sub("\\.R$",".pdf",Script.Name))
    sink(file=sub("\\.R$",".out",Script.Name),split=TRUE)
}

## save in goldencheetah
# metrics <- GC.metrics(all=TRUE)
# saveRDS(metrics, "~/LOGs/GCmetrics.Rds")

## load outside goldencheetah
metrics <- readRDS("~/LOGs/GCmetrics_selection.Rds")
source("~/FUNCTIONS/R/data.R")
metrics <- rm.cols.dups.df(metrics)



####  Copy for GC below  ####################################################


library(data.table)
library(scales)

# This crushes version 3.6-DRV2006 of goldenchretah
# library(randomcoloR)

cols <- c("#f22e2e", "#d9b629", "#30ff83", "#3083ff", "#f22ee5", "#33161e", "#e6a89e", "#bbbf84", "#1d995f", "#324473", "#cc8dc8", "#59111b", "#b25c22", "#b1f22e", "#9ee6d7", "#482ef2", "#66465b", "#33200a", "#385911", "#24a0bf", "#270f4d", "#731647", "#664a13", "#414d35", "#22444d", "#6b1880", "#ff70a9")

metrics <- data.table(metrics)

## keep only "on feet" data
if ( !is.null(metrics$Sport)) {
    metrics <-metrics[metrics$Sport == "Run",]
}

## plot params
cex <- 1




## aggregate data for load estimation
metrics[, Duration := Duration / 3600 ]
data <- metrics[ , .(Distance = sum(Distance,       na.rm = T),
                     Duration = sum(Duration,       na.rm = T),
                     Ascent   = sum(Elevation_Gain, na.rm = T),
                     Descent  = sum(Elevation_Loss, na.rm = T)),
                 by = .(date = as.Date((as.numeric(metrics$date) %/% 7) * 7, origin = "1970-01-01")) ]

lastdate <- as.Date( paste0(year(max(data$date)),"-12-31") )

## prepare data to plot
data[ , Cum_Dist := cumsum( Distance ) ]
data[ , Cum_Dura := cumsum( Duration ) ]
data[ , Cum_Asce := cumsum( Ascent   ) ]
data[ , Cum_Desc := cumsum( Descent  ) ]

## predict
lmDist <- lm(Cum_Dist ~ as.numeric(date), data)
lmDura <- lm(Cum_Dura ~ as.numeric(date), data)
lmAsce <- lm(Cum_Asce ~ as.numeric(date), data)
lmDesc <- lm(Cum_Desc ~ as.numeric(date), data)


alw <- seq(min(data$date), lastdate, by = "week")
alw <- data.frame(date = alw)

alw$Pred_Dist <- predict(lmDist, alw)
alw$Pred_Dura <- predict(lmDura, alw)
alw$Pred_Asce <- predict(lmAsce, alw)
alw$Pred_Desc <- predict(lmDesc, alw)


## plots
layout(matrix(c(1,1,2,3), 4, 1, byrow = TRUE))

xlim <- range(data$date,lastdate, na.rm = T)
par(mar = c(2,3,1,3))
par(xpd = TRUE)


## Distance plot ####

## week distance
cc <- 4
ylim <- range(data$Distance, na.rm = T)
plot(data$date, data$Distance, "h",
     xlab = "", ylab = "", axes = FALSE, bty = "n",
     cex.axis = cex, lwd = 4, col = alpha(cols[cc], 0.7),
     xlim = xlim, ylim = c(ylim[1], ylim[2]*2 ) )
axis(side=4, at = pretty(range(data$Distance)),
     cex.axis = cex, col.axis = cols[cc] )
mtext("Weekly Distance", side = 4, line = 2, col = cols[cc])
abline(h = mean(data$Distance, na.rm = T),
       col = alpha(cols[cc], 0.7), lty = 3, lwd = 2)

## cumulative distance
par(new=TRUE)
cc <- 1
ylim <- range(data$Cum_Dist, alw$Pred_Dist, na.rm = T)
plot(data$date, data$Cum_Dist, "s",
     xlab = "", ylab = "",
     cex.axis = cex, lwd = 3, col = alpha(cols[cc], 0.7),
     col.axis = cols[cc],
     xlim = xlim, ylim = ylim)
mtext("Distance", side = 2, line = 2, col = cols[cc])

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






## Ascent plot ####

## week Ascent
cc <- 7
ylim <- range(data$Ascent, na.rm = T)
plot(data$date, data$Ascent, "h",
     xlab = "", ylab = "", axes = FALSE, bty = "n",
     cex.axis = cex, lwd = 4, col = alpha(cols[cc], 0.7),
     xlim = xlim, ylim = c(ylim[1], ylim[2]*2 ) )
axis(side=4, at = pretty(range(data$Ascent)),
     cex.axis = cex, col.axis = cols[cc] )
mtext("Weekly Ascent ", side=4, line = 2, col = cols[cc])
abline(h = mean(data$Ascent, na.rm = T),
       col = alpha(cols[cc], 0.7), lty = 3, lwd = 2)


## cumulative Ascent
par(new=TRUE)
cc <- 5
ylim <- range(data$Cum_Asce, alw$Pred_Asce, na.rm = T)
plot(data$date, data$Cum_Asce, "s",
     xlab = "", ylab = "",
     cex.axis = cex, lwd = 3, col = alpha(cols[cc], 0.7),
     col.axis = cols[cc],
     xlim = xlim, ylim = ylim)
mtext("Ascent", side=2, line=2, col = cols[cc])

## lm line
cc <- 13
lines( alw$date, alw$Pred_Asce,
       lwd = 3, col = alpha(cols[cc], 0.7)  )
text( x = last(alw$date), y = last(alw$Pred_Asce), labels = round(last(alw$Pred_Asce)),
      pos = 4, col = alpha(cols[cc], 0.7)    )

## current
cc <- 3
abline(v = Sys.Date(),
       lty = 3, lwd = 3, col = alpha(cols[cc], 0.7) )






## Duration plot ####

## week duration
cc <- 8
ylim <- range(data$Duration, na.rm = T)
plot(data$date, data$Duration, "h",
     xlab = "", ylab = "", axes = FALSE, bty = "n",
     cex.axis = cex, lwd = 4, col = alpha(cols[cc], 0.7),
     xlim = xlim, ylim = c(ylim[1], ylim[2]*2 ) )
axis(side=4, at = pretty(range(data$Duration)),
     cex.axis = cex, col.axis = cols[cc] )
mtext("Weekly Duration", side=4, line = 2, col = cols[cc])
abline(h = mean(data$Duration, na.rm = T),
       col = alpha(cols[cc], 0.7), lty = 3, lwd = 2)

## cumulative Duration
par(new=TRUE)
cc <- 10
ylim <- range(data$Cum_Dura, alw$Pred_Dura, na.rm = T)
plot(data$date, data$Cum_Dura, "s",
     xlab = "", ylab = "",
     cex.axis = cex, lwd = 3, col = alpha(cols[cc], 0.7),
     col.axis = cols[cc],
     xlim = xlim, ylim = ylim)
mtext("Duration", side=2, line=2, col = cols[cc])

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







####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
