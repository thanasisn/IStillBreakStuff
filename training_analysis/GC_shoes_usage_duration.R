#!/usr/bin/env Rscript

#### GoldenCheetah plot shoes usage total duration vs total distance

## Can be used inside Golden Cheetah software
## Plot a line for each shoe usage


####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/training_analysis/GC_shoes_usage_duration.R"


out_file <- paste0("~/LOGs/training_status/", basename(sub("\\.R$",".pdf", Script.Name)))
in_file  <- "~/LOGs/GCmetrics.Rds"

if (!interactive()) {
  pdf(file  = out_file)
  sink(file = sub("\\.R$",".out",Script.Name), split = TRUE)
}


## save in goldencheetah
# metrics <- GC.metrics(all=TRUE)
# saveRDS(metrics, "~/LOGs/GCmetrics.Rds")

##  Check if have to run  ------------------------------------------------------
if (!file.exists(out_file) |
    file.mtime(out_file) < file.mtime(in_file) |
    interactive()) {
  cat("Have to run\n")
} else {
  cat("Not have to run\n")
  stop("Not have to run")
}


##  Load parsed data
metrics <- readRDS(in_file)


####  Copy for GC below  -------------------------------------------------------

library(data.table)
library(gdata)

cols <- c(
  "#f22e2e", "#d9b629", "#30ff83", "#3083ff", "#f22ee5", "#33161e", "#e6a89e",
  "#bbbf84", "#1d995f", "#324473", "#cc8dc8", "#59111b", "#b25c22", "#b1f22e",
  "#9ee6d7", "#482ef2", "#66465b", "#33200a", "#385911", "#24a0bf", "#270f4d",
  "#731647", "#664a13", "#414d35", "#22444d", "#6b1880", "#ff70a9")

metrics <- data.table(metrics)
write.fwf(metrics[, .(Dist = round(sum(Distance),1),
                      From = min(date),
                      To   = max(date),
                      Active = difftime(max(date),min(date))), by = Shoes],
          file = "~/TRAIN/Shoes.list", colnames = F)

## plot params
cex <- 0.7

## exclude non meaning
ddd   <- metrics[metrics$Shoes != "Multi", ]
empty <- ddd[ddd$Shoes == "?" | ddd$Shoes == "", ]
ddd   <- ddd[ddd$Shoes != "?", ]
ddd   <- ddd[ddd$Shoes != "", ]

empty  <- empty[empty$Sport == "Run", ]
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
  temp <-   ddd[ddd$Shoes == as, ]
  text <- extra[extra$Shoes == as, ]
  if (nrow(temp) > 0) {
    ## insert extra data
    if (nrow(text) > 0) {
      text$date[is.na(text$date)] <- min(temp$date,text$date,na.rm = T)
      ## is retired
      if (any(text$Status == "End")) {
        ## sanity checks
        stopifnot(text$Status[which.max(text$date)] == "End")
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
    temp$total <- cumsum(temp$Distance)
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
par("mar" = c(4, 4, 1, 1))
xlim <- range(gather$nday, max(gather$nday) + 7 , na.rm = T)
ylim <- range(0, gather$total * 1.05, na.rm = T)
plot(1,
     type = "n",
     xlab = "Days of usage",
     ylab = "km",
     xlim = xlim,
     ylim = ylim,
     cex.axis = cex)

## create color palette
n <- length(unique(gather$Shoes))
# cols   <- distinctColorPalette(n)

## add lines to plot
sn <- c()
sc <- c()
cc <- 1
for (as in sort(unique(gather$Shoes))) {
  temp <- gather[gather$Shoes == as, ]
  lines(temp$nday, temp$total, col = cols[cc], lwd = 4, type = "s")
  model <- gsub("^.*-[ ]+", "", as)
  text(temp$nday[which.max(temp$total)], max(temp$total),
       labels = paste(model,"\n", round(max(temp$total), 0)),
       pos = 3, cex = cex * 0.8  )
  sn <- c(sn, paste0(as, " (", round(max(temp$total), 0), "km)"))
  sc <- c(sc,cols[cc])
  cc <- cc+1
}

## add legend
sn <- c(sn, paste0("NO ENTRY (", round(emtpyD,0), "km)"))
sc <- c(sc, NA)
legend("topright", legend = sn, col = sc, bty = "n", pch = 19, cex = cex)




####_ END _####
tac <- Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
