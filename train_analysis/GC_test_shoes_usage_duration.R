#!/usr/bin/env Rscript

#### Golden Cheetah plot shoes usage total duration vs total distance
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
metrics <- readRDS("~/LOGs/GCmetrics.Rds")



####  Copy for GC below  ####################################################

library(data.table)
library(randomcoloR)

metrics <- data.table(metrics)
gdata::write.fwf(metrics[, .(Dist = round(sum(Distance),1),
                             From = min(date),
                             To   = max(date),
                             Active = difftime(max(date),min(date))), by = Shoes],
                 file = "~/TRAIN/Shoes.list", colnames = F)

## plot params
cex <- 0.7


## exclude non meaning
ddd   <- metrics[metrics$Shoes != "Multi", ]
empty <- ddd[ ddd$Shoes == "?" | ddd$Shoes == ""  , ]
ddd   <- ddd[ddd$Shoes != "?", ]
ddd   <- ddd[ddd$Shoes != "", ]

empty  <- empty[empty$Sport == "Run",]
emtpyD <- sum(empty$Distance,na.rm = T)

## get external data
extra <- read.delim("~/TRAIN/Shoes.csv",
                    comment.char = '#',
                    sep = ";",
                    strip.white = T)
extra$date     <- as.Date(extra$date)
extra$Distance <- as.numeric(extra$Distance)


## get days of usage
gather <- data.frame()
for (as in unique(ddd$Shoes)) {
    temp <-   ddd[ddd$Shoes==as,]
    text <- extra[extra$Shoes==as,]
    if (nrow(temp)>0) {
        ## insert extra data
        if (nrow(text)>0) {
            text$date[is.na(text$date)] <- min(temp$date,text$date,na.rm = T)
            ## is retired
            if (any(text$Status == "End")) {
                ## sanity checks
                stopifnot( text$Status[which.max(text$date)] == "End" )
                stopifnot(max(text$date) >= max(temp$date))
                ## move End day after last usage
                text$date[which.max(text$date)] <- temp$date[which.max(temp$date)] + 1
            }
            temp <- plyr::rbind.fill(text,temp)
            temp <- temp[order(temp$date), ]
        }
        ## aa day
        temp$nday <- temp$date - min(temp$date)
        ## cumsum
        temp$total <- cumsum( temp$Distance )
        ## retired
        temp$total[temp$Status == "End"] <- 0
        ## test shoe line
        temp[ , c("date", "total", "Distance")]
        # plot(temp$date, temp$total)
        ## gather for plotting
        gather <- plyr::rbind.fill(gather, temp)
    }
}



## init empty plot
xlim <- range(gather$nday, max(gather$nday) + 7 , na.rm = T)
ylim <- range(0,gather$total * 1.05, na.rm = T)
plot(1, type="n",
     xlab = "Days of usage",
     ylab = "km",
     xlim = xlim, ylim = ylim,
     cex.axis = cex)

## create color palete
n      <- length(unique(gather$Shoes))
cols   <- distinctColorPalette(n)

## add lines to plot
sn   <- c()
sc   <- c()
cc <- 1
for (as in sort(unique(gather$Shoes))) {
    temp <- gather[gather$Shoes==as,]
    lines(temp$nday, temp$total, col = cols[cc], lwd = 4, type = "s" )
    model <- gsub("^.*-[ ]+", "", as)
    text(temp$nday[which.max(temp$total)], max(temp$total),
         labels = paste(model,"\n", round(max(temp$total),0)),
         pos = 3, cex = cex * 0.8  )
    sn <- c(sn, paste0(as," (",round(max(temp$total),0),"km)" ) )
    sc <- c(sc,cols[cc])
    cc <- cc+1
}

## add legend
sn <- c(sn, paste0("NO ENTRY (", round(emtpyD,0),"km)"))
sc <- c(sc, NA)
legend("topleft", legend = sn, col = sc, bty = "n", pch = 19, cex = cex)







####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
