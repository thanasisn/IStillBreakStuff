#!/bin/bash
## created on 2021-11-10

#### Create a desktop background for host/user

colorback="black"
colorfont="yellow"



cat "/etc/os-release" | grep "ID=" | cut -d'=' -f2


xrandr |awk '/\*/ {print $1}' | while read resolution ;do
    echo "$resolution"

    convert \
        -size "$resolution" \
        -background $colorback \
        -pointsize 25 \
        -fill "$colorfont" \
        -gravity SouthEast caption:"The quick red fox\n jumped over the lazy brown dog." \
        -flatten \
        BackGround_"$resolution".png


done








exit 0
