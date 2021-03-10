#!/usr/bin/env Rscript

#### Golden Cheetah


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
metrics <- data.table(metrics)



library(data.table)


### For golden cheetah


metrics <- metrics[Sport == "Run",]


grep("pace",names(metrics), ignore.case = T, value = T)

train <- metrics[Workout_Code != "Run Race"]
race  <- metrics[Workout_Code == "Run Race"]

hist( train$Pace )
hist( train$xPace )
hist( train$TPace )
hist( train$`60_min_Peak_Pace` )




layout(matrix(c(1,2), 2, 1, byrow = TRUE))
par(mar = c(4,4,1,1))

if (nrow(train > 0)) {
## pace by distance class for training
breakby <- 5 # km
bb <- train[, .(MeanPace = mean(Pace), N = .N), by = .( DistClass = breakby*( (breakby/2 + Distance) %/% breakby )) ]
bb <- bb[ DistClass > 0 ]
setorder(bb, DistClass)

barplot(bb$MeanPace,names.arg = bb$DistClass, density = bb$N,
        xlab = "Distance class", ylab = "Pace min/km")
}


if (nrow(race > 0)){
## pace by distance class for race
breakby <- 20 # km
bb <- race[, .(MeanPace = mean(Pace), N = .N), by = .( DistClass = breakby*( (breakby/2 + Distance) %/% breakby )) ]
bb <- bb[ DistClass > 0 ]
setorder(bb, DistClass)

barplot(bb$MeanPace,names.arg = bb$DistClass, density = bb$N,
        xlab = "Distance class", ylab = "Pace min/km")
}





####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
