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
    sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)
}

# metrics <- GC.metrics(all=TRUE)
# saveRDS(metrics, "~/LOGs/GCmetrics.Rds")


metrics <- readRDS("~/LOGs/GCmetrics.Rds")



####  Copy for GC below  ####################################################

cat(paste(sort(unique(metrics$Shoes)), colapse = "\n"),
    "~/LOGs/Shoes.list")


gsub("^.*-[ ]+"," ",unique(metrics$Shoes))

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
    if (nrow(temp)>1) {
        ## insert extra data
        if (nrow(text)>0) {
            text$date[is.na(text$date)] <- min(temp$date,text$date,na.rm = T)
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

## plot params
cex <- 0.7


xlim <- range(gather$nday, na.rm = T)
ylim <- range(0,gather$total, na.rm = T)


#par(mar=c(2.5,2,0.3,0.3))
plot(1, type="n",
     xlab = "Days of usage", ylab = "km",
     xlim = xlim, ylim = ylim,
     cex.axis = cex)

library(randomcoloR)
sn   <- c()
sc   <- c()
n    <- length(unique(gather$Shoes))
cols <- distinctColorPalette(n)
cc <- 1
for (as in sort(unique(gather$Shoes))) {
    temp <- gather[gather$Shoes==as,]
    lines(temp$nday, temp$total, col = cols[cc], lwd = 4, type = "s" )
    model<-gsub("^.*-[ ]+","",as)
    text(temp$nday[which.max(temp$total)], max(temp$total),
         labels = paste(model,"\n", round(max(temp$total),0)),
         pos = 3, cex = cex * 0.8  )
    sn <- c(sn, paste0(as," (",round(max(temp$total),0),"km)" ) )
    sc <- c(sc,cols[cc])
    cc <- cc+1
}
legend("topleft", legend = sn, col = sc, bty = "n", pch = 19, cex = cex)







####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
