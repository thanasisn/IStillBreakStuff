#!/bin/bash
## created on 2018-06-05

#### Run conky scripts with every 90 minutes with crontab

## external kill switch
#####################################################################
killfile="/dev/shm/KILL_SWITCH/$(basename "$0")"
[[ -f "$killfile" ]] && echo && echo "KILL SWITCH: $killfile !!!" && exit 99
#####################################################################

## no need to run without a Xserver or headless
#####################################################################
xsessions="$(w | grep -o " :[0-9]\+ " | sort -u | wc -l)"
if [[ $xsessions -gt 0 ]]; then
    echo "Display exists $xsessions"
else
    echo "No X server at \$DISPLAY [$DISPLAY] $xsessions" >&2
    exit 11
fi
#####################################################################


## watchdog script
mainpid=$$
(sleep $((60*30)); kill $mainpid) &
watchdogpid=$!

mkdir -p "/dev/shm/CONKY"

SCRIPTS="$HOME/CODE/conky/scripts/"


## ignore errors
set +e
pids=()

"$HOME/CODE/conky/scripts/transact_plot.R"  & pids+=($!)

(
    ## why we run the old one?
    "$HOME/CODE/training_analysis/GC_plots.R" 
    "$HOME/CODE/training_analysis/GC_read_rides.R" 
    "$HOME/CODE/training_analysis/GC_plots_b.R" 
) & pids+=($!)


wait "${pids[@]}"; pids=()
echo "took $SECONDS seconds for $0 to complete"
kill "$watchdogpid"
exit 0
