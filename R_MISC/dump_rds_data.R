#!/usr/bin/env Rscript
# /* Copyright (C) 2022 Athanasios Natsis <natsisthanasis@gmail.com> */

rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()

library(data.table, quietly = T, warn.conflicts = F)
library(optparse,   quietly = T, warn.conflicts = F)



args = commandArgs(trailingOnly=TRUE)
print(paste(args))


option_list <-  list(
    make_option(c("-o", "--output"),
                type    = "character",
                default = "csv",
                help    = paste0("export file type"),
                metavar = "yyyy-mm-dd")
)
opt_parser <- OptionParser(option_list = option_list)

print(opt_parser)


args       <- parse_args(opt_parser)


## read file
## dump data
## export to file formats
##
##
##
