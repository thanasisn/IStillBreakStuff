#!/bin/bash
## created on 2020-11-08
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Check status of md-raid, zfs and btrfs arrays for a host.
## Run locally and hope for a nice notification for errors

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

set +x
set +e

## Variables
auser="athan"
LOGDIR="/home/$auser/LOGs/SYSTEM_LOGS/STORAGE"
mkdir -p "$LOGDIR"


NOTIFY_SEND="/home/athan/CODE/system_tools/pub_notifications.py"
statusfile="${LOGDIR}/Disks_check_$(hostname).status"
logfile="${LOGDIR}/Disks_check_$(hostname)_$(date +'%F').check"
echo "** Report **" > "$logfile"
echo "** Status **" > "$statusfile"


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
echo "Log file: $logfile"
echo "====================================="
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

## for each btrfs filesystem
sudo -S /bin/btrfs filesystem show | grep -o "/dev/.*" | while read device; do
    echo "** REPORT FOR $(hostname) $device"
    btrfs device stats "$device"
    echo ""
done


echo "-------------------------------------"
echo "$(date +%F_%R) ZFS report on $(hostname)"
echo "-------------------------------------"
sudo -S zpool status -v
echo

echo "====================================="
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
    message="BTRFS ERRORS on $(hostname) !!"
    body="Sum of errors: $btrfserrors "
    echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
    echo "$message" "$body"
    echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
    sudo -u "$auser" notify-send  -t 999999999 -u critical "${message} !" "$body"
    $NOTIFY_SEND -t 999999999 -u critical "${message} !!" "$body"
    echo "$message" >> "$statusfile"
    echo "$body"    >> "$statusfile"
else
    echo "BTRFS status ok!! $btrfserrors"
    echo "BTRFS status ok!! $btrfserrors" >> "$statusfile"
fi

echo "DONE checking btrfs"
echo ""



## Capture errors on raids
cat "$logfile" | grep "State[ ]\+:[ ]\+" | while read line; do
    key="$(echo $line | cut -d':' -f2- | sed 's/\r$//g' | sed 's/[ ]*//g' )"
    # echo $key
    if [[ "$key" == "clean" || "$key" == "active" ]] ; then
        echo "Raid status ok!! $key"
        echo "Raid status ok!! $key" >> "$statusfile"
    else
        echo "MD Raid status BAD!! $key"
        message="MD RAID FAULT on $(hostname) !!"
        body="MD Raid status: $key"
        echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
        echo "$message" "$body"
        echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
        sudo -u "$auser" notify-send -t 999999999 -u critical "$message" "$body"
        $NOTIFY_SEND -t 999999999 -u critical "$message" "$body"
        echo "$message" >> "$statusfile"
        echo "$body"    >> "$statusfile"
    fi
done

echo "DONE checking MD RAID"
echo ""



## capture errors on zfs
condition="$( sudo -S zpool status -v | egrep -i '(DEGRADED|SUSPENDED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED|corrupt|cannot|unrecover)')"
if [ "${condition}" ]; then
    echo "Something is not working in ZFS!!"
    echo ""
    echo "${condition}"
    echo ""
    body="$(zpool status | grep "^[ ]*errors")"
    message="ZFS ERRORS on $(hostname) !!"
    echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
    echo "$message" "$body"
    echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
    sudo -u "$auser" notify-send -t 999999999 -u critical "$message" "$body"
    $NOTIFY_SEND -t 999999999 -u critical "$message" "$body"
    echo "$message" >> "$statusfile"
    echo "$body"    >> "$statusfile"
else
    echo "ZFS status ok!! "
    echo "ZFS status ok!! " >> "$statusfile"
fi

echo "DONE checking ZFS"
echo ""



exit 0
