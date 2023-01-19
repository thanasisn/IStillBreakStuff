#!/bin/bash

#### Start a btrfs scrub to check data integrity


LOGDIR="/home/athan/LOGs/SYSTEM_LOGS"

mkdir -p "$LOGDIR"

logfile="${LOGDIR}/$0_$(hostname)_$(date +'%F').check"
echo " " > "$logfile"
chmod a+rw  "$logfile"

exec  > >(tee -i "${logfile}")
exec 2> >(tee -i "${logfile}" >&2)

echo "BTRFS partitions to scrub:"
lsblk -f | grep  "btrfs" | grep -o " /.*"

lsblk -f | grep  "btrfs" | grep -o " /.*" | while read device; do
    echo ""
    echo " ** Scrub btrfs $device ** "
    sudo /usr/bin/btrfs scrub start -B -d "$device"
    echo "---------------------------------------------------"
    echo "** Status btrfs $device"
    sudo /usr/bin/btrfs scrub status -d -R "$device"
    echo "---------------------------------------------------"
done

echo
echo "There is and a 'btrfs check' option, to use with care"








exit 0
