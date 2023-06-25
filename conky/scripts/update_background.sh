#!/bin/bash
## created on 2021-11-10

#### Create a desktop background for host/user and set it

## Create images for display
workingdir="/dev/shm/CONKY"
mkdir -p "$workingdir"
cd "$workingdir"

colorback="black"
colorfont="grey"
pointsize="10"
xpad="0"
ypad="20" ## allow for status bar

# https://imagemagick.org/script/color.php
[ $(hostname) == "sagan"  ] && colorfont="DarkOrange2"
[ $(hostname) == "tyler"  ] && colorfont="cyan4"
[ $(hostname) == "blue"   ] && colorfont="RoyalBlue1"
[ $(hostname) == "crane"  ] && colorfont="crimson"
[ $(hostname) == "cranea" ] && colorfont="ForestGreen"


name="$(cat "/etc/os-release" | grep "PRETTY_NAME=" | cut -d'=' -f2- | sed 's/"//g')"

distro="$(cat "/etc/os-release" | grep "^ID=" | cut -d'=' -f2- | sed 's/"//g')"
versio="$(cat "/etc/os-release" | grep "^VERSION_ID=" | cut -d'=' -f2- | sed 's/"//g')"

echo "$distro"
echo "$versio"

message="${name}\n$USER @ $(hostname)"

xrandr |awk '/\*/ {print $1}' | while read resolution ;do
    echo "$resolution"

    convert                                   \
        -size       "$resolution"             \
        -background "$colorback"              \
        -pointsize  "$pointsize"              \
        -fill       "$colorfont"              \
        -gravity SouthEast caption:""         \
        -annotate +${xpad}+${ypad} "$message" \
        -flatten                              \
        BackGround_"$resolution".png
done



## display images on all screens background

screen_size=$( xrandr |awk '/\*/ {print $1}' )

IFS=$'\n'
readarray -t <<<"$screen_size"
feh_command="feh --bg-fill --no-fehbg"

for i in "${MAPFILE[@]}"; do
    echo size: "$i"
    feh_command="$feh_command BackGround_$i.png"
done

eval "$feh_command"

exit 0
