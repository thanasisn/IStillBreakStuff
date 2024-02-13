#!/bin/bash

#### Start a zfs scrub to check data integrity


LOGDIR="/home/athan/LOGs/SYSTEM_LOGS/STORAGE"

mkdir -p "$LOGDIR"

logfile="${LOGDIR}/Zfs_scrub_$(hostname)_$(date +'%F').check"
echo " " > "$logfile"
chmod a+rw  "$logfile"

exec  > >(tee -i "${logfile}")
exec 2> >(tee -i "${logfile}" >&2)

echo "ZFS partitions to scrub:"
zpool list -H -o name

zpool list -H -o name | while read device; do
    echo "** Scrub zfs $device"
    sudo zpool scrub -w "$device"
    echo "---------------------------------------------"
    echo "** Status zfs $device"
    sudo zpool status -v "$device"
    echo "---------------------------------------------"
done


exit 0
