#!/usr/bin/env Rscript

#### Golden Cheetah read activities directly


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


# library(rjson)
library(jsonlite)
library(geosphere)
library(VIM)


speed_diff_threshold <- 0.1    # km/h

## load outside goldencheetah
metrics <- readRDS("~/LOGs/GCmetrics.Rds")


files <- list.files("~/TRAIN/GoldenCheetah/Athan/activities/",
                    pattern = "*.json",
                    full.names = TRUE)

files <- sort(files)
files <- tail(files,1)

for (af in files) {

    ride <- fromJSON( af)

    rec <- ride$RIDE$SAMPLES

    if (is.null(rec)) next()

    hist(rec$KPH)

    # coor <- data.frame(LON = rec$LON, LAT = rec$LAT)
    # coor$Dist <- NA

    # for (ii in 2:nrow(coor)) {
    #     coor$Dist[ii] <- distm( coor[ii,][1:2], coor[ii-1,][1:2] )
    # }

    # rec$Dist <- coor$Dist
    # rec$Dur  <- c(NA,diff(rec$SECS))

    # rec$Speed <-(rec$Dist / 10^3) / (rec$Dur/3600)

    # rec$SpeedDiff = abs(rec$KPH - rec$Speed)

    ## ignore too small
    # rec$SpeedDiff[ rec$SpeedDiff < speed_diff_threshold ] <- NA

    # plot(  rec$SECS, rec$KPH)
    # points(rec$SECS, rec$Speed, col="red")
    #
    # plot(rec$SECS, rec$SpeedDiff)
    # hist(rec$SpeedDiff,breaks = 100)
    #
    #
    # summary(rec$Speed)
    # quantile(rec$Speed, na.rm = T)
    # toofast <- rec[rec$KPH > quantile(rec$KPH, na.rm = T)[4] * 2,]
    #
    # plot(  toofast$SECS, toofast$KPH)
    # points(toofast$SECS, toofast$Speed, col="red")
    # plot(  toofast$SECS, toofast$SpeedDiff)

    # stopifnot(all(rec$KPH   < 30))
    # stopifnot(all(rec$Speed < 30))
    # stopifnot(all(rec$SpeedDiff < 10))

    ## break spikes
    # rec$KPH[rec$KPH > quantile(rec$KPH, na.rm = T)[4] * 3] <- NA
    ## fix NA with nearest neighbor
    # rec <- kNN(data = rec, variable = "KPH")
    # rec$KPH_imp <- NULL

    ## replace original data
    # ride$RIDE$SAMPLES <- rec

    # txt = sub(".json","_N.json",af)
    # sss <- toJSON(x = ride )
    # write_json(x = ride, path=txt, simplifyVector=F)

}






# library(cycleRtools)
# GC_activity("Athan",activity = "~/TRAIN/GoldenCheetah/Athan/activities/2008_12_19_16_00_00.json")
# GC_activity("Athan")
#
# GC_metrics("Athan")










####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
