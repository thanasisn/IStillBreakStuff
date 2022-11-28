#!/usr/bin/env Rscript

#### Read data from Garmin Connect data dump


####_ Set environment _####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- tryCatch({ funr::sys.script() },
                        error = function(e) { cat(paste("\nUnresolved script name: ", e),"\n\n")
                            return("Garmin_read_dump") })

datalocation <- "~/ZHOST/ggg/504717a5-34a4-46c7-aa2c-3e34d7581984_1/DI_CONNECT/"


library(data.table)
library(jsonlite)



allfiles <- list.files(datalocation, recursive = TRUE, full.names = TRUE)
## drop empty files
allfiles <- allfiles[file.size(allfiles) > 10]

## show file types
table(sub( ".*\\.", "" , basename(allfiles)))



####  parse json  ####
jsonfls <- grep(".json$", allfiles, ignore.case = TRUE, value = TRUE)

jsonfls[file.size(jsonfls) <= 300]

## check and remove some files we don't care for
fromJSON(grep("user_profile", jsonfls, value = T), flatten = T)
jsonfls <- grep("user_profile", jsonfls, value = T, invert = T)

fromJSON(grep("social-profile", jsonfls, value = T), flatten = T)
jsonfls <- grep("social-profile", jsonfls, value = T, invert = T)

fromJSON(grep("user_contact", jsonfls, value = T), flatten = F)
jsonfls <- grep("user_contact", jsonfls, value = T, invert = T)

fromJSON(grep("UserGoal", jsonfls, value = T), flatten = F)
jsonfls <- grep("UserGoal", jsonfls, value = T, invert = T)

fromJSON(grep("_courses", jsonfls, value = T), flatten = F)
jsonfls <- grep("_courses", jsonfls, value = T, invert = T)

fromJSON(grep("_gear", jsonfls, value = T), flatten = T)
jsonfls <- grep("_gear", jsonfls, value = T, invert = T)

fromJSON(grep("_goal", jsonfls, value = T), flatten = T)
jsonfls <- grep("_goal", jsonfls, value = T, invert = T)

fromJSON(grep("_personalRecord", jsonfls, value = T), flatten = T)
jsonfls <- grep("_personalRecord", jsonfls, value = T, invert = T)

fromJSON(grep("_workout", jsonfls, value = T), flatten = T)
jsonfls <- grep("_workout", jsonfls, value = T, invert = T)




## groups of similar files
groups <- unique(sub("__", "", sub(".json", "", gsub( "[-[:digit:]]+", "", basename( jsonfls )))))
groups <- sub("_$","", sub("^_","", groups))
groups <- sub("dangas","", groups)


## parse all files
for (ag in groups) {
    pfiles <- agrep(ag, jsonfls, value = T)

    cat("\n\nGroup:", ag, length(pfiles),"\n")
    cat(pfiles,"\n")

    gather <- data.table()
    for (af in pfiles) {
        cat(basename(af),"\n")
        tmp    <- fromJSON(af, flatten = TRUE)
## if only one element unlist it
        stop()
        if (is.list(tmp)) {
            tmp$preferredLocale <- NULL
            tmp$handedness      <- NULL
            tmp <- list2DF(tmp)
            # tmp <- as.data.frame(do.call(cbind, tmp))
            # tmp <- as.data.frame(do.call(rbind, tmp))
            # tmp <- rbindlist(tmp, fill = T)
        }
        gather <- rbind(gather, tmp, fill = TRUE)
    }
    # gather <- unique(gather)
    assign(ag, gather)
    rm(gather, tmp)


}






####_ END _####
tac <- Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
