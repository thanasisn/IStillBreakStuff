#!/bin/bash
## created on 2019-03-10

#### A helper script to covert list of bookmarks to pdftk format

## this is called by onother script
## reads a special prepared file of bookmarks and create bookmarks for pdftk info

## no sorting is done in the pdf
## extra spaces in variables are not allowed

## TEMPLATE
# BookmarkBegin
# BookmarkTitle: Solar Energy Engineering: Processes and Systems
# BookmarkLevel: 1
# BookmarkPageNumber: 4

## sort manually!

FILE="$1"
[[ ! -f "$FILE" ]] && echo "Not file input" && echo "exit" && exit 1

NAME="${FILE%%.*}"


cat "$FILE" | grep -v '^ *#\+' | sed '/^[[:space:]]*$/d' | while read line;do

#     echo $line
    page="$(echo "$line" | grep -o '^[ 0-9]\+')"

    level="$(echo "$line" | sed 's/^[ 0-9]\+//' | grep -o '^#\+')"
    level="$(echo -n "$level" | wc -c)"

    name="$(echo $line | cut -d' ' -f3-)"

    ## export valid book marks only
    if [ ! -z  "$page" ] && [ ! -z  "$level" ] && [ ! -z  "$name" ]; then
        echo "BookmarkBegin"
        echo "BookmarkTitle: $name"
        echo "BookmarkLevel:" $level
        echo "BookmarkPageNumber:" $page
    fi

done


exit 0
