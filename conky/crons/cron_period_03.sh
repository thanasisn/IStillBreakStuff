#!/bin/bash

#### Run conky scripts every 3 minutes with crontab

## no need to run without a Xserver or when headless
xsessions="$(w | grep -o " :[0-9]\+ " | sort -u | wc -l)"
if [[ $xsessions -gt 0 ]]; then
    echo "Display exists $xsessions"
else
    echo "No X server at \$DISPLAY [$DISPLAY] $xsessions" >&2
    exit 11
fi

mkdir -p "/dev/shm/CONKY"

## watchdog script
mainpid=$$
(sleep $((60*3)); kill -9 $mainpid) &
watchdogpid=$!

SCRIPTS="$HOME/CODE/conky/scripts/"

## ignore errors
set +e

## create tinc network image map
"${SCRIPTS}tinc_diagram.sh"

## plot radiation from broadband
"${SCRIPTS}broadband_plot.R"   &

## TODO  plot graphs of my cluster
"${SCRIPTS}Cnk_collectd_img.sh"

## don't ignore errors
set -e
kill "$watchdogpid"
exit 0