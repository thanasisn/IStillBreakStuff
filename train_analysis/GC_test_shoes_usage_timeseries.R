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

## load ouside goldencheetah
metrics <- readRDS("~/LOGs/GCmetrics.Rds")



####  Copy for GC below  ####################################################

cat(paste(sort(unique(metrics$Shoes)), colapse = "\n"),
    "~/TRAIN/Shoes.list")


library(data.table)
library(randomcoloR)

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
        gather <- plyr::rbind.fill(gather, temp)
    }
}



## aggregate for plot
gather <- data.table(gather)

agg       <- gather[, .(Distance = sum(Distance)), by = .(year(date), month(date), Shoes)]
agg$date  <- as.Date(paste(agg$year,agg$month, "1"), format = "%Y %m %d" )
aggD      <- gather[, .(Distance = sum(Distance)), by = .(date = as.Date(date), Shoes)]

## for daily steps
# agg <- aggD




## compute cumulative sums
gath <- data.table()
for (as in unique(agg$Shoes)) {
    temp <- agg[Shoes == as]
    setorder(temp,date)
    temp[,total := cumsum(Distance) ]
    gath <- rbind(gath,temp)
}

## pretty numbers
gath$total <- round( gath$total, 0)


## init empty plot
xlim <- range(gath$date, Sys.Date() + 7 , na.rm = T)
ylim <- range(0,gath$total * 1.05 , na.rm = T)
plot(1, type="n",
     xlab = "",
     ylab = "km",
     xlim = xlim, ylim = ylim,
     xaxt='n',
     cex.axis = cex)
axis.Date(1,agg$date)
axis.Date(1,at = seq(min(agg$date), max(agg$date)+1, "months"),
          labels = FALSE, tcl = -0.2)

## create color palete
n      <- length(unique(gather$Shoes))
cols   <- distinctColorPalette(n)

## add lines to plot
sn <- c()
sc <- c()
cc <- 1
for (as in sort(unique(gath$Shoes))) {
    temp <- gath[gath$Shoes==as,]
    lines(temp$date, temp$total, col = cols[cc], lwd = 4, type = "s" )
    model <- gsub("^.*-[ ]+", "", as)
    text(temp$date[which.max(temp$total)], max(temp$total),
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
