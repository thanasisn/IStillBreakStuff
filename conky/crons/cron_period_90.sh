#!/usr/bin/env bash
## created on 2018-06-05

#### Run conky scripts with every 90 minutes with crontab

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
(sleep $((60*30)); kill $mainpid) &
watchdogpid=$!

##  MAIN  ############################################################

## Init
mkdir -p "/dev/shm/CONKY"
set +e
pids=()


"$HOME/BASH/TOOLS/brave_history_clean.sh"   & pids+=($!)
# "$HOME/BASH/CRON/gather_winb_email.R"       & pids+=($!)
# "$HOME/CODE/conky/scripts/transact_plot.R"  & pids+=($!)


(
"$HOME/CODE/training_analysis/GC_data_proccess/GC_update_all.R"
# "$HOME/CODE/training_analysis/GC_shoes_usage_duration.R"
# "$HOME/CODE/training_analysis/GC_shoes_usage_timeseries.R"
# "$HOME/CODE/training_analysis/GC_target_load.R"
# "$HOME/CODE/training_analysis/GC_target_estimation.R"
) & pids+=($!)




## Clean
wait "${pids[@]}"; pids=()
set -e
echo "Took $SECONDS seconds for $0 to complete"
kill "$watchdogpid"
exit 0
