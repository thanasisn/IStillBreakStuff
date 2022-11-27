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
metrics <- readRDS("~/LOGs/GCmetrics.Rds")



####  Copy for GC below  ####################################################


library(data.table)

# This crushes version 3.6-DRV2006 of goldenchretah
# library(randomcoloR)

cols <- c("#f22e2e", "#d9b629", "#30ff83", "#3083ff", "#f22ee5", "#33161e", "#e6a89e", "#bbbf84", "#1d995f", "#324473", "#cc8dc8", "#59111b", "#b25c22", "#b1f22e", "#9ee6d7", "#482ef2", "#66465b", "#33200a", "#385911", "#24a0bf", "#270f4d", "#731647", "#664a13", "#414d35", "#22444d", "#6b1880", "#ff70a9")

metrics <- data.table(metrics)

## export shoes lists
summdt <- metrics[, .(Dist = round(sum(Distance),1),
                      From = min(date),
                      To   = max(date),
                      Active = difftime(max(date),min(date))), by = Shoes]
vars <- names(summdt)
for (avar in vars) {
    gdata::write.fwf(summdt[order(summdt[[avar]])],
                     file = paste0("~/TRAIN/Shoes_by_",avar,".list"),
                     colnames = F)
}



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
gather    <- data.table(gather)

## for daily steps
aggD      <- gather[, .(Distance = sum(Distance)), by = .(date = as.Date(date), Shoes)]
agg <- aggD



agg[ Distance>0, Use := (factor(Shoes)) ]
agg$Use <- as.numeric( agg$Use )


for (ay in unique(year(agg$date))){
    temp <- agg[year(date)==ay]

    plot( temp$date, factor(temp$Shoes) )


}

plot( agg$date, agg$Use )

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
unique(gath$Shoes)

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

## missing data
lines(empty$date, cumsum(empty$Distance), col = "grey", lwd = 4, type = "s" )


## create color palette
n      <- length(unique(gather$Shoes))
# cols   <- randomcoloR::distinctColorPalette(n)

## add lines to plot
sn <- c()
sc <- c()
cc <- 1
for (as in sort(unique(gath$Shoes))) {
    temp <- gath[gath$Shoes==as,]
    lines(temp$date, temp$total, col = cols[cc], lwd = 4, type = "s" )
    model <- gsub("^.*-[ ]+", "", as)

    segments(x0 = min(temp$date), y0 = 0, x1 = min(temp$date), y1 = temp$total[which.min(temp$date)],lty = 2, col = cols[cc] )
    segments(x0 = max(temp$date), y0 = 0, x1 = max(temp$date), y1 = temp$total[which.max(temp$date)],lty = 2, col = cols[cc] )


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
