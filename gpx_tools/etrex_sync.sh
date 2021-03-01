#!/bin/bash
## created on 2018-02-11

#### Get all gpx files from etrex, update maps and some other files


TARGET="$HOME/GISdata/etrex_backup"
SOURCE1="/media/$USER/GARMIN/Garmin/GPX"
SOURCE2="/media/$USER/garmin sd/Garmin/GPX"
MAPSdir="/home/$USER/DATA/MAPS/garmin_img"
mapDEV="/media/$USER/garmin sd/Garmin"

## create path to store
mkdir -p "$TARGET"

## check sources and sync
if [ -d "$SOURCE1" ]; then
    echo "EXIST: $SOURCE1"
    rsync -raPh "$SOURCE1" "$TARGET/Device"
else
    echo "MISSING!! ** $SOURCE1 ** MISSING!!"
fi

## copy some of regular waypoints to the device
cp -vu "$HOME/LOGs/waypoints_etrex/wpt_Seix Sou.gpx" "/media/athan/GARMIN/Garmin/GPX"
cp -vu "$HOME/LOGs/waypoints_etrex/wpt_Thessaloniki-Stavros-O4.gpx" "/media/athan/GARMIN/Garmin/GPX"
cp -vu "$HOME/LOGs/waypoints_etrex/wpt_Xortiatis.gpx" "/media/athan/GARMIN/Garmin/GPX"

## check sources and sync
if [ -d "$SOURCE2" ]; then
    echo "EXIST: $SOURCE2"
    rsync -raPh "$SOURCE2" "$TARGET/SDcard"
else
    echo "MISSING!! ** $SOURCE2 ** MISSING!!"
fi


## update device maps
if [ -d "$mapDEV" ]; then
    echo "EXIST: $mapDEV"
    rsync -raPh "$MAPSdir/" "$mapDEV"
else
    echo "MISSING!! ** $mapDEV ** MISSING!!"
fi


exit 0
