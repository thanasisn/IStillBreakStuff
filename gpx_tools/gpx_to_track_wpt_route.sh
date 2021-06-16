#!/bin/bash
## created on 2015-09-10

####  Split a gpx file to tracks, waypoints and routes files


fileIN="$1"

echo
if [[ -f "$fileIN" ]]; then
    echo "Input file: $fileIN"
else
    echo "NO FILE: $fileIN"
    exit
fi

ext="${fileIN##*.}"

if [[ "${ext^^}" == "GPX" ]]; then
    :
else
    echo "No gpx file"
    exit
fi

trackfl="${fileIN%.*}_track.gpx"
wptsfl="${fileIN%.*}_wpts.gpx"
routefl="${fileIN%.*}_route.gpx"

gpsbabel -i gpx -f -  -x nuketypes,waypoints,routes  -o gpx -F - <"$fileIN" >"${trackfl}"
gpsbabel -i gpx -f -  -x nuketypes,tracks,routes     -o gpx -F - <"$fileIN" >"${wptsfl}"
gpsbabel -i gpx -f -  -x nuketypes,tracks,waypoints  -o gpx -F - <"$fileIN" >"${routefl}"


# echo $trackfl

exit 0
