#!/bin/bash
## created on 2018-06-05

#### Run conky scripts every 10 minutes with crontab

## no need to run without a Xserver or headless
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
(sleep $((60*9)); kill $mainpid) &
watchdogpid=$!

SCRIPTS="$HOME/CODE/conky/scripts/"

## ignore errors
set +e

## TODO get calendar
# "${SCRIPTS}Cnk_gcal_reader.sh"  &

## get image from meteoblue
"$HOME/CODE/conky/scripts/meteoblue_get.sh" &

## plot weather
"$HOME/CODE/conky/scripts/plot_weather2.R" &

## output backup status
"${SCRIPTS}status_logs_parse.R" &

## check ip of our hosts
"${SCRIPTS}Cnk_ip_watch.sh"     &

## check external ips and ports of our hosts
"${SCRIPTS}ext_ip_watch.sh"     &


wait; wait; wait; wait; wait;

## don't ignore errors
set -e
echo "took $SECONDS seconds for $0 to complete"
kill "$watchdogpid"
exit 0

