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
    sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)
}


metrics <- readRDS("~/LOGs/GCmetrics.Rds")
sort(unique(metrics$Shoes))


####  Copy from GC below  ####################################################

cat(paste(sort(unique(metrics$Shoes)), colapse = "\n"),
    "~/LOGs/Shoes.list")


library(data.table)
library(randomcoloR)

cex <- 0.7

## exclude non meaning
ddd <- metrics[metrics$Shoes != "Multi", ]
ddd <- ddd[ddd$Shoes != "?", ]

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
            temp <- plyr::rbind.fill(text,temp)
            temp <- temp[order(temp$date), ]
        }
        gather <- plyr::rbind.fill(gather, temp)
    }
}


## agreggate
gather <- data.table(gather)


agg  <- gather[, .(Distance = sum(Distance)), by = .(year(date), month(date), Shoes)]
n    <- length(unique(gather$Shoes))
cols <- distinctColorPalette(n)

agg$date <- as.Date(paste(agg$year,agg$month, "1"), format = "%Y %m %d" )






gath <- data.table()
for (as in unique(agg$Shoes)) {
    temp <- agg[Shoes == as]
    setorder(temp,date)
    temp[,total := cumsum(Distance) ]
    gath <- rbind(gath,temp)
}

gath$total <- round( gath$total, 0)

xlim <- range(gath$date, na.rm = T)
ylim <- range(0,gath$total, na.rm = T)


plot(1, type="n",
     xlab = "", ylab = "km",
     xlim = xlim, ylim = ylim,
     xaxt='n',
     cex.axis = cex)
axis.Date(1,agg$date)
axis.Date(1,at = seq(min(agg$date), max(agg$date)+1, "months"),
          labels = FALSE, tcl = -0.2)


sn <- c()
sc <- c()
cc <- 1
for (as in sort(unique(gath$Shoes))) {
    temp <- gath[gath$Shoes==as,]
    lines(temp$date, temp$total, col = cols[cc], lwd = 4, type = "s" )
    text(temp$date[which.max(temp$total)], max(temp$total), labels = paste(as,"\n" ,round(max(temp$total),0)),pos = 3, cex = cex  )
    sn <- c(sn, paste0(as," (",round(max(temp$total),0),"km)" ) )
    sc <- c(sc,cols[cc])
    cc <- cc+1
}
legend("topleft", legend = sn, col = sc, bty = "n", pch = 19, cex = cex)





####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
