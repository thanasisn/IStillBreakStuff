#!/bin/bash
## created on 2020-11-08
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### Gather S.M.A.R.T. info on all system drives

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

set +x

## Variables
USER="athan"
LOGDIR="/home/$USER/LOGs/SYSTEM_LOGS"

mkdir -p "$LOGDIR"


## Main ##

find "/dev/" -name "*sd?" | while read ad; do
    echo "Doing: $ad"

    ## get info we need
    data="$(/usr/sbin/smartctl -a $ad)"
    ## prepare data
    model="$(echo "$data" | grep -i "device model:"  | sed 's/[ ]\+/ /g' | cut -d":" -f2- | sed 's/^ //' | sed 's/ /_/g')"
    serial="$(  echo "$data" | grep -i "serial number:"   | sed 's/[ ]\+//g'  | cut -d":" -f2-)"
    hourson="$( echo "$data" | grep -i "Power_On_Hours"   | sed 's/[ ]\+/ /g' | cut -d" " -f11)"
    minhoron="$(echo "$data" | grep -i "Power_On_Minutes" | sed 's/[ ]\+/ /g' | cut -d" " -f11 | sed 's/h.*//g')"

    outfile="${LOGDIR}/${model}_${serial}.smart"

    (
        echo ""
        echo "Mount on: $(hostname)"
        echo "Power on: $(( hourson / 24 )) days"
        echo "Mins on?: $minhoron hours?"
        echo ""
        echo "** smartctl -a **"
        /usr/sbin/smartctl -a $ad
        echo ""
        echo "** smartctl -x **"
        /usr/sbin/smartctl -x $ad
        echo ""
    ) | tee "$outfile"

    chmod a+rw  "$outfile"
    echo "$outfile"

done

exit 0
