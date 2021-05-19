#!/usr/bin/env Rscript

#### Create links of the sorted by location gpx files

####_ Set environment _####
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()

library(data.table)

## read vars
source("~/CODE/gpx_tools/gpx_db/DEFINITIONS.R")

outputrep     <- "~/ZHOST/Gpx_by_location/"

fl_localized  <- paste0(baseoutput,"/Location_list.Rds")

data <- readRDS(fl_localized)

##TODO filter out some files
data[FN<2]
data[FN/N>0.1]

####  Create sorted links of characterized files  ##############################

unlink(outputrep, recursive = TRUE)
dir.create(path = outputrep)
# dir.create(path = polarrep)

for (ar in unique(data$Region)) {
    cat(paste("Region:", ar,"\n"))

    temp <- data[Region==ar]
    Name <- gsub(" +","_",ar)

    ## create folder name
    dir <- paste0(outputrep,Name)

    for (af in unique(temp$file)) {
        cat(paste("File:", af,"\n"))

        # ## Check if file name comes from polar folder
        # if (grepl("/Polar/", af)) {
        #     ## alternative folder
        #     dir <- paste0(polarrep,"/",Name)
        #     dir.create(dir, showWarnings = FALSE, recursive = T)
        #
        #     if (file.exists(af)) {
        #         target <- paste0(dir,"/",basename(af))
        #         ## resovlve files with same name
        #         if (file.exists(target)) {
        #             target <- paste0(tools::file_path_sans_ext(target),"_c.",tools::file_ext(target))
        #         }
        #         file.symlink(af, target )
        #     }
        # } else {

        if (file.exists(af)) {
            target <- paste0(outputrep,"/",Name,"/",basename(af))
            dir.create(dirname(target), showWarnings = FALSE, recursive = T)
            ## resolve files with same name
            if (file.exists(target)) {
                target <- paste0(tools::file_path_sans_ext(target),"_c.",tools::file_ext(target) )
            }
            file.symlink(af, target )
        }
        # }
    }
    ## Create gathered gpx file
    system(paste(gather_command,dir))
}

## copy long plans as is
file.symlink("~/GISdata/GPX/Plans/LONG",
             "~/ZHOST/Gpx_by_location/LONG")
system(paste(gather_command, "~/ZHOST/Gpx_by_location/LONG"))
## copy all plans as is
file.symlink("~/GISdata/GPX/Plans",
             "~/ZHOST/Gpx_by_location/PLANS")
system(paste(gather_command, "~/ZHOST/Gpx_by_location/PLANS"))


####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
