source("renv/activate.R")

## Set default to compile packages for performance
R_COMPILE_PKGS <- 3

## Print more digits of dates
options("digits.secs" = 1 )

## Renv options
options(renv.config.auto.snapshot    = TRUE)
options(renv.config.updates.check    = TRUE)
options(renv.config.updates.parallel = 4   )

## Set default repo
options(repos = c(CRAN = "https://cran.rstudio.com"))

## Colorize terminal output
# devtools::install_github("https://github.com/jalvesaq/colorout")
# require(colorout, quietly = TRUE, warn.conflicts = FALSE )

## Don't ask to save workspace on R console exit
utils::assignInNamespace(
    "q",
    function(save = "no", status = 0, runLast = TRUE) {
        .Internal(quit(save, status, runLast)) },
    "base"
)

## Set tags to detect in rstudio
options(todor_patterns = c("FIXME", "TODO", "CHANGED", "IDEA", "HACK", "NOTE", "REVIEW", "BUG", "QUESTION", "COMBAK", "TEMP", "FIX ME", "TEST"))

## short term history
try(loadhistory("/tmp/Rhistory"), silent = TRUE)
.First <- function() try(loadhistory("/tmp/Rhistory"), silent = TRUE)
.Last  <- function() try(savehistory("/tmp/Rhistory"), silent = TRUE)

