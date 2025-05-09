#!/usr/bin/env bash
## created on 2018-06-05

#### Run conky scripts every 30 minutes with crontab

##  External kill switch  ###########################################
killfile="/dev/shm/KILL_SWITCH/$(basename "$0")"
[[ -f "$killfile" ]] && echo && echo "KILL SWITCH: $killfile !!!" && exit 99
# ##  Dot no run headless  ############################################
# xsessions="$(w | grep -o " :[0-9]\+ " | sort -u | wc -l)"
# if [[ $xsessions -gt 0 ]]; then
#     echo "Display exists $xsessions"
# else
#     echo "No X server at \$DISPLAY [$DISPLAY] $xsessions" >&2
#     exit 0
# fi
##  Watchdog for script  ############################################
mainpid=$$
(sleep $((60*20)); kill $mainpid) &
watchdogpid=$!

##  MAIN  ############################################################

## Init
mkdir -p "/dev/shm/CONKY"
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


(
#     "$HOME/BASH/mail_auto/gmailr_get_accounts_alerts.R"
#    "$HOME/BASH/mail_auto/parse_accounts_alerts.R"
    # new parser
    "$HOME/BASH/mail_auto/scrap_noa/run_noa_mail.R
) & pids+=($!)


## Clean
wait "${pids[@]}"; pids=()
set -e
echo "took $SECONDS seconds for $0 to complete"
kill "$watchdogpid"
exit 0
