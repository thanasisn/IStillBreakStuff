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
#'   html_document:
#'     toc:        true
#'   bookdown::pdf_document2:
#'     keep_tex:         yes
#'     keep_md:          yes
#'     latex_engine:     xelatex
#'     toc:              yes
#'     toc_depth:        4
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

bib_fl     <- "~/LIBRARY/A_Atmosphere/A_Atmosphere.bib"
my_pattern <- "Natsis|Νάτσης"
BOLD       <- TRUE

# load a bib file to data frame
bib_df <- bib2df(file = bib_fl)
bib_df$ABSTRACT <- NULL


## keep mine
bib_df <- bib_df[grepl(my_pattern, bib_df$AUTHOR),]
## order by recent
bib_df <- bib_df[order(bib_df$DATE, decreasing = T), ]

#+ results="asis"
for (at in unique(bib_df$CATEGORY)) {
  cat("\n\n##", at, "\n\n")

  temp <- bib_df[bib_df$CATEGORY == at, ]

  for (i in 1:nrow(temp)) {

    bib_entry <- paste0(capture.output(df2bib(temp[i,])), collapse = "")

    suppressMessages({
      print_refs(bib_entry,
                            csl = "apa.csl",
                            spit_out = TRUE,
                            delete_after = FALSE)

sub()
      print_refs(bib_entry,
                 csl = "apa.csl",
                 spit_out = TRUE,
                 delete_after = FALSE)



    })
stop()
    cat("\n")
  }
}
#'


# clean entries
# bib_df$TITLE <- stri_replace_all_regex(bib_df$TITLE, "[\\{\\}]", "")
# bib_df$JOURNAL <- stri_replace_all_regex(bib_df$JOURNAL, "[\\{\\}]", "")
# bib_df$BOOKTITLE <- stri_replace_all_regex(bib_df$BOOKTITLE, "[\\{\\}]", "")


