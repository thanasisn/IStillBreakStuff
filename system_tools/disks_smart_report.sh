#!/bin/bash
## created on 2020-11-08
## https://github.com/thanasisn <lapauththanasis@gmail.com>

#### Gather S.M.A.R.T. info on all system drives

if sudo true; then
    true
else
    echo 'Root privileges required'
    exit 1
fi

set +x

## Variables
USER="athan"
LOGDIR="$HOME/LOGs/SYSTEM_LOGS"

mkdir -p "$LOGDIR"


## Loop all devices
find "/dev/" -name "*sd?" | while read ad; do
    echo "Doing: $ad"

    ## get info we need
    data="$(sudo smartctl -a "$ad")"
    ## prepare data
    model="$(   echo "$data" | grep -i "device model:"    | sed 's/[ ]\+/ /g' | cut -d":" -f2- | sed 's/^[ ]*//' | sed 's/[ ]\+/-/')"
    serial="$(  echo "$data" | grep -i "serial number:"   | sed 's/[ ]\+//g'  | cut -d":" -f2- | sed 's/^[ ]*//' | sed 's/[ ]\+/-/')"
    hourson="$( echo "$data" | grep -i "Power_On_Hours"   | sed 's/[ ]\+/ /g' )"
    minhoron="$(echo "$data" | grep -i "Power_On_Minutes" | sed 's/[ ]\+/ /g' )"

    outfile="${LOGDIR}/${model}_${serial}.smart"

    (
        echo ""
        date +"====  %F %R  ===="
        echo ""
        echo "Mounted on: $(hostname)"
        echo ""
        echo "$hourson"
        echo "$minhoron"
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
