#!/bin/bash

#### Choose the bigger connected screen for displaying conky


## VARS
#confile="$HOME/BASH/CONKY/conky.conf.d/conky_crane_1680x1050_new.conf"
confile="$HOME/BASH/CONKY/conky.conf.d/conky_crane_1366x768.conf"
conpause="0"
confont="Liberation Mono"
conalig="top_left"  # we have done all configs with that in mind


## list monitors
screens="$(xrandr | grep " connected")"
## count monitors
nsc="$(echo "$screens" | wc -l)"
## get the larger by resolution
shopt -s lastpipe
maxp=1
echo "$screens" | while read line;do
    pixels="$(echo "$line" | egrep -o " [x0-9]{4,}" | tr 'x' '*' | bc)"
    # echo "$pixels"
    if [ $pixels -gt $maxp ]; then
        maxp="$pixels"
        echo "$line"
    fi
done | tail -n1 | read maxl

#TODO check output


## get screen offset
Yoff="$(echo "$maxl" | grep -o "+[0-9]\++[0-9]\+" | cut -d'+' -f3)"
Xoff="$(echo "$maxl" | grep -o "+[0-9]\++[0-9]\+" | cut -d'+' -f2)"

## Info
echo "Larger mon: $maxl"
echo "X offset:   $Xoff"
echo "Y offset:   $Yoff"
echo "Config:     $confile"

killall -s 9 conky


## the only instance we like to see time in home locale
export LC_ALL="el_GR.UTF-8"

conky -p "$conpause"  \
      -f "$confont"   \
      -a "$conalig"   \
      -x "$Xoff"      \
      -y "$Yoff"      \
      -D \
      -d \
      -c "$confile"   &
export LC_ALL=en_US.UTF-8


#    if [[  $(xrandr | grep " connected .*1366x768") ]] ; then
#        echo "LVDS1 connected 1366x768"
#
#        export LC_ALL=el_GR.UTF-8
#        conky -p 5                 \
#              -d                   \
#              -f "Liberation Mono" \
#              -a "top_left"        \
#              -D \
#              -c "$HOME/BASH/CONKY/conky.conf.d/conky_crane_1366x768.conf" &
#        export LC_ALL=en_US.UTF-8
#        echo "conky_crane_1366x768.conf"
#
#        exit 0
#    fi
