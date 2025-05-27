#!/usr/bin/env Rscript

#### Parse xml logs from phone
## Data in xml files created by "SMS Backup & Restore" app

####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/data_tools/gather_xml_phone_logs.R"
if (!interactive()) {
    pdf( file = paste0(sub("\\.R$",".pdf", Script.Name)))
    sink(file = paste0(sub("\\.R$",".out", Script.Name)), split = TRUE)
}

library(XML)
source("~/CODE/R_myRtools/myRtools/R/write_.R")
# library(myRtools)
# library(data.table)

## root of all xml files
data_folder = "~/DATA_ARC/08_Chats/SMS_CALLS/"
data_folder = "/home/athan/MISC/a34_export/SMS_calls"

##  Gather all xml call logs  --------------------------------------------------
old_files <- list.files(path = data_folder,
                        pattern = "calls.*\\.xml",
                        full.names = TRUE,
                        recursive  = TRUE)

old_files <- sort(old_files)

batch <- 66
if (length(old_files) > batch) {
    old_files <- sort(old_files)[1:batch]
}

gather <- data.frame()
if (!file.exists(old_files[1])) {
    cat(paste("NO CALL FILES\n"))
} else {
    if (length(old_files) > 1) {
        old_files <- old_files[1:(length(old_files) - 1)]
        for (af in old_files) {
            cat(paste(af), sep = "\n")

            ## read a file
            data <- xmlParse(af)
            dd   <- xmlToList(data)

            ## create dataframe from uneven rows
            for (aa in dd) {
                gather <- plyr::rbind.fill(gather, data.frame(t(aa), stringsAsFactors = FALSE))
            }

            ## clean often too many dups
            gather$backup_date <- NULL
            gather$backup_set  <- NULL
            gather$count       <- NULL
            gather <- unique(gather)

        }

        if (nrow(gather) > 0) {
            ## store xml data
            exp_fl <- paste0(data_folder,"/Calls_",format(Sys.time(),"%F_%T"))
            write_dat(gather, exp_fl, clean = TRUE)
            write_RDS(gather, exp_fl, clean = TRUE)
            ## remove files
            file.remove(old_files)
        }
    }
}



##  Gather all xml sms logs  ---------------------------------------------------

old_files <- list.files(path = data_folder,
                        pattern = "sms.*\\.xml",
                        full.names = TRUE,
                        recursive  = TRUE)
old_files <- sort(old_files)

batch <- 66
if (length(old_files) > batch) {
    old_files <- sort(old_files)[1:batch]
}


gather <- data.frame()
if (!file.exists(old_files[1])) {
    cat(paste("NO SMS FILES\n"))
} else {
    if (length(old_files) > 1) {
        old_files <- old_files[1:(length(old_files) - 1)]
        for (af in old_files) {
            cat(paste(af), sep = "\n")

            ## read a file
            data <- xmlParse(af)
            dd   <- xmlToList(data)

            ##FIXME this is slow
            ## create dataframe from uneven rows
            for (aa in dd) {
                gather <- plyr::rbind.fill(gather, data.frame(t(aa), stringsAsFactors = FALSE))
            }

            ## clean often too many dups
            gather$backup_date <- NULL
            gather$backup_set  <- NULL
            gather$count       <- NULL
            gather$read        <- NULL
            gather <- unique(gather)
        }

        if (nrow(gather) > 0) {
            ## store xml data
            exp_fl <- paste0(data_folder,"/SMS_",format(Sys.time(),"%F_%T"))
            write_dat(gather, exp_fl, clean = TRUE)
            write_RDS(gather, exp_fl, clean = TRUE)
            ## remove files
            file.remove(old_files)
        }

        # gather <- gather[!is.na(gather$date), ]
        # vec    <- vapply(gather, function(x) length(unique(x)) > 1, logical(1L))
        # gather <- gather[, vec]
        #
        # gather <- unique(gather)

        ## ignore different formatting of readable date
        # gather <- gather[!duplicated(gather[,!(names(gather) %in% c("readable_date"))]),]
    }
}



##  Combine all .Rds files  ----------------------------------------------------

old_files <- list.files(path = data_folder,
                        pattern = "^Calls_20[0-9].*\\.Rds",
                        full.names = TRUE,
                        recursive  = TRUE)

if (length(old_files) > 1) {
    gather <- data.frame()
    for (af in old_files) {
        temp   <- readRDS(af)
        gather <- unique(plyr::rbind.fill(gather, temp))
    }

    gather <- gather[order(gather$date), ]

    if (nrow(gather) > 0) {
        ## store xml data
        exp_fl <- paste0(data_folder,"/Calls_",format(Sys.time(),"%F_%T"))
        write_dat(gather, exp_fl, clean = TRUE)
        write_RDS(gather, exp_fl, clean = TRUE)
        ## remove files
        file.remove(old_files)
        file.remove( sub(".Rds", ".dat", old_files))
    }
}





old_files <- list.files(path = data_folder,
                        pattern = "^SMS_20[0-9].*\\.Rds",
                        full.names = TRUE,
                        recursive  = TRUE)

if (length(old_files) > 1) {
    gather <- data.frame()
    for (af in old_files) {
        temp   <- readRDS(af)
        gather <- unique(plyr::rbind.fill(gather, temp))
    }

    gather <- gather[order(gather$date), ]

    if (nrow(gather) > 0) {
        ## store xml data
        exp_fl <- paste0(data_folder,"/SMS_",format(Sys.time(),"%F_%T"))
        write_dat(gather, exp_fl, clean = TRUE)
        write_RDS(gather, exp_fl, clean = TRUE)
        ## remove files
        file.remove(old_files)
        file.remove( sub(".Rds", ".dat", old_files))
    }
}




#' **END**
#+ include=T, echo=F
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
if (interactive() & difftime(tac,tic,units = "sec") > 30) {
    system("mplayer /usr/share/sounds/freedesktop/stereo/dialog-warning.oga", ignore.stdout = T, ignore.stderr = T)
    system(paste("notify-send -u normal -t 30000 ", Script.Name, " 'R script ended'"))
}
