#!/bin/bash
## created on 2020-11-08

#### Check status of akk mdraid and btrfs arrays for the host.
## Run locally and hope for a nice notification for errors

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

set +e

auser="athan"
LOGDIR="/home/athan/LOGs/SYSTEM_LOGS"
mkdir -p "$LOGDIR"


NOTIFY_SEND="/home/athan/CODE/system_tools/pub_notifications.py"
statusfile="${LOGDIR}/Disks_$(hostname).status"
logfile="${LOGDIR}/Disks_$(hostname)_$(date +'%F').check"
echo "" > "$logfile"
echo      "$logfile"
touch "$statusfile"


cleanup() {
    ## make all files accessible after running as root
    chown "$auser" "$LOGDIR"
    chmod a+rw     "$LOGDIR"*
    chown "$auser" "$LOGDIR"*
    chmod a+rw     "$logfile"
    chown "$auser" "$logfile"
    chmod a+rw     "$statusfile"
    chown "$auser" "$statusfile"
}

trap cleanup 0 1 2 3 6

## magic redirection for the whole script
exec  > >(tee -i "${logfile}")
exec 2> >(tee -i "${logfile}" >&2)



echo ""
echo "-------------------------------------"
echo "$(date +%F_%R) RAID report on $(hostname)"
echo "-------------------------------------"

ls -d -1 "/dev/md"* | while read device; do
    echo ""
    echo "** REPORT FOR $(hostname) $device **"
    mdadm --detail "${device}"
    echo ""
done



echo "-------------------------------------"
echo "$(date +%F_%R) BTRFS report on $(hostname)"
echo "-------------------------------------"
sudo -S /bin/btrfs filesystem show;
echo

sudo -S /bin/btrfs filesystem show | grep -o "/dev/.*" | while read device; do
    echo "** REPORT FOR $(hostname) $device"
    btrfs device stats "$device"
    echo
done

echo "DONE Probing"
echo ""



## count all btrfs errors for host
btrfserrors="$(
echo "$(cat "$logfile"           |\
        grep "^\[\/dev.*_errs.*" |\
        cut -d' ' -f2-           |\
        sed 's/^[ ]*/ /g'        |\
        sed 's/\r$//g'           |\
        tr '\n' '+'              |\
        sed 's/[ ]*//g'          |\
        sed 's/+$//'             )"  | bc
)"

if [ "$btrfserrors" -gt 0 ]; then
    message="BTRF ERRORS detected on $(hostname) !!"
    body="Sum of errors: $btrfserrors "
    echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
    echo "$message" "$body"
    echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
    notify-send  -u critical "$message" "$body"
    $NOTIFY_SEND -u critical "$message" "$body"
else
    echo "BTRFS status ok!! $btrfserrors"
fi

echo "DONE checking btrfs"
echo ""



## Capture errors on raids
cat "$logfile" | grep "State[ ]\+:[ ]\+" | while read line; do
    key="$(echo $line | cut -d':' -f2- | sed 's/\r$//g' | sed 's/[ ]*//g' )"
    # echo $key
    if [[ "$key" == "clean" || "$key" == "active" ]] ; then
        echo "Raid status ok!! $key"
    else
        echo "Raid status BAD!! $key"
        message="RAID FAULT detected on $(hostname) !!"
        body="Raid md status: $key"
        echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
        echo "$message" "$body"
        echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
        notify-send  -u critical "$message" "$body"
        $NOTIFY_SEND -u critical "$message" "$body"
    fi
done

echo "DONE checking RAID"
echo ""

exit 0