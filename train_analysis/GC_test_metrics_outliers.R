#!/usr/bin/env Rscript

#### Golden Cheetah detect outliers in metrics data


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


library(data.table)
source("FUNCTIONS/R/data.R")



metrics <- readRDS("~/LOGs/GCmetrics.Rds")
metrics <- data.table(metrics)
metrics <- rm.cols.dups.DT(metrics)

wecare  <- names(Filter(is.numeric, metrics))

wecare  <- grep("Time_in_Zone",      wecare, value = T, invert = T )
wecare  <- grep("Time_in_Pace_Zone", wecare, value = T, invert = T )
wecare  <- grep("Percent_in_Zone",   wecare, value = T, invert = T )
wecare  <- grep("Checksum",          wecare, value = T, invert = T )
##TODO we may want that for detection extemes
wecare  <- grep("Best_",             wecare, value = T, invert = T )


wecare


for (var in wecare) {
    temp <- data.table(  metrics$date,  metrics[[var]])
    temp$V1 <- as.numeric(temp$V1)

    outlier_values <- boxplot.stats(temp$V2)$out  # outlier values.
    boxplot(temp$V2, main=var, boxwex=0.1)
    # mtext(paste("Outliers: ", paste(outlier_values, collapse=", ")), cex=0.6)

    # For continuous variable (convert to categorical if needed.)
    boxplot(V2 ~ V1, data=temp, main=var)
    boxplot(V2 ~ cut(V1, pretty(temp$V1 )), data=temp, main=var, cex.axis=0.5)

    plot(as.Date(temp$V1,origin = "1970-01-01"), temp$V2)
    title(var)

    mod <- lm( V1 ~ V2, data=temp)
    cooksd <- cooks.distance(mod)

    plot(cooksd, pch="*", cex=2, main=var)  # plot cook's distance
    abline(h = 4*mean(cooksd, na.rm=T), col="red")  # add cutoff line
    # text(x=1:length(cooksd)+1, y=cooksd, labels=ifelse(cooksd>4*mean(cooksd, na.rm=T),names(cooksd),""), col="red")  # add labels


    }






####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
