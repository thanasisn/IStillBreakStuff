#!/usr/bin/env Rscript

####  Dump *.parquet files to a table in terminal

Sys.setenv(TZ = "UTC")
library(arrow, warn.conflicts = FALSE, quietly = TRUE)

args <- commandArgs(TRUE)

suppressPackageStartupMessages(
    USE_GDATA <- require(gdata, quietly = TRUE, warn.conflicts = FALSE)
)

for (fl in args) {
    if (!file.exists(fl)) {
        warning(paste("NOT A FILE:",fl))
    } else {
        ## read file
        tmp <- try(read_parquet(fl))
        cat("\r\n")
        cat("## file:",fl,"\r\n")
        cat("\r\n")
        if (USE_GDATA) {
            suppressPackageStartupMessages(library(gdata))
            ## use a nicer formatter
            write.fwf(x = tmp,
                      append   = FALSE,
                      quote    = FALSE,
                      sep      = " ",     ## we want a tight view of the data
                      eol      = "\r\n",  ## for unfortunate people with windows
                      na       = "NA",
                      rownames = FALSE,
                      colnames = TRUE,
                      qmethod  = c("escape", "double")
            ## TODO maybe this don't needs gdata
            ## Pipe it to   ... | column -t -s ";" -o " "
            ## Pipe it to   ... | sed '/#.*/d' | column -t -s ";" -o " "
            )
        } else {
            ## output to terminal with native tool
            write.table(x            = format(tmp),
                        append       = FALSE,
                        quote        = FALSE,
                        sep          = " ",     ## we want a tight view of the data
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
