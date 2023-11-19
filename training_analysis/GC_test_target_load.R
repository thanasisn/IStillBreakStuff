#!/usr/bin/env Rscript

#### Golden Cheetah plot training load yearly summary

## Used inside Golden Cheetah software


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
# metrics <- readRDS("~/LOGs/GCmetrics_selection.Rds")

metrics <- readRDS("~/DATA/Other/Train_metrics.Rds")
source("~/FUNCTIONS/R/data.R")
# metrics <- rm.cols.dups.df(metrics)



####  Copy for GC below  ####################################################

daysback    <- 365

library(data.table)
library(scales)

# This crushes version 3.6-DRV2006 of goldenchretah
# library(randomcoloR)

cols <- c("#f22e2e", "#d9b629", "#30ff83", "#3083ff", "#f22ee5", "#33161e", "#e6a89e", "#bbbf84", "#1d995f", "#324473", "#cc8dc8", "#59111b", "#b25c22", "#b1f22e", "#9ee6d7", "#482ef2", "#66465b", "#33200a", "#385911", "#24a0bf", "#270f4d", "#731647", "#664a13", "#414d35", "#22444d", "#6b1880", "#ff70a9")

metrics <- data.table(metrics)

metrics <- metrics[date > Sys.Date() - daysback, ]

## keep only "on feet" data
# if ( !is.null(metrics$Sport)) {
    # metrics <- metrics[metrics$Sport == "Run",]
# }

## plot params
cex <- 1

sort(names(metrics))

#TODO "EPOC"

## aggregate data for load estimation
# metrics[, TRIMP_Zonal_Points := TRIMP_Zonal_Points / 3600 ]
data <- metrics[ , .(TRIMP_Points       = sum(TRIMP_Points,       na.rm = T),
                     TRIMP_Zonal_Points = sum(TRIMP_Zonal_Points, na.rm = T),
                     TriScore           = sum(TriScore,           na.rm = T),
                     EPOC               = sum(EPOC,               na.rm = T),
                     Descent            = sum(Elevation_Loss,     na.rm = T)),
                 by = .(date = as.Date((as.numeric(metrics$date) %/% 7) * 7, origin = "1970-01-01")) ]

lastdate <- as.Date( paste0(year(max(data$date)),"-12-31") )

## prepare data to plot
data[ , Cum_Dist := cumsum( TRIMP_Points ) ]
data[ , Cum_Dura := cumsum( TRIMP_Zonal_Points ) ]
data[ , Cum_Asce := cumsum( TriScore   ) ]
data[ , Cum_Desc := cumsum( Descent    ) ]
data[ , Cum_EPOC := cumsum( EPOC       ) ]

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

xlim <- range(data$date,lastdate, na.rm = T)
par(mar = c(2,3,1,3))
par(xpd = TRUE)


## TRIMP_Points plot ####

## week TRIMP_Points
cc <- 4
ylim <- range(data$TRIMP_Points, na.rm = T)
plot(data$date, data$TRIMP_Points, "h",
     xlab = "", ylab = "", axes = FALSE, bty = "n",
     cex.axis = cex, lwd = 4, col = alpha(cols[cc], 0.7),
     xlim = xlim, ylim = c(ylim[1], ylim[2]*2 ) )
axis(side=4, at = pretty(range(data$TRIMP_Points)),
     cex.axis = cex, col.axis = cols[cc] )
mtext("Weekly TRIMP_Points", side = 4, line = 2, col = cols[cc])
abline(h = mean(data$TRIMP_Points, na.rm = T),
       col = alpha(cols[cc], 0.7), lty = 3, lwd = 2)

## cumulative TRIMP_Points
par(new=TRUE)
cc <- 1
ylim <- range(data$Cum_Dist, alw$Pred_Dist, na.rm = T)
plot(data$date, data$Cum_Dist, "s",
     xlab = "", ylab = "",
     cex.axis = cex, lwd = 3, col = alpha(cols[cc], 0.7),
     col.axis = cols[cc],
     xlim = xlim, ylim = ylim)
mtext("TRIMP_Points", side = 2, line = 2, col = cols[cc])

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



## EPOC plot ####

## week EPOC
cc <- 7
ylim <- range(data$EPOC, na.rm = T)
plot(data$date, data$EPOC, "h",
     xlab = "", ylab = "", axes = FALSE, bty = "n",
     cex.axis = cex, lwd = 4, col = alpha(cols[cc], 0.7),
     xlim = xlim, ylim = c(ylim[1], ylim[2]*2 ) )
axis(side=4, at = pretty(range(data$EPOC)),
     cex.axis = cex, col.axis = cols[cc] )
mtext("Weekly EPOC ", side=4, line = 2, col = cols[cc])
abline(h = mean(data$EPOC, na.rm = T),
       col = alpha(cols[cc], 0.7), lty = 3, lwd = 2)


## cumulative EPOC
par(new=TRUE)
cc <- 5
ylim <- range(data$Cum_EPOC, alw$Pred_EPOC, na.rm = T)
plot(data$date, data$Cum_EPOC, "s",
     xlab = "", ylab = "",
     cex.axis = cex, lwd = 3, col = alpha(cols[cc], 0.7),
     col.axis = cols[cc],
     xlim = xlim, ylim = ylim)
mtext("EPOC", side=2, line=2, col = cols[cc])

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









## TRIMP_Zonal_Points plot ####

## week TRIMP_Zonal_Points
cc <- 8
ylim <- range(data$TRIMP_Zonal_Points, na.rm = T)
plot(data$date, data$TRIMP_Zonal_Points, "h",
     xlab = "", ylab = "", axes = FALSE, bty = "n",
     cex.axis = cex, lwd = 4, col = alpha(cols[cc], 0.7),
     xlim = xlim, ylim = c(ylim[1], ylim[2]*2 ) )
axis(side=4, at = pretty(range(data$TRIMP_Zonal_Points)),
     cex.axis = cex, col.axis = cols[cc] )
mtext("Weekly TRIMP_Zonal_Points", side=4, line = 2, col = cols[cc])
abline(h = mean(data$TRIMP_Zonal_Points, na.rm = T),
       col = alpha(cols[cc], 0.7), lty = 3, lwd = 2)

## cumulative TRIMP_Zonal_Points
par(new=TRUE)
cc <- 10
ylim <- range(data$Cum_Dura, alw$Pred_Dura, na.rm = T)
plot(data$date, data$Cum_Dura, "s",
     xlab = "", ylab = "",
     cex.axis = cex, lwd = 3, col = alpha(cols[cc], 0.7),
     col.axis = cols[cc],
     xlim = xlim, ylim = ylim)
mtext("TRIMP_Zonal_Points", side=2, line=2, col = cols[cc])

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
