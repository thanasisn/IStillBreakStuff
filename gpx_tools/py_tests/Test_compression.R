#!/opt/R/4.2.3/bin/Rscript
# /* Copyright (C) 2022-2023 Athanasios Natsis <natsisphysicist@gmail.com> */

#### Test the compression of the BB data base

## __ Set environment  ---------------------------------------------------------
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/Test_compression.R"



library(arrow,      warn.conflicts = TRUE, quietly = TRUE)
library(dplyr,      warn.conflicts = TRUE, quietly = TRUE)
library(lubridate,  warn.conflicts = TRUE, quietly = TRUE)
library(data.table, warn.conflicts = TRUE, quietly = TRUE)
library(ggplot2,    warn.conflicts = TRUE, quietly = TRUE)
library(plotly,     warn.conflicts = TRUE, quietly = TRUE)


for (algo in c("gzip", "brotli", "zstd", "lz4", "lzo", "bz2")) {
    if (codec_is_available(algo)) {
        cat("AVAILABLE:", algo, "\n")
    } else {
        cat("NOT available:", algo, "\n")
    }
}


results <- "~/CODE/gpx_tools/py_tests/DB_compression_test.Rds"
DATASET <- "/home/athan/ZHOST/testfit"

DB <- open_dataset(DATASET,
                   partitioning  = c("year", "month"),
                   unify_schemas = T)
currentsize <- as.numeric(strsplit(system(paste("du -s", DATASET), intern = TRUE), "\t")[[1]][1])



gatherDB    <- data.frame()

for (algo in c("gzip", "brotli", "zstd", "lz4", "lzo")) {
  if (codec_is_available(algo)) {
    targetdb <- paste0(DATASET, "_temp")
    # for (comLev in c(2, 3, 5, 7, 9, 10, 11, 20)) {
    for (comLev in unique(c(1:11, 20, 50))) {
      cat("Algo: ", algo, " Level:", comLev, "\n")
      try({
        ## remove target dir
        system(paste("rm -rf ", targetdb))
        ## try compression
        aa <- system.time(
          write_dataset(DB, path          = targetdb,
                        compression       = algo,
                        compression_level = comLev,
                        format            = "parquet",
                        partitioning      = c("year", "month"),
                        hive_style        = FALSE),
          gcFirst = TRUE
        )
        ## gather stats
        temp <- data.frame(
          Date = Sys.time(),
          Host = Sys.info()["nodename"],
          User = aa[1],
          Syst = aa[2],
          Elap = aa[3],
          Algo = algo,
          Level = comLev,
          Size = as.numeric(strsplit(system(paste("du -s", targetdb), intern = TRUE), "\t")[[1]][1])
        )

        cat(temp$Algo,
            "level:", temp$Level,
            "Elap:",  temp$Elap,
            "Size:",  temp$Size,
            "Ratio:", temp$Size / currentsize,
            "\n")
        temp$Ratio   <- temp$Size / currentsize
        temp$Current <- currentsize
        gatherDB     <- data.table(
          rbind(gatherDB, temp)
        )

        ## Gather results
        if (!file.exists(results)) {
          saveRDS(gatherDB, results)
          cat("Data saved\n")
        } else {
          DATA <- readRDS(results)
          DATA <- unique(
            rbind(DATA, gatherDB, fill = TRUE)
          )
          saveRDS(DATA, results)
          cat("Data saved again\n")
        }
      })
    }
  }
}
stop()

DATA <- readRDS(results)

# DATA <- DATA[Host == "sagan",   ]
# DATA <- DATA[Current > 2000000, ]
DATA <- DATA[User    < 100,     ]
DATA <- DATA[Ratio   <   1,     ]
DATA <- DATA[Ratio   <  .7,     ]
DATA <- DATA[Size    >  20,     ]
DATA <- DATA[Date > "2023-12-01"]
# DATA[, col := 1 + as.numeric(factor(Algo))]


table(DATA$Current)

setorder(DATA, -Ratio, -Elap)
print(DATA)


p <- ggplot(DATA, aes(Level, Ratio, size = Current, color = Algo)) +
    geom_point() +
    theme_bw()
print(p)
ggplotly(p)


p <- ggplot(DATA, aes(Ratio, User,  size = Level, color = Algo)) +
    geom_point() +
    theme_bw()
print(p)
ggplotly(p)


p <- ggplot(DATA, aes(Ratio, Current, size = Level, color = Algo)) +
    geom_point() +
    theme_bw()
print(p)
ggplotly(p)



tac <- Sys.time()
cat(sprintf("%s %s@%s %s %f mins\n\n",Sys.time(),Sys.info()["login"],Sys.info()["nodename"],Script.Name,difftime(tac,tic,units="mins")))
