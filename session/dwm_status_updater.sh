#!/bin/bash
## created on 2021-11-16

#### Continuously Update dwm status bar

while true; do
    UTIME="$(awk '{print int($1/86400)"d "int($1%86400/3600)":"int(($1%3600)/60)":"int($1%60)}' /proc/uptime)"
    DATE="$(date +"%y-%m-%d(%j) %H:%M")"
    comands="$(ps -A --no-headers | wc -l)"
    LOAD="$(sed 's/\//\/'$comands'\//g' /proc/loadavg | cut -d' ' -f1-4 | sed 's/\/[0-9]\+$//g')"
    MemUsed="$(free | grep "Mem" | awk '{print "scale=1; 100*" $3 "/" $2 }' | bc)"
    BAT="$(upower -d | grep "percentage" | sort -u | tail -n1 | grep -o "[.0-9%]\+")"

    ## compose display info
    MESSG=" ${UTIME} b:${BAT} ${LOAD} m:${MemUsed}% ${DATE} "

    ## set info on statusbar
    # echo "$MESSG"
    xsetroot -name "$MESSG"

    sleep 10
done

exit 0
