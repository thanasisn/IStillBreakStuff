#!/usr/bin/env Rscript


#### A very esoteric script to monitor car usage and status

####_ Set environment _####
rm(list = (ls()[ls() != ""]))
tic <- Sys.time()
Script.Name <- tryCatch({ funr::sys.script() },
                        error = function(e) { cat(paste("\nUnresolved script name: ", e),"\n")
                            return("Undefined R script name!!") })
if(!interactive())pdf(file="~/LOGs/car_logs/Car_stats_plots.pdf")
if(!interactive())sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)
Script.Base = sub("\\.R$","",Script.Name)



library(data.table)


source("~/FUNCTIONS/R/data.R")

## always use local time here
Sys.setenv(TZ = "Europe/Athens")

## variables
repo   <- "~/LOGs/carpros/"
mycars <- c("Duster", "Carina")
TANK   <- c(  70    ,   60    )

# mycars <- c("Carina", "Duster")
# TANK   <- c(  60    ,   70    )



## functions
m_s <- Vectorize(
    function(dur = "") {
        sum(as.numeric(strsplit( dur, split = ":" )[[1]]) * c(60, 1))
    },
    SIMPLIFY = TRUE, USE.NAMES = FALSE)

h.m.s <- Vectorize(
    function(dur = "") {
        sum(as.numeric(strsplit( dur, split = "[.]" )[[1]]) * c(3600, 60, 1))
    },
    SIMPLIFY = TRUE, USE.NAMES = FALSE)

m.s.S <- Vectorize(
    function(dur = "") {
        sum(as.numeric(strsplit( dur, split = "[.]" )[[1]]) * c(600, 10, 1))/10
    },
    SIMPLIFY = TRUE, USE.NAMES = FALSE)



for (CAR in mycars) {
    cat(CAR, "\n")

    ## get file list
    files <- list.files(path       = repo,
                        pattern    = CAR,
                        recursive  = TRUE,
                        full.names = TRUE)

    ####  Read service manual  ####
    afile <- paste0(repo, "/", CAR, "_Service_manual.csv")
    if (file.exists(afile)) {
        cat("Read manual service file", CAR,"\n")
        servicemanual <- read.csv(afile)
        servicemanual <- data.table(servicemanual)
        servicemanual <- servicemanual[ Title != "Service Book",]
        servicemanual[ , Date        := as.Date(Date) ]
        servicemanual[ , Expire.Date := as.Date(Expire.Date) ]
        wecare        <- servicemanual[, .(Date = max(Date)), by = Title ]
        gather <- data.table()
        for(ai in 1:nrow(wecare)){
            comp   <- wecare[ai]
            temp   <- servicemanual[ Date == comp$Date & Title == comp$Title, ]
            gather <- rbind(gather,temp)
        }
        gather <- rm.cols.dups.DT(gather)
        gather$Source <- "manual"
        servicemanual <- gather
    } else {
        servicemanual <- data.table()
    }



    ####  Prepare taplog data   ####
    taplog <- read.csv("~/LOGs/BMeasurments/Csv File")
    taplog <- taplog[agrepl(CAR, taplog$cat1, ignore.case = T),]
    taplog <- taplog[order(taplog$timestamp),]
    wecare <- grep("Time", names(taplog), value = T, invert = T)
    for (an in wecare ) {
        if (length(unique(taplog[[an]]))==1) {
            taplog[[an]] <- NULL
        }
    }
    taplog$Milliseconds     <- NULL
    taplog$DayOfYear        <- NULL
    taplog$DayOfMonth       <- NULL
    taplog$DayOfWeek        <- NULL
    taplog$TimeOfDay        <- NULL
    taplog$gpstime          <- NULL
    taplog$gpsMilliseconds  <- NULL
    taplog$X_id             <- NULL
    taplog$lat_text         <- NULL
    taplog$lon_text         <- NULL
    taplog$altitude         <- NULL
    taplog$accuracy         <- NULL
    taplog$latitude         <- NULL
    taplog$longitude        <- NULL
    taplog$speed            <- NULL
    taplog$bearing          <- NULL
    taplog$timezoneOffset   <- NULL

    ## assume gas has the same data with taplog
    taplog           <- taplog[ grep("fill", taplog$cat1, invert = T), ]

    sub(":00$" ,"00",sub("\\.[0-9]+\\+" ,"+",taplog$timestamp))
    sub("\\.[0-9]+\\+" ,"+",taplog$timestamp)

    taplog$timestamp <- strptime( sub(":00$" ,"00",sub("\\.[0-9]+\\+" ,"+",taplog$timestamp)) , "%FT%T")
    taplog$timestamp <- as.POSIXct(taplog$timestamp)
    taplog$tdiff     <- c(90000,diff(taplog$timestamp))
    taplog$gid       <- NA
    taplog$Date      <- Sys.time()

    ## group records by times
    threshold <- 1800
    id        <- 1
    for (ar in 1:nrow(taplog)) {
        cur <- taplog$tdiff[ar]
        if (cur >= threshold) {
            id <- id + 1
        }
        taplog$gid[ar] <- id
    }
    for (ar in unique(taplog$gid)) {
        taplog$Date[taplog$gid == ar] <- as.POSIXct(mean(taplog$timestamp[taplog$gid == ar]))
    }

    taplog$tdiff     <- NULL
    taplog$gid       <- NULL
    taplog$timestamp <- NULL

    # if (!any(names(taplog) %in% "note")) taplog$note <- NA
    # taplog <- reshape(data = taplog, direction = "wide", idvar = c("Date","note"), timevar = "cat1")
    taplog <- reshape(data = taplog, direction = "wide", idvar = c("Date"), timevar = "cat1")

    wecare <- grep(paste0("number.",CAR), names(taplog))
    names(taplog)[wecare]              <- sub(paste0("number.",CAR,"_"),"", names(taplog)[wecare])
    names(taplog)[names(taplog)=="km"] <- "Odometer"
    taplog <- rm.cols.dups.df(taplog)

    if (any(names(taplog) %in% "trip_km")) {

        ## Extract driving time from car
        taplog$Time_assum <- taplog$trip_km / taplog$Avg_kmph
        taplog$Drive_Duration <- c(NA, diff( nafill( taplog$Time_assum, fill = 0 )))
        taplog$Drive_Duration[taplog$Drive_Duration <= 0] <- NA
        taplog$Drive_Duration <- taplog$Drive_Duration * 3600
        taplog$Avg_kmph   <- NULL
        taplog$Time_assum <- NULL

        ## Get consumption from car
        taplog$Car_Consumption <- c(NA, diff( nafill( taplog$Consumption_Accum, fill = 0 )))
        taplog$Car_Consumption[taplog$Car_Consumption <= 0] <- NA
        taplog$Consumption_Accum <- NULL

    }

    ## Get distance from car
    taplog$Distance_Od   <- c(NA, diff( nafill( taplog$Odometer, fill = 0 )))
    taplog$Distance_trip <- c(NA, diff( nafill( taplog$trip_km, fill = 0 )))
    taplog$test <- ( 100 * abs(taplog$Distance_Od - taplog$Distance_trip) / taplog$Distance_Od ) > 90
    taplog$test[is.na(taplog$test)] <- FALSE
    taplog$Distance_trip[taplog$test] <- taplog$Distance_Od[taplog$test]
    taplog$test        <- NULL
    taplog$Distance_Od <- NULL
    taplog$trip_km     <- NULL

    if (!all(is.na(taplog$Distance_trip))) {
        taplog$Car_Consumption_Rate <- 100 * taplog$Car_Consumption / taplog$Distance_trip

        ## Get fuel estimate for range
        taplog$Fuel_from_range  <- taplog$Range * (taplog$Consumption_Rate/100)
        taplog$Range            <- NULL
        taplog$Consumption_Rate <- NULL

        taplog$Car_Consumption_Rate[taplog$Car_Consumption_Rate > 20] <- NA
    }

    indx2 <- which(sapply(taplog, is.character))
    for (j in indx2) set(taplog, i = grep("^$|^ $", taplog[[j]]), j = j, value = NA_character_)

    taplog        <- rm.cols.dups.df(taplog)
    taplog$Source <- "taplog"
    taplog        <- data.table(taplog)



    vec <- !is.na(taplog$Fuel_Level)
    taplog[ vec , Fuel_Level_diff := c(0,diff(Fuel_Level)) ]
    taplog[ vec , Fuel_Level_trip := c(0,diff(Odometer)) ]

    taplog[ vec & Fuel_Level_trip >0 & Fuel_Level_diff <= 0,
            Fuel_Level_change_p100km := 100 * Fuel_Level_diff / Fuel_Level_trip]

    setorder(taplog, Date )
    write.csv(x = taplog, file = paste0("~/LOGs/car_logs/Taplog_",CAR,".csv"),row.names = F)



    ####  Prepare service data carpros  ####
    service <- fread(grep(paste0(CAR,"_ServiceData"),files,value = T))
    service[, Date := as.Date(Date, "%m/%d/%y") ]
    service[, Date := as.POSIXct(paste(Date,"12:00:00")) ]
    names(service)[names(service) == "Mileage"] <- "Odometer"
    service <- rm.cols.dups.DT(service)
    service$Source <- "carpros"
    service <- data.table(service)



    ####  Prepare gas data carpros  ####
    gas <- fread(grep("GasData", files, value = T))
    gas[, Date := as.Date(Date, "%m/%d/%y") ]
    gas[, Date := as.POSIXct(paste(Date, Time))]
    setorder(gas, Date)
    gas[, Time := NULL]
    gas[, Lat  := NULL]
    gas[, Lng  := NULL]
    gas[, Litre := Cost / UnitPrice ]
    names(gas)[names(gas) == "Mileage"] <- "Odometer"
    gas[ , dist_traveled := c(NA, abs(diff(Odometer)))]
    gas[ , lp100km       := 100 * Litre / dist_traveled ]
    gas[ , Avg_lp100km   := 100 * sum(gas$Litre[ 1:(nrow(gas)-1) ]) / diff(range(gas$Odometer)) ]
    write.csv(x = gas, file = paste0("~/LOGs/car_logs/Gas_stats_", CAR,".csv"),row.names = F)


    ####  Prepare trip data carpros  ####
    afile <- grep("carpros_manual",files,value = T)
    if (!identical(afile, character(0))) {

        trip1                        <- read.csv(grep("carpros_manual",files,value = T))
        trip1$Duration               <- h.m.s( trip1$Duration )
        trip1$Idle.time              <- m.s.S( trip1$Idle.time.min.sec.0)
        trip1$WOT.duration.min.sec.0 <- m.s.S( trip1$WOT.duration.min.sec.0)
        trip1$Driving.Start.Time     <- as.POSIXct( trip1$Driving.Start.Time,  tz = "Europe/Athens" )
        trip1$Driving.Finish.Time    <- as.POSIXct( trip1$Driving.Finish.Time, tz = "Europe/Athens" )
        ## we don't trust that
        trip1$Max.MAF.g.s            <- NULL
        trip1$Avg..MAF.g.s           <- NULL
        trip1$Max.IAT.C              <- NULL
        trip1$Avg..Iat.C             <- NULL
        trip1$Idle.time.min.sec.0    <- NULL
        trip1$Fuel.Consumed          <- NULL
        trip1$Fuel.efficiency.kpl    <- NULL

        names(trip1)[ names(trip1) == "Avg..speed.km.h" ] <- "Avg.Speed"
        names(trip1)[ names(trip1) == "Max..speed.km.h" ] <- "Max.Speed"

        trip1 <- rm.cols.dups.df(trip1)
        trip1$Source <- "carpros"
    }


    ####  Prepare trip data infocar  ####
    trip2   <- data.frame()
    xlfiles <- grep(paste0("[0-9]+-[0-9]+_.*",CAR,".xls" ) ,files,value = T)
    if (length(xlfiles) != 0) {

        for (af in xlfiles){
            temp  <- xlsx::read.xlsx(af,sheetIndex = 1)
            trip2 <- rbind(trip2,temp, fill = T)
        }
        trip2 <- unique( trip2 )

        trip2$Driving.Start.Time  <- as.POSIXct( trip2$Driving.Start.Time,  format = "%d %b %Y %T", tz = "Europe/Athens" )
        trip2$Driving.Finish.Time <- as.POSIXct( trip2$Driving.Finish.Time, format = "%d %b %Y %T", tz = "Europe/Athens" )
        trip2$Duration            <- as.numeric(difftime(trip2$Driving.Finish.Time, trip2$Driving.Start.Time , units = "sec"))
        trip2$"Arr."       <- NULL
        trip2$"Dep."       <- NULL
        trip2$Driving.Time <- NULL
        trip2 <- trip2[trip2$Duration > 0,]
        trip2 <- trip2[!is.na( trip2$Driving.Start.Time), ]
        wecare <- grep("Time", names(trip2), value = T, invert = T)
        for (an in wecare ) {
            if (length(unique(trip2[[an]]))==1) {
                trip2[[an]] <- NULL
            }
        }

        trip2$Distance                     <- as.numeric(sub("km",     "", trip2$Distance ))
        trip2$Fuel.Consumed                <- as.numeric(sub("L",      "", trip2$Fuel.Consumed ))
        trip2$Avg..speed                   <- as.numeric(sub("km/h",   "", trip2$Avg..speed ))
        trip2$Fuel.effciency               <- as.numeric(sub("L/100km","", trip2$Fuel.effciency ))
        trip2$Distance.of.driving.at.night <- as.numeric(sub("km",     "", trip2$Distance.of.driving.at.night ))
        trip2$Idle.time                    <- m_s( trip2$Idle.time..min.sec. )
        trip2$Idle.time..min.sec.          <- NULL
        trip2$Driving.at.night             <- m_s( trip2$Driving.at.night..min.sec. )
        trip2$Driving.at.night[is.na(trip2$Driving.at.night)] <- 0
        trip2$Driving.at.night..min.sec.   <- NULL

        trip2 <- rm.cols.dups.df(trip2)
        trip2$Source <- "infocar"
        names(trip2)[ names(trip2) == "Avg..speed" ] <- "Avg.Speed"
    }



    if (any(grepl("trip1", ls()))) {

        ####  Combine trips from different sources  ####
        trip <- merge(trip1, trip2,
                      by = intersect(names(trip1),names(trip2)),
                      all = T)

        trip$Date <- trip$Driving.Finish.Time
        trip$Driving.Start.Time            <- NULL
        trip$Driving.Finish.Time           <- NULL
        trip$Driving.at.night..min.sec.    <- NULL
        trip$Distance.of.driving.at.night  <- NULL
        trip$Odometer.on.Dep.              <- NULL
        trip$Odometer.on.Arr.              <- NULL
        trip$Fuel.cut.time..min.sec.       <- NULL
        trip$Driving.purpose               <- NULL
        trip$Fuel.expenses                 <- NULL
        trip$Other.costs                   <- NULL
        trip$Toll.fee                      <- NULL
        trip$Fuel.effciency2 <- 100 * trip$Fuel.Consumed / trip$Distance

        setorder(trip, "Date")
        rm(trip1, trip2)
        trip <- data.table(trip)
        trip <- trip[ !is.na(Date)]
        write.csv(x = trip, file = paste0("~/LOGs/car_logs/Trip_stats_",CAR,".csv"),row.names = F)
    }



    ####  Combine all data  ####
    data <- merge(taplog, gas,
                  by = intersect(names(taplog),names(gas)),
                  all = T)
    rm(gas,taplog)

    data <- merge(data, service,
                  by = intersect(names(data),names(service)),
                  all = T)
    rm(service)

    if (any(grepl("trip$", ls()))) {
        data <- merge(trip, data,
                      by = intersect(names(trip),names(data)),
                      all = T)
        rm(trip)
    }

    data <- unique(data)
    data <- rm.cols.dups.DT(data)
    setorder(data,Date)
    data[is.na(Source), Source := "Other"]




    ####    ANALYSIS   #############################################################


    #### Check for maintenance ####
    lastodometer <- max(data$Odometer, na.rm = T)

    servicemanual$Cost     <- NULL

    servicemanual[, Used_distance      := lastodometer - Mileage ]
    servicemanual[, Remaining_distance := Service_km   - Used_distance ]

    servicemanual[ !is.na(Remaining_distance) , Distance_left := paste(round( 100 * Remaining_distance / Service_km, digits = 1 ),"%" )]

    library(lubridate)
    servicemanual[ is.na(Expire.Date) , Expire.Date := Date %m+% months(Service_Months)  ]

    servicemanual$Time_left <- sub("^[0-9]+s \\(" ,"" ,as.duration(difftime( servicemanual$Expire.Date, Sys.Date() , units = "days")))
    servicemanual$Time_left <- sub("\\)" ,"" ,servicemanual$Time_left)
    servicemanual           <- servicemanual[ order(difftime( servicemanual$Expire.Date, Sys.Date() , units = "days")),]
    write.csv(x = servicemanual, file = paste0("~/LOGs/car_logs/Maintainance_",CAR,".csv"),row.names = F)
    rm(servicemanual)

    ## TODO Issue warnings



    ## fill odometer
    data$Odometer <- as.integer(data$Odometer)

    data$Od    <- NA
    data$Od[1] <- data$Odometer[1]
    for (nn in 2:nrow(data) ){
        data$Od[nn] <- data$Odometer[nn] - data$Odometer[nn-1]
    }

    data[is.na(Od), Od := Distance ]
    data[is.na(Od), Od := 0        ]

    data$Odometer2 <- cumsum(data$Od)

    temp <- data[Date >= "2022-01-01"]
    wecare <- grep("speed|RPM|Score|oil|night|WOT|idle|note|type|MAF|IAT|Location|Station|lat|lng|coolant|Start.Time|Finish.Time|Fuel.effciency.kpl",names(temp),ignore.case = T,invert = T,value = T)
    temp <- temp[, ..wecare]

    temp$lost <- temp$Odometer - temp$Odometer2




    ##TODO test app consumption with car consumption



    FUEL     <- TANK[which(mycars == CAR)]
    wecare <- c(
        "Date",
        "Odometer",
        "Fuel.Consumed",
        "Source",
        "Fuel_Level",
        "Fuel_from_range",
        "UnitPrice",
        "FillStatus",
        "Distance_trip",
        "Distance",
        "PrevSkipped",
        "Litre",
        "Cost",
        "Car_Consumption"
    )
    wecare <- names(temp)[names(temp) %in% wecare]

    fff   <- temp[, ..wecare ]
    fff[, Fuel_car := NA ]
    fff[, Fuel_app := NA ]

    fff$Fuel_app[fff$FillStatus == "Full Tank"] <- FUEL
    fff$Fuel_car[fff$FillStatus == "Full Tank"] <- FUEL
    fff$Odometer2 <- fff$Odometer

    ids <- c( which(fff[, FillStatus == "Full Tank" ]),nrow(fff))

    if (length(ids)>2) {
        for (i in 1:(length(ids)-1) ){
            start <- ids[i]   + 1
            end   <- ids[i+1] - 1

            for (ii in start:end) {
                if (!is.na(fff$Car_Consumption[ii])) {
                    fff$Fuel_car[ii] <- min(fff$Fuel_car[(start-1):end], na.rm = T) - fff$Car_Consumption[ii]
                }
                if (!is.na(fff$Fuel.Consumed[ii])) {
                    fff$Fuel_app[ii] <- min(fff$Fuel_app[(start-1):end], na.rm = T) - fff$Fuel.Consumed[ii]
                }
                if (!is.na(fff$Distance[ii])) {
                    fff$Odometer2[ii] <- max(fff$Odometer2[(start-1):end], na.rm = T) + fff$Distance[ii]
                }
            }
        }
        fff <- fff[(ids[1]):nrow(fff),]



        plot(fff$Date, fff$Fuel_car, col = as.factor(fff$Source))
        points(fff$Date, fff$Fuel_app, col = as.factor(fff$Source))

        plot(fff$Date, fff$Fuel_app, col = as.factor(fff$Source))
        points(fff$Date, fff$Fuel_car, col = as.factor(fff$Source))

        plot(fff$Odometer2, fff$Fuel_car, col = as.factor(fff$Source))
        points(fff$Odometer2, fff$Fuel_app, col = as.factor(fff$Source))

        plot(fff$Odometer2, fff$Fuel_app, col = as.factor(fff$Source))
        points(fff$Odometer2, fff$Fuel_car, col = as.factor(fff$Source))

        plot(fff$Odometer, fff$Odometer2, col = as.factor(fff$Source))
    }

    temp$Fuel             <- NA
    temp$AccumConsumption <- cumsum( nafill(temp$Fuel.Consumed, fill = 0) )
    temp$Fuel <- FUEL - temp$AccumConsumption + nafill( temp$Litre, fill = 0 )


    if (any(names(temp)%in%"Fuel.Consumed")) {
        plot(temp$Date, temp$Fuel.Consumed, col=as.factor(temp$Source))
    }

    if ( any(names(temp)%in%"Fuel") & !any(is.na(temp$Fuel)) ) {
        plot(temp$Date, temp$Fuel, col=as.factor(temp$Source))
    }


    ## monitor fuel

    temp$Consum_Accu_diff <- NA
    temp$Odometer_diff    <- NA
    temp$Fuel_range_diff  <- NA
    temp$Fuel_estim_diff  <- NA
    temp$Fuel_Consum_sum  <- NA
    temp$Distance_sum     <- NA

    ids <- which( !is.na(temp$Car_Consumption), arr.ind = T)
    if (length(ids)>1){
        fuelgather <- data.table()
        for (ai in 1:(length(ids)-1) ) {
            start <- ids[ai]
            end   <- ids[ai+1]


            ## consumed by car
            temp$Consum_Accu_diff[start:end] <- temp$Car_Consumption[start]
            ## consumed by obd
            Fuel_Consum_sum                  <- sum(temp$Fuel.Consumed[ start:end ], na.rm = T )
            temp$Fuel_Consum_sum[start:end]  <- Fuel_Consum_sum


            Odometer_diff                    <- temp$Odometer         [end] - temp$Odometer         [start]
            temp$Odometer_diff[start:end]    <- Odometer_diff


            Distance_sum                     <- sum(temp$Distance[      start:end ], na.rm = T )
            temp$Distance_sum[start:end]     <- Distance_sum

            fuelgather <- rbind(fuelgather,
                                data.table( Date             = temp$Date[ end ],
                                            Odometer_diff    = Odometer_diff,
                                            Distance_sum     = Distance_sum,
                                            Consum_Car       =temp$Car_Consumption[start],
                                            Fuel_Cons_sum    = Fuel_Consum_sum,
                                            NULL)
            )
        }
        fuelgather <- rm.cols.dups.DT(fuelgather)
        write.csv(x = fuelgather, file = paste0("~/LOGs/car_logs/Fuel_test_",CAR,".csv"),row.names = F)
    }


    ####  Plot all by date  ####

    wecare <- grep("Date", names(temp), ignore.case = T, value = T, invert = T)
    for ( av in wecare ) {
        if ( ! is.numeric( temp[[av]] )) next()
        pp <- !is.na(temp[[av]])
        if (!any(pp)) next()
        plot(temp$Date[pp], temp[[av]][pp],type = "b")
        title(paste(CAR,"Date -",av))
    }


    ####  Plot all by Odometer  ####

    wecare <- grep("Odometer$", names(temp), ignore.case = T, value = T, invert = T)
    for ( av in wecare ) {
        if ( ! is.numeric( temp[[av]] )) next()
        pp <- !is.na(temp[[av]]) & !is.na(temp$Odometer)
        if (!any(pp)) next()
        plot(temp$Odometer[pp], temp[[av]][pp],type = "b",
             xlab = "Odometer real")
        title(paste(CAR,"Main Odometer -",av))
    }


    ####  Plot all by Odometer 2  ####

    wecare <- grep("Odometer2$", names(temp), ignore.case = T, value = T, invert = T)
    for ( av in wecare ) {
        if ( ! is.numeric( temp[[av]] )) next()
        pp <- !is.na(temp[[av]]) & !is.na(temp$Odometer)
        if (!any(pp)) next()
        plot(temp$Odometer2[pp], temp[[av]][pp],type = "b",
             xlab = "Odometer constracted")
        title(paste(CAR,"Odometer approx -",av))
    }

    temp <- rm.cols.dups.DT(temp)
    write.csv(x = temp, file = paste0("~/LOGs/car_logs/Data_",CAR,".csv"),row.names = F)
}




tac = Sys.time();
cat(sprintf("%s %s@%s %s %f mins\n\n",Sys.time(),Sys.info()["login"],Sys.info()["nodename"],Script.Name,difftime(tac,tic,units="mins")))
