#!/usr/bin/env bash
## created on 2018-06-05

#### Run conky scripts every 10 minutes with crontab

## external kill switch
#####################################################################
killfile="/dev/shm/KILL_SWITCH/$(basename "$0")"
[[ -f "$killfile" ]] && echo && echo "KILL SWITCH: $killfile !!!" && exit 99
#####################################################################

# ## no need to run without a Xserver or headless
# #####################################################################
# xsessions="$(w | grep -o " :[0-9]\+ " | sort -u | wc -l)"
# if [[ $xsessions -gt 0 ]]; then
#     echo "Display exists $xsessions"
# else
#     echo "No X server at \$DISPLAY [$DISPLAY] $xsessions" >&2
#     exit 11
# fi
# #####################################################################


mkdir -p "/dev/shm/CONKY"

## watchdog script
mainpid=$$
(sleep $((60*9)); kill $mainpid) &
watchdogpid=$!

SCRIPTS="$HOME/CODE/conky/scripts/"

## ignore errors
set +e
pids=()

## get calendar
# "${SCRIPTS}Cnk_gcal_reader.sh"  &

## plot weather
# "$HOME/CODE/conky/scripts/plot_weather2.R" & pids+=($!)
"$HOME/CODE/conky/scripts/plot_weather3.R" & pids+=($!)

## output backup status
"$HOME/CODE/conky/scripts/status_logs_parse.R" & pids+=($!)

## check ip of our hosts
# "${SCRIPTS}Cnk_ip_watch.sh"     &

## check external ips and ports of our hosts
"$HOME/CODE/conky/scripts/ext_ip_watch.sh"     & pids+=($!)


## Clean some of syncthing artifacts
find "$HOME/LOGs/SYSTEM_LOGS" -name "*.sync-conflict-*" -delete
find "$HOME/LOGs/waypoints"   -name "*.sync-conflict-*" -delete
find "$HOME/LOGs/winb"        -name "*.sync-conflict-*" -delete
find "$HOME/PANDOC"           -name "*.sync-conflict-*" -delete
find "$HOME/NOTES/.obsidian"  -name "*.sync-conflict-*" -delete


wait "${pids[@]}"; pids=()
set -e
echo "took $SECONDS seconds for $0 to complete"
kill "$watchdogpid"
exit 0

