#!/bin/bash

#### Start a btrfs scrub to check data integrity


LOGDIR="/home/athan/LOGs/SYSTEM_LOGS"

mkdir -p "$LOGDIR"

logfile="${LOGDIR}/Btrfs_scrub_$(hostname)_$(date +'%F').check"
echo " " > "$logfile"

exec  > >(tee -i "${logfile}")
# exec 2> >(tee -i "${logfile}" >&2)


lsblk -f | grep  "btrfs" | grep -o " /.*" | while read device; do
    echo "** Scrub btrfs $device"
    sudo /usr/bin/btrfs scrub start -B  "$device"
    echo "---------------------------------------------"
done

echo
echo "There is and a 'btrfs check' option, to use with care"

exit 0
