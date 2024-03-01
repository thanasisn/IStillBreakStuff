# /* Copyright (C) 2022-2024 Athanasios Natsis <natsisphysicist@gmail.com> */


#' List R dependencies for files or folders
#'
#' @param source_code      File or directory path to read.
#' @param output           Output file of dependencies.
#' @param output_overwrite If file exist, force overwrite.
#'
#' @details                It used `renv` to find dependencies.
#'
#' @return                 Terminal output and/or an output file.
#' @export
#'
listDependencies <- function(source_code,
                             output = "Dependencies.md",
                             output_overwrite = TRUE) {

  WRITE <- TRUE

  ## Check input
  if (!file.exists(source_code)) {
    cat("\nSource code path don't exist:", source_code, "\n")
    cat("Ignoring function call\n")
    return(NULL)
  }

  ## Check output
  if (file.exists(output) & output_overwrite == FALSE) {
    cat("\nOutput exist:", output, "\n")
    cat("And 'output_overwrite' =", output_overwrite, "\n")
    cat("Will not write output\n")
    WRITE <- FALSE
  }

  ## Get dependencies
  require(renv, quietly = TRUE, warn.conflicts = FALSE)
  pkgs <- dependencies(
    path  = source_code,
    quiet = TRUE
  )

  ## Display
  cat("\nDependencies for:", source_code, "\n")
  cat("At:", paste(Sys.Date()), "\n")
  cat("\n", R.version.string, "\n\n")
  ## TODO handle packageVersion can not find installed package due to environment
  for (ap in unique(pkgs$Package)) {
    cat(sprintf("%16s:  %-8s\n", ap, packageVersion(ap)))
  }

  ## Save to file
  if (WRITE == TRUE) {
    cat("\nDependencies for:", source_code, "\n", file = output)
    cat("At:", paste(Sys.Date()), "\n", file = output, append = TRUE)
    cat("\n", R.version.string, "\n\n", file = output, append = TRUE)
    ## TODO handle packageVersion can not find installed package due to environment
    for (ap in unique(pkgs$Package)) {
      cat(sprintf("%16s:  %-8s\n", ap, packageVersion(ap)), file = output, append = TRUE)
    }
    cat("\nOutput written to:", output, "\n")
  }
}

