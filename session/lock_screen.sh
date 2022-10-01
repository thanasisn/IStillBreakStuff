#!/bin/bash

#### Lock screen with a custom image

BASE_IMG="$HOME/Media/IMAGES/debian_Vader.png"
TARGET="/dev/shm/CONKY/lockimage.png"
COLOR="black"

mkdir -p "/dev/shm/CONKY"

## get image target resolution
resol="$(xrandr | grep -o " connected .*" | grep -o "[0-9]\+x[0-9]\+" | sort -n | tail -n 1)"
echo "$resol"

## create a proper image
convert             "$BASE_IMG"    \
        -gravity    "center"       \
        -background "$COLOR"       \
        -extent     "$resol"       \
                    "$TARGET"

## lock screen and black screen
( i3lock -t -c 000000 -i "$TARGET" ) &
sleep 30
( xset dpms force off )

exit 0
