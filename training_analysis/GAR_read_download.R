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

allfiles <- allfiles[file.size(allfiles) > 10]



## file types
table(sub( ".*\\.", "" , basename(allfiles)))


####  parse json  ####
jsonfls <- grep(".json$", allfiles, ignore.case = TRUE, value = TRUE)

jsonfls[file.size(jsonfls) <= 300]


fromJSON(grep("user_profile", jsonfls, value = T), flatten = F)
jsonfls <- grep("user_profile", jsonfls, value = T, invert = T)

groups <- unique(sub( "__", "", sub(".json","", gsub( "[-[:digit:]]+", "", basename( jsonfls )))))


for (ag in groups) {
    pfiles <- agrep(ag, jsonfls, value = T)

    cat("\n\nGroup:", ag, length(pfiles),"\n")
    cat(pfiles,"\n")





}






####_ END _####
tac <- Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
