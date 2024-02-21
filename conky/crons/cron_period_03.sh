#!/usr/bin/env bash

#### Run conky scripts every 3 minutes with crontab

##  External kill switch  ###########################################
killfile="/dev/shm/KILL_SWITCH/$(basename "$0")"
[[ -f "$killfile" ]] && echo && echo "KILL SWITCH: $killfile !!!" && exit 99
##  Dot no run headless  ############################################
xsessions="$(w | grep -o " :[0-9]\+ " | sort -u | wc -l)"
if [[ $xsessions -gt 0 ]]; then
    echo "Display exists $xsessions"
else
    echo "No X server at \$DISPLAY [$DISPLAY] $xsessions" >&2
    exit 0
fi
##  Watchdog for script  ############################################
mainpid=$$
(sleep $((60*3)); kill -9 $mainpid) &
watchdogpid=$!

##  MAIN  ############################################################

## Init
mkdir -p "/dev/shm/CONKY"
set +e
pids=()

##  Plot number of processes
# "$HOME/CODE/conky/scripts/plot_ps.gp"         &

## Create tinc network image map
"$HOME/CODE/conky/scripts/tinc_diagram.sh"    & pids+=($!)

## Plot radiation from broadband
"$HOME/CODE/conky/scripts/broadband_plot.R"   & pids+=($!)

## Plot graphs of my cluster
"$HOME/CODE/conky/scripts/munin_rrd_plots.sh" & pids+=($!)


## Clean
wait "${pids[@]}"; pids=()
set -e
echo "took $SECONDS seconds for $0 to complete"
kill "$watchdogpid"
exit 0
