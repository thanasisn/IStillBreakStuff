#!/usr/bin/env Rscript

#### Get system location through wifi or google AP probing.
## uses 'sudo iw dev' and other system commands to collect data

# rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")

library(jsonlite)

API_KEY   <- Sys.getenv("GOOGLE_GEOLOC_API_KEY")
node      <- Sys.info()["nodename"]
year      <- strftime(Sys.Date(), "%Y")
keep_file <- paste0("~/LOGs/Locations/",node,"_",year,"_locations.dat" )

dir.create(   "/dev/shm/CONKY/", recursive = T, showWarnings = F)
CURRENT_FL <- "/dev/shm/CONKY/Locations.Rds"

ALLOW_SWITCH_WIFI <- TRUE
# ALLOW_SWITCH_WIFI <- FALSE

## load known locations (no spaces for bash sake)
LOCs    <- read.table("~/BASH/PARAMS/Known_locations.csv",sep = ";",strip.white = T, header = T)
LOCs$Dt <- Sys.time()

## location for different sources
loc_H   <- data.frame()
loc_0   <- data.frame()
loc_1   <- data.frame()
## location method that worked
AT_HOME <- FALSE
AT_WIFI <- FALSE
AT_IP   <- FALSE


#' Create columns if not exist
fncols <- function(data, cname) {
    add <- cname[!cname %in% names(data)]
    if (length(add) != 0) data[add] <- NA
    data
}



##  For wifi AP mac address  ###################################################
try({
    res <- "Nothing"
    ## have to drop vnc devices from results
    res <- system('sudo arp -a ',
                  intern        = TRUE,
                  ignore.stderr = TRUE,
                  timeout       = 10)

    ## we got something useful to process
    if ( !is.null(res) && length(res) > 0 ) {
        AT_HOME <- any(apply(LOCs[1],1, grepl, res))
        if (AT_HOME) {
            loc_H <- LOCs[ apply(LOCs[1],1, function(x) { any(grepl(x, res)) } ),  ]
            cat(paste("Known location Access Point\n"))
        }
        rm(res)
    }
    cat(paste("Wifi AP says:", c(AT_HOME, loc_H)), sep = "\n")
})


##  For known static ip  #######################################################
try({
    if (!AT_HOME) {
        res <- "Nothing"
        res <- system('ip addr show',
                  intern        = TRUE,
                  ignore.stderr = TRUE,
                  timeout       = 10)

        if ( !is.null(res) && length(res) > 0  ) {
            AT_HOME <- any(apply(LOCs[1],1, grepl, res))

            if (AT_HOME) {
                loc_H <- LOCs[ apply(LOCs[1],1, function(x) { any(grepl(x, res)) } ),  ]
                cat(paste("Known location static ip\n"))
            }
            rm(res)
        }
        cat(paste("Known static ip says:", c(AT_HOME, loc_H)),sep = "\n")
    }
})


##  IP only method  ############################################################
## use this if google failed
try({
    if (!AT_HOME) {
        x <- readLines("https://www.geodatatool.com/")
        y <- grep("City:|lat:|lng:|title:", x,value = T)
        y <- gsub("\t|,",  "", y)
        y <- gsub(" +",   " ", y)

        lat_0 <- as.numeric(unlist(strsplit(x = unique(grep("[Ll][Aa][Tt]: [-0-9.]+$",y,value = T))[1], " " ))[2])
        lng_0 <- as.numeric(unlist(strsplit(x = unique(grep("[Ll][Nn][Gg]: [-0-9.]+$",y,value = T))[1], " " ))[2])

        ff     <- grep("[Cc][Ii][Tt][Yy]: [0-9a-zA-Z ]+",y,value = T)[1]
        city_0 <- gsub(".*[Cc][Ii][Tt][Yy]: (.*)<.*", '\\1', ff)
        city_0 <- iconv( city_0 , to = 'ASCII//TRANSLIT')
        loc_0  <- data.frame(Dt   = Sys.time(),
                             Lat  = lat_0,
                             Lng  = lng_0,
                             City = city_0,
                             Elv  = NA,
                             Acc  = NA,
                             Key  = NA,
                             Type = "ip")

        if (is.numeric( loc_0$Lat )) {
            AT_IP = TRUE
            cat(paste("Location from public ip says:", c(AT_HOME, loc_0)),sep = "\n")
        }
    }
})


##  From WIFI and google  ######################################################
try({
    if (!AT_HOME) {
        ## get current radio status and turn it on for retrieval
        wifi_OFF <- system('nmcli radio wifi',
                           intern = TRUE,
                           timeout = 10) == "disabled"
        if ( wifi_OFF & ALLOW_SWITCH_WIFI) {
            ## try to start wifi
            system('nmcli radio wifi on',
                   intern = TRUE,
                   timeout = 10)
            system('sleep 2')
        }

        ## get wifi name
        wif <- system('sudo iw dev | awk \'$1==\"Interface\"{print $2}\'',
                      intern  = TRUE,
                      timeout = 10)
        # cat(paste(wif))

        ## get access point data
        scan_res <- system(paste('sudo iw dev', wif, 'scan'),
                           intern = TRUE,
                           timeout = 10)

        ## prepare a json to send
        AP     <- grep("BSS|signal", scan_res, ignore.case = T, value = T)
        AP     <- gsub("\t|,",  "", AP )

        AP_BSS <- grep("^BSS", AP, ignore.case = T, value = T)
        AP_BSS <- gsub(".*([0-9a-z]{2}:[0-9a-z]{2}:[0-9a-z]{2}:[0-9a-z]{2}:[0-9a-z]{2}:[0-9a-z]{2}).*", '\\1', AP_BSS)
        AP_BSS <- grep("[0-9a-z]{2}:[0-9a-z]{2}:[0-9a-z]{2}:[0-9a-z]{2}:[0-9a-z]{2}:[0-9a-z]{2}", AP_BSS, value = T)

        AP_SIG <- grep("^signal", AP, ignore.case = T, value = T)
        AP_SIG <- gsub(".*(-[0-9.]+).*", '\\1', AP_SIG)
        AP_SIG <- as.numeric( AP_SIG )

        ### don't know how to use this
        # data_sent <- toJSON(list(considerIp = "true",
        #                          wifiAccessPoints = data.frame(macAddress = AP_BSS,
        #                                                        signalStrength = AP_SIG)),
        #                     simplifyVector = T,
        #                     auto_unbox = T
        #                     )

        AP_singals <- data.frame(macAddress = AP_BSS, signalStrength = AP_SIG)

        ## write file to disk to use system command
        write_json(x = list(considerIp = "true",
                            wifiAccessPoints = data.frame(macAddress = AP_BSS,
                                                          signalStrength = AP_SIG) ),
                   auto_unbox = T,
                   path = "/dev/shm/CONKY/ap.json")
        ## fix formating
        # system("sed -i 's/\\[\"true\"\\]/\"true\"/' /dev/shm/CONKY/ap.json")

        url <- paste0('https://www.googleapis.com/geolocation/v1/geolocate?key=', API_KEY)

        ## use a system call to google
        output <- system(
            paste0('curl -d @/dev/shm/CONKY/ap.json -H "Content-Type: application/json" -i "', url,'"'),
            intern  = TRUE,
            timeout = 10)

        ## parse output data
        geol <- gsub('"',  "", output)
        geol <- gsub(',',  "",  geol )
        geol <- gsub(" +", " ", geol )
        geol <- gsub("^ ", "",  geol )
        geol <- gsub("\r", "",  geol )

        lat_1 <- as.numeric(unlist(strsplit(grep("[Ll][Aa][Tt]: [0-9.]+$",geol,value = T), " "))[2])
        lng_1 <- as.numeric(unlist(strsplit(grep("[Ll][Nn][Gg]: [0-9.]+$",geol,value = T), " "))[2])
        acc_1 <- as.numeric(unlist(strsplit(grep("Accuracy: [0-9.]+$",geol,value = T, ignore.case = T), " "))[2])
        ## gather data
        loc_1  <- data.frame(Dt   = Sys.time(),
                             Lat  = lat_1,
                             Lng  = lng_1,
                             Acc  = acc_1,
                             Elv  = NA,
                             Key  = NA,
                             Type = "wifi")
        ## check data
        if (is.numeric( loc_1$Lat )) {
            AT_WIFI = TRUE
            cat(paste("Location from wifi and google says:", c(AT_HOME, loc_1)),sep = "\n")
        }
        ## set wifi to previous power state
        if ( wifi_OFF & ALLOW_SWITCH_WIFI) {
            system('nmcli radio wifi off',
                   intern = TRUE,
                   timeout = 10)
        }
    }
})


cat(paste("Home:", AT_HOME, "  WIFI:", AT_WIFI , "  by IP: ", AT_IP, "\n"))
## load previous data or create a new storage
if (file.exists(CURRENT_FL)) {
    Location_data <- readRDS(CURRENT_FL)
} else {
    Location_data <- data.frame()
}

## update with new found location
if ( AT_HOME ) {
    Location_data <- plyr::rbind.fill(Location_data, loc_H)
} else if ( AT_WIFI ) {
    Location_data <- plyr::rbind.fill(Location_data, loc_1)
} else if ( AT_IP ) {
    Location_data <- plyr::rbind.fill(Location_data, loc_0)
}


export_columns <- c("Dt", "Lat", "Lng", "Elv", "City", "Acc", "Type", "Key")
Location_data  <- Location_data[ ! is.na( Location_data$Lat ) & ! is.na( Location_data$Lng ), ]
Location_data  <- Location_data[ order(Location_data$Dt),]
Location_data  <- unique(Location_data)
Location_data  <- fncols(Location_data, export_columns)
Location_data  <- Location_data[ , c("Dt", "Lat", "Lng", "Elv", "City", "Acc", "Type", "Key") ]

## store location data
Location_data <- Location_data[ order(Location_data$Dt ), ]
write.table(Location_data, keep_file,
            sep       = ",",
            append    = TRUE,
            col.names = FALSE,
            row.names = FALSE)
## for desktop use
write.csv(x    = tail(Location_data, 4 ),
          file = "/dev/shm/CONKY/last_location.dat", quote = F, row.names = F )
## show on terminal
print(tail(Location_data, 4 ))

## END ##
