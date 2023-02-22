#!/bin/bash
## created on 2020-11-08
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Gather S.M.A.R.T. info on all system drives

if sudo true; then
    true
else
    echo 'Root privileges required'
    exit 1
fi

set +x

## Variables init
USER="athan"
LOGDIR="$HOME/LOGs/SYSTEM_LOGS"
mkdir -p "$LOGDIR"

## Loop all devices
for ad in /dev/sd[a-z] /dev/sd[a-z][a-z]; do
    if [[ ! -e $ad ]]; then continue ; fi
    echo ""
    echo "Doing: $ad"
    ## get info we need
    data="$(sudo smartctl -a "$ad")"
    ## prepare info data
    model="$(   echo "$data" | grep -i "device model:"    | sed 's/[ ]\+/ /g' | cut -d":" -f2- | sed 's/^[ ]*//g' | sed 's/[ ]\+/-/g')"
    serial="$(  echo "$data" | grep -i "serial number:"   | sed 's/[ ]\+//g'  | cut -d":" -f2- | sed 's/^[ ]*//g' | sed 's/[ ]\+/-/g')"
    hourson="$( echo "$data" | grep -i "Power_On_Hours"   | sed 's/[ ]\+/ /g' | grep -o "[0-9]\+[ ]*$")"
    minhoron="$(echo "$data" | grep -i "Power_On_Minutes" | sed 's/[ ]\+/ /g' | cut -d" " -f11 | sed 's/h.*//g')"
    ## ouput file
    outfile="${LOGDIR}/${model}_${serial}.smart"
    ## generate report
    (
        echo ""
        date +"====  %F %R  ===="
        echo ""
        echo "Mounted on: $(hostname)"
        echo ""
        echo "Hours on:  $hourson"
        echo "Days on:   $((hourson/24))"
        echo "On:        $((hourson/24/365)) years  $((hourson/24 - 365*(hourson/24/365))) days"
        echo "Minutes on: $minhoron"
        echo ""
        echo "** smartctl -H **"
        sudo smartctl -H "$ad"
        echo ""
        echo "** smartctl -a **"
        sudo smartctl -a "$ad"
        echo ""
        echo "** smartctl -x **"
        sudo smartctl -x "$ad"
        echo ""
    ) | tee "$outfile"
    chmod a+rw  "$outfile"
    echo "$outfile"
done

exit 0
