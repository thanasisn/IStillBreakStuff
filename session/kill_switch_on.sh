#!/usr/bin/env bash
## created on 2017-05-25

#### Switch on a kill switch for a list of appropriate scripts

## Have to add a kill switch block in each one of those
all=(
    'killswitch test 2.sh'
    'CODE/conky/crons/cron_period_03.sh'
    'CODE/conky/crons/cron_period_10.sh'
    'CODE/conky/crons/cron_period_30.sh'
    'CODE/conky/crons/cron_period_90.sh'
)




## Locks location
KILLDIR="/dev/shm/KILL_SWITCH/"

## target dir
mkdir -p "$KILLDIR"

for i in "${all[@]}" ; do
    filepath="$(basename "$i")"
    killfile="${KILLDIR}/${filepath}"
    echo "" ; input=0
    echo "Apply lock:   $filepath "
    echo -n " (y/n)?: "
    read -n 1 input
    if [ "$input" == "y" -o "$input" == "Y" ] ; then
        ## issue lock for script
        date +"%F %T" >> "$killfile"
        echo "          LOCKED !!"
    else
        echo "          free to run"
    fi
done

echo
echo "FINISH"
echo
exit 0

# kill switch example
#####################################################################
# killfile="/dev/shm/KILL_SWITCH/$(basename "$0")"
# [[ -f "$killfile" ]] && echo && echo "KILL SWITCH: $killfile !!!" && exit 999
#####################################################################
