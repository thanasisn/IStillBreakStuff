#!/bin/bash

#### Scrub all btrfs filesystems


LOGDIR="/home/athan/LOGs/SYSTEM_LOGS"

mkdir -p "$LOGDIR"

logfile="${LOGDIR}/Btrfs_scrub_$(hostname)_$(date +'%F').check"
exec  > >(tee -i "${logfile}")
exec 2> >(tee -i "${logfile}" >&2)

echo "** Start **"
chmod a+rw  "$logfile"

echo ""
echo " * * * READ ONLY SCRUB * * * "

lsblk -f | grep  "btrfs" | grep -o " /.*" | while read device; do
    echo ""
    echo "** Scrub btrfs $device"
    sudo /usr/bin/btrfs scrub start -B -d -r "$device"
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

chmod a+rw  "$logfile"

exit
