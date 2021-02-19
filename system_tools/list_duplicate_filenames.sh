#!/bin/bash
## created on 2020-11-09

#### Find duplicate filenames recursively in a folder structure
## Used to detect dups filenames when you want filename uniqueness within a folder structure
## Edit to deal with them and find solutions

FOLDER="$1"

if [[ ! -d "$FOLDER" ]]; then
    echo "Give a folder!"
    exit 0
fi

echo "Dir: $FOLDER"

find "$FOLDER" -type f -exec basename {} \; | sort |  uniq -d | while read fileName; do
    echo ""
    ## show dup file name
    echo "$fileName"

    ## List dup file paths
    find "$FOLDER" -type f | grep "/${fileName}$"

    ## One line output for use with other programs
    find "$FOLDER" -type f | grep "/${fileName}$" | sed 's/^..*$/"&"/' | tr "\n" " "
    echo ""

done

exit 0
