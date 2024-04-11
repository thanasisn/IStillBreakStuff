#!/usr/bin/env bash
## created on 2024-04-11

#### List files with specific value in specific exif tag

## Run to create a list of files for other usages
##
## Example:
##  $ exif_list_by_tag.sh "exif:Model" "GT-B2710" "./path/to/folder" > ./files_with_tag.list
##
## This slow! Query digikam database if you need to run regularly.

## tag to check
TAG="$1"
## tag value to match
VALUE="$2"
## recursive in folder
FOLDER="$3"

if [ ! -d "$FOLDER" ];then
  echo "Give a folder"
  exit 1
fi

find "$FOLDER" -type f | while read line; do
  testvalue="$(exiftool -m -q -"$TAG" "$line" 2>/dev/null | cut -d":" -f2-)"
  # echo "$testvalue"
  if [[ "$testvalue" == *"$VALUE"* ]]; then
    ## print matching files
    echo "$line"
  else
    :
  fi
done


##  END  ##
exit 0 
