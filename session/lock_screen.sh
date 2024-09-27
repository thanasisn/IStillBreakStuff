#!/usr/bin/env bash

#### Lock screen with a custom image

BASE_IMG="$HOME/MISC/Media/IMAGES/debian_Vader.png"
TARGET="/dev/shm/CONKY/lockimage.png"
COLOR="black"

mkdir -p "/dev/shm/CONKY"

## get image target resolution
resol="$(xrandr | grep -o " connected .*" | grep -o "[0-9]\+x[0-9]\+" | sort -n | tail -n 1)"
echo "$resol"

## create a proper image for the current screen
# convert             "$BASE_IMG"    \
#         -gravity    "center"       \
#         -background "$COLOR"       \
#         -extent     "$resol"       \
#                     "$TARGET"

convert                                               \
  -background     "$COLOR"                            \
  -density 200    "$HOME/MISC/Media/IMAGES/nixos.svg" \
  -gravity center "$BASE_IMG"                         \
  -composite                                          \
  -extent         "$resol"                            \
  "$TARGET"

## lock screen with tiled image
nohup i3lock -t -c 000000 -i "$TARGET"
sleep 15

## blank screen
xset dpms force off

exit 0
