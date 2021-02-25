#!/bin/bash

#### Run all crons at reboot or for development

## path of most of the scripts
BASEPATH="$HOME/CODE/conky/crons/"

sleep 1
nice -n 19 ionice -c2 -n7 "${BASEPATH}cron_period_03.sh" &
sleep 10
nice -n 19 ionice -c2 -n7 "${BASEPATH}cron_period_10.sh" &
sleep 10
nice -n 19 ionice -c2 -n7 "${BASEPATH}cron_period_30.sh" &
sleep 10
nice -n 19 ionice -c2 -n7 "${BASEPATH}cron_period_90.sh" &

## keep only last n lines of status files
find "/home/athan/LOGs/SYSTEM_LOGS/" -iname "*.status" | while read line; do
    echo "$(tail -2000 $line)" > "$line"
done

exit 0
