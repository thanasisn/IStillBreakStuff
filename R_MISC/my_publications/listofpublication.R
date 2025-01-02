#' ---
#' title:         "List of publications"
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
#'  - \usepackage{fontspec}
#'  - \usepackage{xunicode}
#'  - \usepackage{xltxtra}
#'  - \usepackage[greek]{babel}
#'  - \setmainfont[Scale=1]{Linux Libertine O}
#'
#' output:
#'   bookdown::pdf_document2:
#'     keep_tex:         yes
#'     keep_md:          yes
#'     latex_engine:     xelatex
#'   html_document:
#'     keep_md:          yes
#'
#' date: "`r format(Sys.time(), '%F')`"
#'
#' ---

#+ echo=F, messages=F
knitr::opts_chunk$set(comment  = ""     )
knitr::opts_chunk$set(echo     = FALSE  )
knitr::opts_chunk$set(messages = FALSE  )

library(bib2df)
library(stevemisc)
library(stringi)
library(janitor)

bib_fl     <- "~/LIBRARY/A_Atmosphere/A_Atmosphere.bib"
my_pattern <- "Natsis|Νάτσης"
LANG       <- "en"
LANG       <- "el"
BOLD       <- TRUE
# BOLD       <- FALSE
NUMBER     <- TRUE
# NUMBER     <- FALSE


## load a bib file to data frame
bib_df <- bib2df(file = bib_fl)
bib_df$ABSTRACT <- NULL

## keep mine
bib_df <- bib_df[grepl(my_pattern, bib_df$AUTHOR),]
bib_df <- remove_empty(bib_df, which = "cols")

## order by date
bib_df <- bib_df[order(bib_df$DATE, decreasing = T), ]

## select categories
unique(bib_df$CATEGORY)

bib_df <- bib_df[
  bib_df$CATEGORY %in% c(
    "ARTICLE",
    # "SOFTWARE",
    "INPROCEEDINGS",
    # "MISC",
    # "MASTERSTHESIS",
    # "THESIS",
    NULL
  ),
]



#+ results="asis"
for (at in unique(bib_df$CATEGORY)) {
  cc <- 0
  ## Change language
  if (LANG == "el") {
    tit <- switch(
      at,
      ARTICLE       = "Άρθρα",
      INPROCEEDINGS = "Παρουσιάσεις σε συνέδρια"
    )
  }
  cat("\n\n##", tit, "\n\n")

  temp <- bib_df[bib_df$CATEGORY == at, ]

  for (i in 1:nrow(temp)) {
    cc        <- cc + 1
    bib_entry <- paste0(capture.output(df2bib(temp[i,])), collapse = "")

    suppressMessages({
      # print_refs(bib_entry,
      #                       csl = "apa.csl",
      #                       spit_out = TRUE,
      #                       delete_after = FALSE)

      # paste(print_refs(bib_entry,
      #            csl = "apa.csl",
      #            spit_out = FALSE,
      #            delete_after = FALSE))

     if (NUMBER) {
       cat(cc, ". ", sep = "")
     }

      if (BOLD) {
        cat(
          sub("(Natsis,[. AN]*)|(Νάτσης,[. ΑΝ]*)", "**\\1\\2**",
              print_refs(bib_entry,
                         csl = "apa.csl",
                         spit_out = FALSE,
                         delete_after = FALSE)
          ), "\n"
        )
      } else {
        cat(
          print_refs(bib_entry,
                     csl = "apa.csl",
                     spit_out = FALSE,
                     delete_after = FALSE)
          , "\n"
        )
      }
    })
    cat("\n")
  }
}
#'


# clean entries
# bib_df$TITLE <- stri_replace_all_regex(bib_df$TITLE, "[\\{\\}]", "")
# bib_df$JOURNAL <- stri_replace_all_regex(bib_df$JOURNAL, "[\\{\\}]", "")
# bib_df$BOOKTITLE <- stri_replace_all_regex(bib_df$BOOKTITLE, "[\\{\\}]", "")


