#!/usr/bin/env bash
## created on 2020-11-08
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Gather S.M.A.R.T. info form all system drives

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

set +x
set +e

## Variables
auser="athan"
LOGDIR="/home/$auser/LOGs/SYSTEM_LOGS/SMART"
mkdir -p "$LOGDIR"

cleanup() {
    ## make all files accessible after running as root
    chown "$auser" "$LOGDIR"
    chmod a+rw     "$LOGDIR"*
    chown "$auser" "$LOGDIR"*
}

trap cleanup 0 1 2 3 6

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
    # outfile="${LOGDIR}/${model}_${serial}_$(date +%F).smart"
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
