#!/usr/bin/env Rscript

#### Parse xml logs from phone
## Data in xml files created by "SMS Backup & Restore" app

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


## root of all xml files
data_folder = "~/LOGs/sms/"



## Parse all xml call logs #####################################################

## Better use bash tools to merge files before parsing
# grep -h "<call " ./call/call*.xml | sort -u > Callall.xml

# old_files <- list.files(path = data_folder,
#                         pattern = "calls.*\\.xml",
#                         full.names = T,
#                         recursive = T)
old_files <- c("~/LOGs/sms/Callall.xml")

gather <- data.frame()
if (!file.exists(old_files[1])) {
    cat(paste("NO CALL FILES\n"))
} else {
    if (length(old_files) > 0) {
        for ( af in old_files) {
            cat(paste(af), sep = "\n")

            ## read a file
            data  <- xmlParse(af)
            dd    <- xmlToList(data)

            ##FIXME this is slow
            ## create dataframe from uneven rows
            for (aa in dd) {
                gather <- plyr::rbind.fill(gather, data.frame(t(aa), stringsAsFactors = FALSE))
            }
        }
        ## clean often too many dups
        gather <- unique( gather )

        ## clean calls logs
        gather$backup_set  <- NULL
        gather$backup_date <- NULL
        gather$post_dial_digits[gather$post_dial_digits == "" ]     <- NA
        gather$post_dial_digits[gather$post_dial_digits == "null" ] <- NA
        gather$post_dial_digits[is.null(gather$post_dial_digits)]   <- NA

        gather$subscription_component_name[ gather$subscription_component_name == "null" ] <- NA
        gather$subscription_component_name[ gather$subscription_component_name == "com.android.phone/com.android.services.telephony.TelephonyConnectionService" ] <- NA

        unique( gather$post_dial_digits )

        gather <- gather[ !(is.na(gather$date) & is.na(gather$number)), ]
        vec    <- vapply(gather, function(x) length(unique(x)) > 1, logical(1L))
        gather <- gather[ , vec ]

        gather <- unique( gather )

        ## untested ignore different formating of readable date
        # gather <- gather[!duplicated(gather[,!(names(gather) %in% c("readable_date"))]),]

        # as.POSIXct(as.numeric(gather$date), origin = "1970-01-01")

        ## store xml data
        exp_fl <- paste0(data_folder,"/Calls_xml_",format(Sys.time(),"%F_%T"))
        write_dat(gather, exp_fl)
        write_RDS(gather, exp_fl)

        cat(paste("\nRemove CALLs xml files and move", exp_fl, "to data storage\n"))
    }
}


## Parse all xml sms logs ######################################################

## Better use bash tools to merge files before parsing
# grep -h "<sms " ./sms/sms*.xml | sort -u > SMSall.xml

##FIXME remove sms and keel mms entries in files
# find . -name "*" -type f | xargs sed -i -e '/ <sms pr/d'


# old_files <- list.files(path = data_folder,
#                         pattern = "sms.*\\.xml",
#                         full.names = T,
#                         recursive = T)

old_files <- c("~/LOGs/sms/SMSall.xml")

gather <- data.frame()
if (!file.exists(old_files[1])) {
    cat(paste("NO CALL FILES\n"))
} else {
    if (length(old_files) > 0) {
        for ( af in old_files) {
            cat(paste(af), sep = "\n")

            ## read a file
            data  <- xmlParse(af)
            dd    <- xmlToList(data)

            ##FIXME this is slow
            ## create dataframe from uneven rows
            for (aa in dd) {
                gather <- plyr::rbind.fill(gather, data.frame(t(aa), stringsAsFactors = FALSE))
            }
        }
        ## clean often too many dups
        gather <- unique( gather )

        ## clean calls logs
        gather$backup_set  <- NULL
        gather$backup_date <- NULL
        gather$read        <- NULL
        gather$sub_id      <- NULL

        gather <- gather[ !is.na(gather$date) , ]
        vec    <- vapply(gather, function(x) length(unique(x)) > 1, logical(1L))
        gather <- gather[ , vec ]

        gather <- unique( gather )
        ## ignore different formatting of readable date
        gather <- gather[!duplicated(gather[,!(names(gather) %in% c("readable_date"))]),]

        # as.POSIXct(as.numeric(gather$date), origin = "1970-01-01")

        ## store xml data
        exp_fl <- paste0(data_folder,"/SMS_xml_",format(Sys.time(),"%F_%T"))
        write_dat(gather, exp_fl)
        write_RDS(gather, exp_fl)

        # cat(paste("\nRemove CALLs xml files and move", exp_fl, "to data storage\n"))
    }
}


####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
