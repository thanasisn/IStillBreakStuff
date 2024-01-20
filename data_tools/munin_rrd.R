#!/opt/R/4.2.3/bin/Rscript
# /* Copyright (C) 2022-2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:         "Project performance monitoring"
#' author:        "Natsis Athanasios"
#' documentclass: article
#' classoption:   a4paper,oneside
#' fontsize:      10pt
#' geometry:      "left=0.5in,right=0.5in,top=0.5in,bottom=0.5in"
#'
#' link-citations:  yes
#' colorlinks:      yes
#'
#' header-includes:
#' - \usepackage{caption}
#' - \usepackage{placeins}
#' - \captionsetup{font=small}
#'
#' output:
#'   bookdown::pdf_document2:
#'     number_sections:  no
#'     fig_caption:      no
#'     keep_tex:         no
#'     latex_engine:     xelatex
#'     toc:              yes
#'     toc_depth:        4
#'     fig_width:        8
#'     fig_height:       5
#'   html_document:
#'     toc:        true
#'     fig_width:  7.5
#'     fig_height: 5
#'
#' date: "`r format(Sys.time(), '%F')`"
#'
#' ---


#'
#+ echo=F, include=T


#+ echo=F, include=F
## __ Document options ---------------------------------------------------------
knitr::opts_chunk$set(comment   = ""      )
knitr::opts_chunk$set(dev       = "pdf"   )
knitr::opts_chunk$set(out.width = "100%"  )
knitr::opts_chunk$set(fig.align = "center")
knitr::opts_chunk$set(fig.pos   = "!h"    )


## __ Set environment  ---------------------------------------------------------
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/data_tools/munin_rrd.R"

if (!interactive()) {
    pdf( file = paste0("~/BBand_LAP/REPORTS/RUNTIME/", basename(sub("\\.R$", ".pdf", Script.Name))))
    sink(file = paste0("~/BBand_LAP/REPORTS/RUNTIME/", basename(sub("\\.R$", ".out", Script.Name))), split = TRUE)
}


## __ Load libraries  ----------------------------------------------------------
library(data.table, warn.conflicts = FALSE, quietly = TRUE)
library(pander,     warn.conflicts = FALSE, quietly = TRUE)
library(gdata,      warn.conflicts = FALSE, quietly = TRUE)
library(ggplot2,    warn.conflicts = FALSE, quietly = TRUE)
library(rrd,        warn.conflicts = FALSE, quietly = TRUE)
library(tidyverse,  warn.conflicts = FALSE, quietly = TRUE)


# remotes::install_github("andrie/rrd")


readRRD <- function(file) {
    data   <- read_rrd(file)
    vars   <- unique(sub("[0-9]*$", "", names(data)))
    gather <- data.table()
    for (avar in vars) {
        colunns  <- grep(avar, names(data), value = TRUE)
        datapart <-  data.table(bind_rows(data[colunns]))
        datapart$timestamp <- as.POSIXct(datapart$timestamp)

        names(datapart) <- c("Date", avar)

        if (nrow(gather) == 0) {
            gather <- datapart
        } else {
            gather <- merge(gather, datapart, by = "Date")
        }
    }
    return(gather)
}



## Start with the munin storage
repo <- switch(Sys.info()["nodename"],
               tyler = "/var/lib/munin",
               "/var/lib/munin")
stopifnot(dir.exists(repo))

hostsrepos <- grep("cgi-tmp|\\..*",
                   list.dirs(repo, full.names = T, recursive = F),
                   value = TRUE, invert = TRUE )


## get all files
allfiles <- list.files(hostsrepos,
                       full.names  = TRUE,
                       recursive   = TRUE,
                       include.dirs = FALSE)

## parse all variables groups and host
ff           <- data.frame(files = allfiles)
ff$hostname  <- sub("-[a-z]*.*", "", basename(ff$files))
ff$datagroup <- sub("[_-].*", "", sub("^[a-z]*-", "", basename(ff$files)))
ff$var       <- apply(ff, 1, function(x) sub( x[["hostname"]], "", basename(x[["files"]])))
ff$var       <- apply(ff, 1, function(x) sub( x[["datagroup"]], "", x[["var"]]))
ff$var       <- sub(".rrd$",  "", ff$var)
ff$var       <- sub("^[-_]+", "", ff$var)
ff$var       <- gsub("[-_]+", " ", ff$var)
ff           <- data.table(ff)


unique(ff$hostname)
unique(ff$datagroup)
unique(ff$var)



#'
#' ## S.M.A.R.T.
#'
#+ echo=F, include=T, results = "asis"
ss <- ff[datagroup == "smart"]

for (af in 1:nrow(ss)) {
    ll <- ss[af,]

    if (!file.exists(ll$files)) next()

    data <- data.table(readRRD(ll$files))

    hostname  <- ll$hostname
    datagroup <- ll$datagroup
    variable  <- ll$var

    # cat(paste(hostname, "-", datagroup, "-",  variable),"\n" )

    ## skip empty
    if (all(is.na(data$AVERAGE))) {
        cat("\nNo DATA, Skip:", ll$files, "\n")
        next()
    }

    ## Skip same data
    if (all(apply(data[, -"Date"], 2, function(x) sum(!is.na(unique(x))) <= 1 ))) {
        cat("\nNo Data Variation, Skip:", basename(ll$files), "\n\n")
        next()
    }

    ## Reshape for plot
    d <- melt(data, id.vars = "Date")

    ## Plot
    p <- ggplot(d, aes(Date, value, col = variable)) +
        geom_point() +
        labs(
            y        = variable,
            x        = "",
            title    = variable,
            subtitle = paste(hostname, datagroup),
            caption  = variable) +
        stat_smooth() +
        theme_bw()
    suppressWarnings(print(p))

    cat(" \n \n")
}





#'
#' ## Failure Warning blackblaze S.M.A.R.T. tags
#'
#+ echo=F, include=T, results = "asis"

# |   5 | Reallocated_Sector_Count.      |
# | 187 | Reported_Uncorrectable_Errors. |
# | 188 | Command_Timeout.               |
# | 197 | Current_Pending_Sector_Count.  |
# | 198 | Offline_Uncorrectable.         |

sel <- unique(c(
    agrep("Reallocated_Sector_Count",      basename(ff$files), ignore.case = T),
    agrep("Reported_Uncorrectable_Errors", basename(ff$files), ignore.case = T),
    agrep("Command_Timeout",               basename(ff$files), ignore.case = T),
    agrep("Current_Pending_Sector_Count",  basename(ff$files), ignore.case = T),
    agrep("Offline_Uncorrectable",         basename(ff$files), ignore.case = T),
    agrep("Reallocated Sector Count",      basename(ff$var),   ignore.case = T),
    agrep("Reported Uncorrectable Errors", basename(ff$var),   ignore.case = T),
    agrep("Command Timeout",               basename(ff$var),   ignore.case = T),
    agrep("Current Pending Sector Count",  basename(ff$var),   ignore.case = T),
    agrep("Offline Uncorrectable",         basename(ff$var),   ignore.case = T)
))


rr <- ff[sel,]

for (af in 1:nrow(rr)) {
    ll <- rr[af,]

    if (!file.exists(ll$files)) next()

    data <- readRRD(ll$files)

    hostname  <- ll$hostname
    datagroup <- ll$datagroup
    variable  <- ll$var

    cat(paste(hostname, "-", datagroup, "-",  variable),"\n" )

    ## skip empty
    if (all(is.na(data$AVERAGE))) {
        cat("\nNo DATA, Skip:", ll$files, "\n")
        next()
    }

    ## Skip same data
    if (all(apply(data[, -"Date"], 2, function(x) sum(!is.na(unique(x))) <= 1 ))) {
        cat("\nNo Data Variation, Skip:", basename(ll$files), "\n\n")
        next()
    }

    d <- melt(data, id.vars = "Date")

    # Everything on the same plot
    p <- ggplot(d, aes(Date, value, col = variable)) +
        geom_point() +
        labs(
            y        = variable,
            x        = "",
            title    = variable,
            subtitle = paste(hostname, datagroup),
            caption  = variable) +
        stat_smooth() +
        theme_bw()
    suppressWarnings(print(p))

    cat(" \n \n")
}





#'
#' ## Plot temperatures
#'
#+ echo=F, include=T, results = "asis"

sel <- unique(c(
    agrep("temp",    ff$var, ignore.case = TRUE),
    agrep("thermal", ff$var, ignore.case = TRUE)
))

tt <- ff[c(sel, which(datagroup == "hddtemp")), ]
tt <- tt[var != "system d"]
tt <- tt[datagroup != "df"]

for (ahost in unique(tt$hostname)) {
    for (agroup in unique(tt$datagroup)) {

        cat(paste("\n### ", ahost, agroup, "\n\n" ))

        pp <- tt[datagroup == agroup & hostname == ahost]

        if (nrow(pp) < 1) next()

        gather <- data.frame()

        for (af in 1:nrow(pp)) {
            ll       <- pp[af]
            data     <- readRRD(ll$files)
            data$var <- ll$var
            gather   <- rbind(gather, data)
        }

        gather[ AVERAGE <= 0, AVERAGE := NA ]
        gather[ MAX     <= 0, MAX     := NA ]
        gather[ MIN     <= 0, MIN     := NA ]

        # Everything on the same plot
        p <- ggplot(gather, aes(Date, MAX, col = var)) +
            geom_point() +
            labs(
                title    = paste(ahost, "MAX"),
                subtitle = agroup) +
            stat_smooth() +
            theme_bw()
        suppressWarnings(print(p))

        cat(" \n \n")

        p <- ggplot(gather, aes(Date, AVERAGE, col = var)) +
            geom_point() +
            labs(
                title    = paste(ahost, "AVERAGE"),
                subtitle = agroup) +
            stat_smooth() +
            theme_bw()
        suppressWarnings(print(p))

        cat(" \n \n")
    }
}










#'
#' ## Plot the rest
#'
#+ echo=F, include=T, results = "asis"
ff <- ff[ !files %in% rr$files, ]
ff <- ff[ !files %in% tt$files, ]
ff <- ff[ !files %in% ss$files, ]

for (af in 1:nrow(ff)) {
    ll <- ff[af,]

    if (!file.exists(ll$files)) next()

    data <- data.table(readRRD(ll$files))

    hostname  <- ll$hostname
    datagroup <- ll$datagroup
    variable  <- ll$var

    # cat(paste(hostname, "-", datagroup, "-",  variable),"\n" )

    ## skip empty
    if (all(is.na(data$AVERAGE))) {
        cat("\nNo DATA, Skip:", ll$files, "\n")
        next()
    }

    ## Skip same data
    if (all(apply(data[, -"Date"], 2, function(x) sum(!is.na(unique(x))) <= 1 ))) {
        cat("\nNo Data Variation, Skip:", basename(ll$files), "\n\n")
        next()
    }

    ## Reshape for plot
    d <- melt(data, id.vars = "Date")

    ## Plot
    p <- ggplot(d, aes(Date, value, col = variable)) +
        geom_point() +
        labs(
            y        = variable,
            x        = "",
            title    = variable,
            subtitle = paste(hostname, datagroup),
            caption  = variable) +
        # stat_smooth() +
        theme_bw()
    suppressWarnings(print(p))

    cat(" \n \n")
}




#' **END**
#+ include=T, echo=F
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n",Sys.time(),Sys.info()["login"],Sys.info()["nodename"],Script.Name,difftime(tac,tic,units="mins")))
