#!/bin/bash
## created on 2018-06-05

#### Run conky scripts with every 90 minutes with crontab

## no need to run without a Xserver or headless
xsessions="$(w | grep -o " :[0-9]\+ " | sort -u | wc -l)"
if [[ $xsessions -gt 0 ]]; then
    echo "Display exists $xsessions"
else
    echo "No X server at \$DISPLAY [$DISPLAY] $xsessions" >&2
    exit 11
fi

## watchdog script
mainpid=$$
(sleep $((60*30)); kill $mainpid) &
watchdogpid=$!

mkdir -p "/dev/shm/CONKY"

SCRIPTS="$HOME/CODE/conky/scripts/"


## ignore errors
set +e

"$SCRIPTS"transact_plot.R  &


## don't ignore errors
set -e
kill "$watchdogpid"
exit 0