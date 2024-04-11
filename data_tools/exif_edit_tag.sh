#!/usr/bin/env bash
## created on 2024-04-11

#### Edit exif tags for a list of files

## This will edit your files!!
## Don't run it if you don't understand it, I am not responsible for your data.
## This must be edited and TESTED by you to run!!

## To run:
## ./exif_edit_tag.sh "$(cat file.list)"
## cat file.list | xargs         -I {} ./exif_edit_tag.sh {}
## cat file.list | xargs    -P 4 -I {} ./exif_edit_tag.sh {}
## cat file.list | xargs -t -P 4 -I {} ./exif_edit_tag.sh {}

## File to parse
FILE="$1"


## Fix samsung phone FNumber  --------------------------------------------------
TAG="exif:FNumber"

## get dirty value
dirty="$(exiftool -m -q -"$TAG" "$FILE" 2>/dev/null | cut -d":" -f2- | sed 's/^[ ]\+//')"

## get clean value
clean="$(echo "$dirty" | cut -d" " -f1)"

## if empty ignore file
if [ -z "${clean}" ]; then
  echo "Empty for: $FILE"
  exit 0
fi

## check output before run
printf "%8s   -> %8s   ::  %s\n" "$dirty" "$clean" "$FILE"

## uncomment to replace tag
## will update mtime in all files with or without correct value
exiftool -"$TAG"="$clean" "$FILE"



##  END  ##
exit 0 
