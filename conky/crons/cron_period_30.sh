#!/bin/bash
## created on 2018-06-05

#### Run conky scripts with every 10 minutes with crontab

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
(sleep $((60*20)); kill $mainpid) &
watchdogpid=$!


## ignore errors
set +e
pids=()


# (
#     "$HOME/CODE/conky/scripts/meteoblue_get.sh" 
#     "$HOME/CODE/conky/scripts/getForecast_DarkSkyNet.R" 
# ) & pids+=($!)


(
    "$HOME/CODE/conky/scripts/getCurrent_OpenWeather.R" 
    "$HOME/CODE/conky/scripts/getForecast_OpenWeather.R" 
) & pids+=($!)


"$HOME/CODE/conky/scripts/get_open_meteo_api.R"  & pids+=($!)


## corona virus plot
#"${SCRIPTS}wikipd.R"              &
#"${SCRIPTS}rls_choose.sh" 90      &


(
    "$HOME/BASH/mail_auto/gmailr_get_accounts_alerts.R" 
    "$HOME/BASH/mail_auto/parse_accounts_alerts.R"
) & pids+=($!)


wait "${pids[@]}"; pids=()
echo "took $SECONDS seconds for $0 to complete"
kill "$watchdogpid"
exit 0
