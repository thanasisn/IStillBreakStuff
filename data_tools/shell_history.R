#!/usr/bin/env Rscript

#### Explore shell history files

#### _ INIT _ ####
closeAllConnections()
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()
# if(!interactive())pdf(file=sub("\\.R$",".pdf",Script.Name))
# sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)

Sys.setlocale('LC_ALL','C')

library(data.table)

file <- "~/.global_hist"

res <- readLines(file)

## drop multiline commands
res <- grep('::: ', res, value = T)

## get host only
res  <- gsub(":::","|",res)
name <- gsub("\\|.*","",res)

res2 <- gsub(".hist_[a-z]+\\|","",res)

## get time
time <- gsub(":.*","",res2)
time <- as.POSIXct(as.numeric(time), origin="1970-01-01")

res3 <- gsub("^[ 0-9]+:","",res2)

## get duration
dura <- as.numeric(gsub(";.*","",res3))

## get command
command <- gsub("^[0-9]+;","",res3)


data <- data.table(name = name,
                   time = time,
                   duration = dura,
                   command  = command)

summary(data)

unique(data$name)
unique(data$duration)
unique(data$command)

text <- paste(data$command,collapse = " ")
text <- gsub(";"," ",text)

words <- strsplit(text, " ")

dd <- data.table(words = unlist(words))
dd$words <- gsub("^\"","",dd$words )
dd$words <- gsub("\"$","",dd$words )
dd$words <- gsub("^'","",dd$words )
dd$words <- gsub("'$","",dd$words )
dd$words <- gsub("~/","",dd$words )


dd <- dd[, .N, by = words ]

dd[, nchar := nchar(words)]
dd <- dd[ nchar > 1, ]


dd <- dd[ ! grepl("^-", words)]
dd <- dd[ ! grepl("^#", words)]
dd <- dd[ ! grepl("^%", words)]
dd <- dd[ ! grepl("^\\*", words)]


dd <- dd[ ! grepl("^\\+", words)]
dd <- dd[ ! grepl("^\\$", words)]
dd <- dd[ ! grepl("^./$", words)]
dd <- dd[ ! grepl("^\\{\\}$", words)]
dd <- dd[ ! grepl("^\"\\{\\}\"$", words)]
dd <- dd[ ! grepl("^>>$", words)]
dd <- dd[ ! grepl("^&&$", words)]

dd <- dd[ ! grepl("^[-+x.0-9]+$", words)]




# stringi::stri_length(dd$words)
#
# stringr::str_length( dd$words )
# stringr::str_length( stringi::stri_enc_toutf8(dd$words) )
#
# stringr::str_length("ήή")

####_ END _####
tac = Sys.time()
cat(sprintf("\n%s H:%s U:%s S:%s T:%f\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
