#!/bin/bash
## created on 2019-01-11
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### List libraries used in R and Rmd scripts
## It is not very robust but it is helpful
## Can create a install.packages command
## Doesn't now if libraries are from private repositories like github

##TODO grep all relevant lines to file
##     clean them afterwords


FOLDER="$1"

if [[ ! -d "$FOLDER" ]];then
    echo "Give a folder to process"
    exit
fi

librariesfile="$FOLDER/Rpackages.used"

echo ""
echo "R packages seen in $FOLDER"
echo "--------------------------"



(
    ## get all library(*) declarations
    find "$FOLDER" -type f  \
                -not -path "*/old/*"         \
                -iname "*.R" -or             \
                -iname "*.Rmd"               |\
                xargs grep -h "library("     |\
                sed '/[ ]*#/d'               |\
                tr -d \"                     |\
                tr -d \'                     |\
                sed 's/.*(\([^]]*\)).*/\1/g' |\
                sed 's/[, ].*//g'            |\
                sed '/"/d'                   |\
                sort -u

    ## get all require(*) declarations
    find "$FOLDER" -type f  \
                -not -path "*/old/*"         \
                -iname "*.R" -or             \
                -iname "*.Rmd"               |\
                xargs grep -h "require("     |\
                sed '/[ ]*#/d'               |\
                tr -d \"                     |\
                tr -d \'                     |\
                sed 's/.*(\([^]]*\)).*/\1/g' |\
                sed 's/[, ].*//g'            |\
                sed '/"/d'                   |\
                sort -u




   ## get all *:: declarations
   find "$FOLDER" -type f  \
               -not -path "*/old/*"    \
               -iname "*.R" -or        \
               -iname "*.Rmd"                           |\
               xargs grep -h "[[:alnum:]]::[[:alnum:]]" |\
               sed 's@\(.*\)::.*@\1@g'                  |\
               sed '/[)(-<]/d'                          |\
               sed 's/^[ ]*//'                          |\
               sed 's/[ ]*$//'                          |\
               sed '/ /d'                               |\
               grep -oE '[^ ({=]+$'                     |\
               sed '/"/d'                               |\
               sort -u


) | sort -u | tee "$librariesfile"

echo ""
echo "Output written >> $librariesfile"
echo ""

## export for R installation
## remove some of my packages
\cat "$librariesfile"                         |\
    grep -v "RAerosols\|RlibRadtran\|myRtools\|AEROSOL" |\
    sed '/^[[:space:]]*$/d'                   |\
    paste -sd "," -                           |\
    sed 's@,@","@g ; s@\(.*\)@install.packages(c("\1"),repos="https://cran.rstudio.com")@'



exit 0
