#!/usr/bin/env Rscript

#### GoldenCheetah plot shoes usage total distance vs time

## Can be used inside Golden Cheetah software
## Plot a line for each shoe usage

####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/training_analysis/GC_shoes_usage_timeseries.R"

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
library(gdata)

cols <- c(
  "#f22e2e", "#d9b629", "#30ff83", "#3083ff", "#f22ee5", "#33161e", "#e6a89e",
  "#bbbf84", "#1d995f", "#324473", "#cc8dc8", "#59111b", "#b25c22", "#b1f22e",
  "#9ee6d7", "#482ef2", "#66465b", "#33200a", "#385911", "#24a0bf", "#270f4d",
  "#731647", "#664a13", "#414d35", "#22444d", "#6b1880", "#ff70a9")

metrics <- data.table(metrics)

## usefull data only
metrics <- metrics[, .(Date, Shoes, Workout_Time, Workout_Code, Total_Distance,Sport)]
metrics <- metrics[!Sport %in% c("Bike", "Measurement")]
names(metrics)[names(metrics) == "Total_Distance"] <- "Distance"

## export shoes lists
summdt <- metrics[,
                  .(Dist   = round(sum(Distance), 1),
                    From   = min(Date),
                    To     = max(Date),
                    Active = difftime(max(Date), min(Date))),
                  by = Shoes]
vars <- names(summdt)

## create multiple list sorting
for (avar in vars) {
  write.fwf(summdt[order(summdt[[avar]])],
            file = paste0("~/LOGs/training_status/Shoes_by_", avar, ".list"),
            colnames = F)
}

## plot params
cex <- 0.7

## exclude non meaningfull for shoes
ddd   <- metrics[metrics$Shoes != "Multi", ]
empty <- ddd[ddd$Shoes == "?" | ddd$Shoes == "", ]
ddd   <- ddd[ddd$Shoes != "?", ]
ddd   <- ddd[ddd$Shoes != "", ]
ddd[, Date := as.Date(Date)]

## list missing shoes info
empty  <- empty[empty$Sport == "Run", ]
emtpyD <- sum(empty$Distance, na.rm = T)

## get external shoe logging
extra <- read.delim("~/TRAIN/Shoes.csv",
                    comment.char = '#',
                    sep = ";",
                    strip.white = T)
extra$Date     <- as.Date(extra$date)
extra$Distance <- as.numeric(extra$Distance)


## get days of usage
gather <- data.frame()
for (as in unique(ddd$Shoes)) {
  temp <-   ddd[ddd$Shoes == as, ]
  text <- extra[extra$Shoes == as, ]
  if (nrow(temp) > 0) {
    ## insert extra data
    if (nrow(text) > 0) {
      text$Date[is.na(text$Date)] <- as.Date(min(temp$Date, text$Date, na.rm = T), origin = "1970-01-01")
      ## is retired
      if (any(text$Status == "End")) {
        ## sanity checks
        stopifnot(text$Status[which.max(text$Date)] == "End")
        stopifnot(max(text$Date) >= max(temp$Date))
        ## move End day after last usage
        text$Date[which.max(text$Date)] <- temp$Date[which.max(temp$Date)] + 1
      }
      temp <- plyr::rbind.fill(text, temp)
      temp <- temp[order(temp$Date), ]
    }
    gather <- plyr::rbind.fill(gather, temp)
  }
}


## aggregate for plot
gather    <- data.table(gather)
agg       <- gather[,
                    .(Distance = sum(Distance)),
                    by = .(year(Date), month(Date), Shoes)
]
agg$Date  <- as.Date(paste(agg$year, agg$month, "1"), format = "%Y %m %d")

## for daily steps
# aggD      <- gather[, .(Distance = sum(Distance)), by = .(date = as.Date(date), Shoes)]
# agg <- aggD


## compute cumulative sums
gath <- data.table()
for (as in unique(agg$Shoes)) {
  temp <- agg[Shoes == as]
  setorder(temp, Date)
  temp[,total := cumsum(Distance)]
  gath <- rbind(gath, temp)
}

## pretty numbers
gath$total <- round(gath$total, 0)
unique(gath$Shoes)

## init empty plot
par("mar" = c(4, 4, 1, 1))
xlim <- range(gath$Date, Sys.Date() + 7 , na.rm = T)
ylim <- range(0, gath$total * 1.05 , na.rm = T)
plot(1, type="n",
     xlab = "",
     ylab = "km",
     xlim = xlim,
     ylim = ylim,
     xaxt = 'n',
     cex.axis = cex)
axis.Date(1, agg$Date)
axis.Date(1, at = seq(min(agg$Date), max(agg$Date) + 1, "months"),
          labels = FALSE, tcl = -0.2)

## missing type
lines(empty$Date, cumsum(empty$Distance), col = "grey", lwd = 4, type = "s")


## create color palette
n <- length(unique(gather$Shoes))
# cols   <- distinctColorPalette(n)

## add lines to plot
sn <- c()
sc <- c()
cc <- 1
for (as in sort(unique(gath$Shoes))) {
  temp <- gath[gath$Shoes == as, ]
  lines(temp$Date, temp$total, col = cols[cc], lwd = 4, type = "s" )
  model <- gsub("^.*-[ ]+", "", as)

  segments(x0 = min(temp$Date), y0 = 0, x1 = min(temp$date), y1 = temp$total[which.min(temp$Date)], lty = 2, col = cols[cc])
  segments(x0 = max(temp$Date), y0 = 0, x1 = max(temp$date), y1 = temp$total[which.max(temp$Date)], lty = 2, col = cols[cc])

  text(temp$Date[which.max(temp$total)], max(temp$total),
       labels = paste(model, "\n", round(max(temp$total), 0)),
       pos = 3, cex = cex * 0.8  )
  sn <- c(sn, paste0(as, " (", round(max(temp$total), 0), "km)"))
  sc <- c(sc,cols[cc])
  cc <- cc + 1
}

## add legend
sn <- c(sn, paste0("NO ENTRY (", round(emtpyD,0), "km)"))
sc <- c(sc, NA)
legend("topleft", legend = sn, col = sc, bty = "n", pch = 19, cex = cex)


if (!interactive()) {
  dev.off()
}

####_ END _####
tac <- Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
