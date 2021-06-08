#!/usr/bin/env Rscript


#### Parse xml logs from phone
## Data created by "SMS Backup & Restore" app

####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
# Script.Name = funr::sys.script()
# if(!interactive())pdf(file=sub("\\.R$",".pdf",Script.Name),width = 14)
# sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)



library(XML)
library(myRtools)



data_folder = "~/LOGs/sms/"


## parse all xml call logs ##
old_files <- list.files(path = data_folder,
                        pattern = "calls.*\\.xml",
                        full.names = T,
                        recursive = T)
gather <- data.frame()
if (length(old_files) > 0) {
    for ( af in old_files) {
        cat(paste(af), sep = "\n")

        ## read a file
        data  <- xmlParse(af)
        dd    <- xmlToList(data)

        ##FIXME this is slow
        ## create dataframe from uneven rows
        for (aa in dd) {
            gather <- plyr::rbind.fill(gather, data.frame(t(aa)))
        }
    }
    ## clean often too many dups
    gather <- unique( gather )

    ## clean calls logs
    gather$backup_set  <- NULL
    gather$backup_date <- NULL
    gather <- gather[ !(is.na(gather$date) & is.na(gather$number)), ]
    vec    <- vapply(gather, function(x) length(unique(x)) > 1, logical(1L))
    gather <- gather[ , vec ]

    ## store xml data
    exp_fl <- paste0(data_folder,"/Calls_xml_",format(Sys.time(),"%F_%T"))
    write_dat(gather, exp_fl)
    write_RDS(gather, exp_fl)

    cat(paste("\nRemove CALLs xml files and move", exp_fl, "to data storage\n"))
}


stop()

## parse all xml sms logs ##

old_files <- list.files(path = data_folder,
                        pattern = "sms.*\\.xml",
                        full.names = T,
                        recursive = T)

gather <- data.frame()
if (length(old_files) > 0) {
    for ( af in old_files) {
        cat(paste(af), sep = "\n")

        ## read a file
        data  <- xmlParse(af)
        dd    <- xmlToList(data)

        ## create dataframe from uneven rows
        for (aa in dd) {
            gather <- plyr::rbind.fill(gather, data.frame(t(aa)))
        }
    }
    ## clean often too many dups
    gather <- unique( gather )

    stop()
    ## clean calls logs
    gather$backup_set  <- NULL
    gather$backup_date <- NULL
    gather <- gather[ !(is.na(gather$date) & is.na(gather$number)), ]
    vec    <- vapply(gather, function(x) length(unique(x)) > 1, logical(1L))
    gather <- gather[ , vec ]

    ## store xml data
    exp_fl <- paste0(data_folder,"/SMS_xml_",format(Sys.time(),"%F_%T"))
    write_dat(gather, exp_fl)
    write_RDS(gather, exp_fl)

    cat(paste("\nRemove SMSs xml files and move", exp_fl, "to data storage\n"))
}





####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
