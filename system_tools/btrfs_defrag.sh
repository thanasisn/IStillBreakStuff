#!/bin/bash

#### Defrag all btrfs filesystems


LOGDIR="/home/athan/LOGs/SYSTEM_LOGS"

mkdir -p "$LOGDIR"

logfile="${LOGDIR}/Btrfs_defrag_$(hostname)_$(date +'%F').check"
echo " " > "$logfile"
chmod a+rw  "$logfile"

exec  > >(tee -i "${logfile}")
exec 2> >(tee -i "${logfile}" >&2)



lsblk -f | grep  "btrfs" | grep -o " /.*" | while read device; do
    echo "** Defrag btrfs $device"
    sudo /usr/bin/btrfs filesystem defragment -r -f -v "$device"
    echo "---------------------------------------------"
done


echo ""
echo " STATUS CHECK "
echo ""
sudo -S /usr/bin/btrfs filesystem show | grep -o "/dev/.*" | while read device; do
    echo "** REPORT FOR $device"
    sudo /usr/bin/btrfs device stats "$device"
    echo ""
done

exit
