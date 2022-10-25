#' ---
#' title: "Golden Cheetah detect outliers in metrics data"
#' date: "`r format(Sys.time(), '%F')`"
#'
#' documentclass: article
#' classoption:   a4paper,oneside
#' fontsize:      11pt
#' geometry:      "left=1in,right=1in,top=1in,bottom=1in"
#'
#' bibliography:  [references.bib]
#' biblio-style:  apalike
#'
#' header-includes:
#' - \usepackage{caption}
#' - \usepackage{placeins}
#' - \captionsetup{font=small}
#' - \usepackage{multicol}
#' - \setlength{\columnsep}{1cm}
#'
#' output:
#'   bookdown::pdf_document2:
#'     number_sections:  no
#'     fig_caption:      no
#'     keep_tex:         no
#'     latex_engine:     xelatex
#'     toc:              yes
#'   html_document:
#'     keep_md:          yes
#'   odt_document:  default
#'   word_document: default
#'
#' ---


#+ include=FALSE, echo=FALSE

#### Golden Cheetah detect outliers in metrics data


####_ Set environment _####
#rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name <- tryCatch({ funr::sys.script() },
                        error = function(e) { cat(paste("\nUnresolved script name: ", e),"\n\n")
                            return("GC_metrics_outliers") })
if(!interactive()) {
    pdf(file=sub("\\.R$",".pdf",Script.Name))
    sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)
}

library(data.table)
source("~/FUNCTIONS/R/data.R")



metrics <- readRDS("~/LOGs/GCmetrics.Rds")
metrics <- data.table(metrics)
metrics <- rm.cols.dups.DT(metrics)

wecare  <- names(Filter(is.numeric, metrics))

wecare  <- grep("Time_in_Zone",      wecare, value = T, invert = T )
wecare  <- grep("Time_in_Pace_Zone", wecare, value = T, invert = T )
wecare  <- grep("Percent_in_Zone",   wecare, value = T, invert = T )
wecare  <- grep("Checksum",          wecare, value = T, invert = T )
##TODO we may want that for detection extremes
wecare  <- grep("Best_",             wecare, value = T, invert = T )
wecare <- grep("date|notes|time|sport|workout_code|bike|shoes|workout_title|device|Calendar_text|Elevation_Gain_Carrying|heartbeats|Max_Core_Temperature|Checksum|Right_Balance|Percent_in_Zone|Percent_in_Pace_Zone|Best_|Distance_Swim|Equipment_Weight|Average_Core_Temperature|Average_Temp|Max_Cadence|Max_Temp|min_Peak_Pace|_Peak_Pace|_Peak_Pace_HR|_Peak_Power|_Peak_Power_HR|min_Peak_Hr|_Peak_WPK|Min_temp|Average_Cadence|Average_Running_Cadence|Max_Running_Cadence|Percent_in_Pace_Zone",
               wecare, ignore.case = T,value = T,invert = T)



#+ results="asis", include=T, echo=F
for (var in wecare) {
    cat(paste("\n\\newpage\n"))
    cat(paste("\n\n## ",var,"\n\n"))

    temp    <- data.table(metrics$date,  metrics[[var]])
    temp$V1 <- as.numeric(temp$V1)

    outlier_values <- boxplot.stats(temp$V2)$out  # outlier values.

    # boxplot(temp$V2, main=var, boxwex=0.1)
    # mtext(paste("Outliers: ", paste(outlier_values, collapse=", ")), cex=0.6)
    cat(paste("\n\n"))

    # For continuous variable (convert to categorical if needed.)
    boxplot(V2 ~ V1, data=temp, main=var)
    cat(paste("\n\n"))
    boxplot(V2 ~ cut(V1, pretty(temp$V1 )), data=temp, main=var, cex.axis=0.5)
    cat(paste("\n\n"))

    temp$V1 <- as.Date(temp$V1,origin = "1970-01-01")

    plot(temp$V1, temp$V2)
    title(var)
    cat(paste("\n\n"))

    hist(temp$V2)
    cat(paste("\n\n"))

    mod <- lm( as.numeric(V1) ~ V2, data=temp)
    temp$cooksd <- cooks.distance(mod)

    plot(temp$V1, temp$cooksd, pch="*", cex=2, main=var)  # plot cook's distance
    abline(h = 4*mean(temp$cooksd, na.rm=T), col="red")  # add cutoff line
    # text(x=1:length(cooksd)+1, y=cooksd, labels=ifelse(cooksd>4*mean(cooksd, na.rm=T),names(cooksd),""), col="red")  # add labels
    cat(paste("\n\n"))

    cat(pander::pander( temp[ cooksd > 4*mean(cooksd, na.rm=T), ] ))

    cat(paste("\n\n"))
    }
#'




#'
#' **END**
#+ include=T, echo=F
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f mins\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
