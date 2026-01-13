#!/usr/bin/env bash

#### Run conky scripts every 10 minutes

##  External kill switch  ###########################################
killfile="/dev/shm/KILL_SWITCH/$(basename "$0")"
[[ -f "$killfile" ]] && echo && echo "KILL SWITCH: $killfile !!!" && exit 99

##  Dot no run headless  ############################################
# xsessions="$(w | grep -o " :[0-9]\+ " | sort -u | wc -l)"
# if [[ $xsessions -gt 0 ]]; then
#     echo "Display exists $xsessions"
# else
#     echo "No X server at \$DISPLAY [$DISPLAY] $xsessions" >&2
# #     exit 0
# fi

##  Watchdog for script  ############################################
mainpid=$$
(sleep $((60*9)); kill -9 $mainpid) &
watchdogpid=$!

##  INIT  ----------------------------------------------------------------------
mkdir -p "/dev/shm/CONKY"
set +e
pids=()

##  RUN  -----------------------------------------------------------------------

"$HOME/CODE/conky/scripts/plot_weather3.R"     & pids+=($!)

## output backup status
"$HOME/CODE/conky/scripts/status_logs_parse.R" & pids+=($!)

## check ip of our hosts
# "${SCRIPTS}Cnk_ip_watch.sh"     &

## check external ips and ports of our hosts
# "$HOME/CODE/conky/scripts/ext_ip_watch.sh"     & pids+=($!)

## Clean some of syncthing artifacts
echo "Clean some artifacts"
find "$HOME/LOGs/SYSTEM_LOGS" -name "*.sync-conflict-*" -delete
find "$HOME/LOGs/waypoints"   -name "*.sync-conflict-*" -delete
find "$HOME/LOGs/winb"        -name "*.sync-conflict-*" -delete
find "$HOME/PANDOC"           -name "*.sync-conflict-*" -delete
find "$HOME/NOTES/.obsidian"  -name "*.sync-conflict-*" -delete

##  CLEAN  ---------------------------------------------------------------------
wait "${pids[@]}"; pids=()
echo
echo "Took $SECONDS seconds for $0 to complete"
kill "$watchdogpid"
exit 0
