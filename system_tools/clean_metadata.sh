#!/bin/bash

## Remove metadata from file using exiftool

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "Give a file"
    exit 1
fi

echo "REMOVE METADATA:  $FILE"

## show tags from the original PDF
# exiftool -all:all "$FILE"

## This will empty tags (XMP + metadata) from any file
exiftool -overwrite_original -all:all= "$FILE"

## Not sure why I use that  
qpdf --linearize "$FILE" "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"

## Show remaining metadata to be sure
exiftool -all:all "$FILE"

exit 0
