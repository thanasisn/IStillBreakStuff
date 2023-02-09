#!/usr/bin/env Rscript

####  Display info for *.Rds files

Sys.setenv(TZ = "UTC")

args <- commandArgs(TRUE)

for (fl in args) {
    if (!file.exists(fl)) {
        warning(paste("NOT A FILE:",fl))
    } else {
        cat(paste0(rep("=",nchar(fl)), collapse = ""), "\n")
        cat(paste(fl), "\n")
        tmp <- try(readRDS(fl))
        cat(paste0(rep("-", nchar(fl)), collapse = ""), "\n")
        cat(paste("Name   :", basename(fl)), "\n")
        cat(paste("Rows   :", nrow(tmp)),    "\n")
        cat(paste("Columns:", ncol(tmp)),    "\n")
        # cat(paste("[", 1:length(names(tmp)), "]", names(tmp)), sep = "\n")
        cat(paste0(" - str ", paste0(rep("-", nchar(fl) - 7), collapse = "")), "\n")
        cat(str(tmp, nchar.max = 200))
        cat("\n")
        cat(paste0(" - summary ",paste0(rep("-", nchar(fl) - 11), collapse = "")), "\n")
        print(summary(tmp), width = 120, na.print = "-NA-")
        cat("\n")
    }
}
