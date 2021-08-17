#!/bin/bash
## created on 2021-08-17

#### enter description here

FOLDER="$1"

if [ -d $FOLDER ]; then
    echo "Folder: $FOLDER"
else
    echo "NOT A FOLDER: $FOLDER"
fi


## Folder pattern YYYY-MM-DD

pattern="[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$"

echo "Ignoring:"
echo "---------"
find "$FOLDER" -type d | grep -v "$pattern"
echo "---------"

echo "Will process YYYY-MM-DD :"
find "$FOLDER" -type d | grep "$pattern"
echo "---------"


read -p "Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[YyυY]$ ]]; then
    echo "Continuing"
    find "$FOLDER" -type d | grep "$pattern" | while read line; do
        echo "$line"
        date="$(echo "$line" | grep -o "$pattern")"

        echo "$date"

        find "$line" -type f | while read img; do
            # echo "$img"

            ## create date command to use
            ndate="$(echo "$date" | sed 's/-/:/g')"
            comm="-AllDates=\"$ndate 12:00:00\""
            # echo "$comm"

            exiftool -r -v -P "$comm" "$img"

        done
    done
else
    echo "SKIP"
fi



## Folder pattern YYYY-MM


## Folder pattern YYYY-MM



exit 0
