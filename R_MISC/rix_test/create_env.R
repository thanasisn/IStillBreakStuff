
## Build a nix environment for R using r

# install.packages("rix", repos = c(
#   "https://ropensci.r-universe.dev",
#   "https://cloud.r-project.org"
# ))

library("rix")

path_default_nix <- "."

rix(
  r_ver        = "4.3.3",
  r_pkgs       = c(
                   "data.table",
                   "dplyr",
                   "ggplot2",
                   "renv",
                  NULL),
  git_pkgs     = list(
                   list(package_name = "colorout",
                        repo_url     = "https://github.com/jalvesaq/colorout/",
                        commit       = "6eca95213c6cb2fae1c2c4eaccf43de4c93a65b5"),
                   list(package_name = "duckdb",
                        repo_url     = "https://github.com/duckdb/duckdb-r/",
                        commit       = "71c71a6b824bd0f2c0fca43c5dfa53645b17bfb7")
  ),
  system_pkgs  = c(
                   "adwaita-qt",
                   # "adwaita-qt6",
                   NULL),
  ide          = "rstudio",
  project_path = path_default_nix,
  overwrite    = TRUE,
  print        = TRUE
)

## run nix build from r
nix_build(
  project_path = getwd(),
  message_type = c("simple", "quiet", "verbose")
)

