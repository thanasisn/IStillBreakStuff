#!/usr/bin/env Rscript

####  Dump *.Rds files to a csv like format

Sys.setenv(TZ = "UTC")

args <- commandArgs(TRUE)

for (fl in args) {
    if (!file.exists(fl)) {
        warning(paste("NOT A FILE:",fl))
    } else {
        ## read file
        tmp <- try(readRDS(fl))

        if (require(gdata,quietly = TRUE)) {
            ## use a nicer formatter
            gdata::write.fwf(x = tmp,
                             append   = FALSE,
                             quote    = FALSE,
                             sep      = " ; ",
                             eol      = "\r\n",  ## for unfortunate people with windows
                             na       = "NA",
                             rownames = FALSE,
                             colnames = TRUE,
                             qmethod  = c("escape", "double")
            )
        } else {
            ## output to terminal with native tool
            write.table(x            = format(tmp),
                        append       = FALSE,
                        quote        = FALSE,
                        sep          = " ; ",
                        eol          = "\r\n",  ## for unfortunate people with windows
                        na           = "NA",
                        dec          = ".",
                        row.names    = FALSE,
                        col.names    = TRUE,
                        qmethod      = c("escape", "double"),
                        fileEncoding = ""
            )
        }
        cat("\r\n")
    }
}
