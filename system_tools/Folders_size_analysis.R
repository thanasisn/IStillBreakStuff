# /* #!/usr/bin/env Rscript */
# /* Copyright (C) 2023 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "Folders Disk Usage"
#'
#' author: "Natsis Athanasios"
#'
#' output:
#'   html_document:
#'     toc: true
#'     fig_width:  9
#'     fig_height: 4
#'   pdf_document:
#'
#' date: "`r format(Sys.time(), '%F')`"
#' ---


#+ echo=F, include=T
rm(list = (ls()[ls() != ""]))
Script.Name <- "~/CODE/system_tools/Folders_size_analysis.R"
dir.create("./runtime/", showWarnings = FALSE)
Sys.setenv(TZ = "UTC")
## standard output
if (!interactive()) {
    pdf( file = paste0("/home/athan/LOGs/SYSTEM_LOGS/",  basename(sub("\\.R$",".pdf", Script.Name))))
    sink(file = paste0("/home/athan/LOGs/SYSTEM_LOGS/",  basename(sub("\\.R$",".out", Script.Name))), split = TRUE)
}
## error notification function
tic <- Sys.time()



## __ Document options ---------------------------------------------------------
knitr::opts_chunk$set(comment    = ""       )
# knitr::opts_chunk$set(dev        = c("pdf", "png"))
knitr::opts_chunk$set(dev        = "png"    )
knitr::opts_chunk$set(out.width  = "100%"   )
knitr::opts_chunk$set(fig.align  = "center" )
knitr::opts_chunk$set(cache      =  FALSE   )  ## !! breaks calculations
knitr::opts_chunk$set(fig.pos    = '!h'     )

## __  Set environment ---------------------------------------------------------
require(data.table, quietly = TRUE, warn.conflicts = FALSE)
require(stringr,    quietly = TRUE, warn.conflicts = FALSE)
require(ggplot2,    quietly = TRUE, warn.conflicts = FALSE)
require(plotly,     quietly = TRUE, warn.conflicts = FALSE)
require(DT,         quietly = TRUE, warn.conflicts = FALSE)


#+ echo=F, include=T

data_fl      <- paste0("/home/athan/LOGs/SYSTEM_LOGS/Log_folders_size_", Sys.info()["nodename"], ".Rds")

datafls <- list.files(path         = "/home/athan/LOGs/SYSTEM_LOGS",
                      pattern      = "Log_folders_size_.*.Rds",
                      full.names   = TRUE,
                      recursive    = FALSE,
                      include.dirs = FALSE)
datafls <- sort(datafls)

##  Analysis  -----------------------------------------------

af <- datafls[1] # blue
af <- datafls[3] # tyler
af <- datafls[4] # yperos
af <- datafls[2] # sagan

# for (af in datafls) {
host <- sub("Log_folders_size_", "", sub(".Rds", "", basename(af)))
DATA <- data.table(readRDS(af))



#'
#' # `r host`
#'
#+ echo=F, include=T

## clean and prepare
DATA       <- DATA[ size > 2, ]
DATA$Bytes <- gdata::humanReadable(DATA$size)
DATA$Date  <- as.Date(DATA$Date, origin = "1970-01-01")
DATA[, Depth := str_count(file, "/")]


## keep the oldest unchanged row only
## assume the size is constant since last day
DATA <- DATA[DATA[, .I[which.min(Date)], by = .(file, size) ]$V1, ]

# ALL <- DATA

## just for the first run of the log
if (length(unique(DATA$Date)) == 1) cc <- 0
if (length(unique(DATA$Date)) != 1) cc <- 1


## keep only folder with changed size
DATA <- DATA[DATA[, .I[.N > cc], by = .(file)]$V1, ]

# if (nrow(DATA) > 0){

## TODO check not changing folder

# cat(length(unique(DATA$file)), "Folders with changed size\n")

#'
#' ### `r length(unique(DATA$file))` Folders with changed size
#'
#+ echo=F, include=T

DATA[, Ratio   := size / min(size), by = file]
DATA[, Diff_MB := as.integer((size - min(size)) / 1024 ^ 2), by = file]


## to monitor absolute change
p <- ggplot(DATA,
            aes(x = Date, y = Diff_MB, colour = file)) +
  geom_line() +
  theme(legend.position = "none")

p <- add_trace(p, x = DATA$Date, y = DATA$Diff_MB,
               # text      = DATA$file,
               # name      = DATA$file,
               hoverinfo = "text",
               mode      = "lines",
               type      = "scatter")
ggplotly(p)


## to monitor relative change
p <- ggplot(DATA,
            aes(x = Date, y = Ratio, colour = file)) +
  geom_line() +
  theme(legend.position = "none")

p <- add_trace(p, x = DATA$Date, y = DATA$Ratio,
               # text      = DATA$file,
               # name      = DATA$file,
               hoverinfo = "text",
               mode      = "lines",
               type      = "scatter")
ggplotly(p)


## bigest by depth

#+ include=FALSE
htmltools::tagList(datatable(cars))
htmltools::tagList(ggplotly(ggplot()))

library(kableExtra)

#+ results='asis', echo = F
for (ad in sort(unique(DATA$Depth))) {

  temp <- DATA[DATA[Depth == ad, .I[which.max(Date)], by = file]$V1, ]

  setorder(temp, -size)
  temp$size  <- NULL
  # temp$Date  <- NULL
  temp$Depth <- NULL
  temp$Ratio <- round(temp$Ratio, 3)

  cat(paste("\n## Depth: ", ad, "\n\n"))

  # temp <- head(temp, 20)

  # cat(pander::pander(temp))

  # print(
  #   temp %>%
  #     kbl() %>%
  #     kable_material(c("striped", "hover")) |>
  #     kable_styling(bootstrap_options = c("striped", "hover"))
  # )
  cat("\n\n")

  print(htmltools::tagList(
    datatable(temp,
              colnames = c('ID' = 1),
              options = list(pageLength = 30),
              style = 'bootstrap',
              class = 'table-bordered table-condensed')
  ))

}


# }

## % change per day
## % total change
## min max current

## Table and plots
## the most offendin


# }






#' **END**
#+ include=T, echo=F
tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
