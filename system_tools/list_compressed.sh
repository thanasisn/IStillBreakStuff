#!/bin/bash
## created on 2015-11-23
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### List compressed files by looking for mime type

FOLDER="$1"
## if no folder assume current
: ${FOLDER:="./"}

if [ ! -d "$FOLDER" ]; then
    echo "Give a folder"
    exit 1
fi

find "$FOLDER" -type f -exec file {} + |\
    grep "archive\|compres\|extract"   |\
    cut -d: -f1                        |\
    grep -i -v ".*.rds"


exit 0
