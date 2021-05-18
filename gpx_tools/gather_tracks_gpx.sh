#!/bin/bash

#### Gather multiple gpx files to a single gpx file

## It uses find to get all gpx file under root folder


folderin="$1"

if [[ -d $folderin ]]; then
    echo "Valid folder: $folderin"
else
    echo "NOT VALID FOLDER: $folderin"
    exit
fi


ff=""
command=$(find "$folderin" -iname "*$pattern*.gpx" | sort | while read line; do
printf "-"
printf "f %s  " "$line"
done)

# echo $command
# echo "${folderin}GATHERED_TRACKS.gpx"


gpsbabel -i gpx $command -o gpx -F "${folderin}GATHERED_TRACKS.gpx"

echo
echo "Output file: ${folderin}GATHERED_TRACKS.gpx"
echo

exit 0
