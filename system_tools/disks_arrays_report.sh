#!/usr/bin/env bash
## created on 2020-11-08
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Gather information for hard disks, partitions and storage arrays
## Also useful for btrfs, zfs and md raid arrays

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

set +x
set +e

## Variables
auser="athan"
LOGDIR="/home/athan/LOGs/SYSTEM_LOGS/STORAGE"
mkdir -p "$LOGDIR"


NOTIFY_SEND="/home/athan/CODE/system_tools/pub_notifications.py"
# statusfile="${LOGDIR}/Disks_report_$(hostname).status"
logfile="${LOGDIR}/Disks_report_$(hostname)_$(date +'%F').check"
echo "" > "$logfile"
# touch "$statusfile"


cleanup() {
    ## make all files accessible after running as root
    chown "$auser" "$LOGDIR"
    chmod a+rw     "$LOGDIR"*
    chown "$auser" "$LOGDIR"*
    chmod a+rw     "$logfile"
    chown "$auser" "$logfile"
    # chmod a+rw     "$statusfile"
    # chown "$auser" "$statusfile"
}

trap cleanup 0 1 2 3 6

## magic redirection for the whole script
exec  > >(tee -i "${logfile}")
exec 2> >(tee -i "${logfile}" >&2)

echo ""
echo "Log file: $logfile"
echo ""
echo "================================================================"



## check storage arrays first
echo ""
echo "$(date +%F_%R) ** RAID report start on $(hostname) ** "
echo ""

ls -d -1 "/dev/md"* | while read device; do
    echo ""
    echo "** REPORT FOR $(hostname) $device **"
    mdadm --detail "${device}"
    echo ""
done

echo ""
echo "----------------------------------------------------------------"



echo ""
echo "$(date +%F_%R) BTRFS report start on $(hostname)"
echo ""
sudo -S /bin/btrfs filesystem show
echo ""

## stats on each file system
sudo -S /bin/btrfs filesystem show | grep -o "/dev/.*" | while read device; do
    echo "** REPORT FOR $(hostname) $device"
    btrfs device stats "$device"
    echo ""
done

echo "----------------------------------------------------------------"



echo ""
echo "$(date +%F_%R) ZFS report start on $(hostname)"
echo ""
## get health status
sudo -S zpool status -v
echo ""
## get all properties
sudo -S zfs get all
echo ""
echo "----------------------------------------------------------------"




## general info on devices and partitions
echo ""
echo "$(date +%F_%R) file system report start on $(hostname)"
echo ""
echo " ** lsblk -af ** "
echo ""
sudo lsblk -af
echo ""
echo "----------------------------------------------------------------"
echo ""
echo " ** df -h ** "
echo ""
sudo df -h
echo ""
echo "----------------------------------------------------------------"
echo ""
echo " ** fdisk -l ** "
echo ""
sudo fdisk -l
echo ""
echo "----------------------------------------------------------------"
echo ""
echo " ** mount -l ** "
echo ""
sudo mount -l | column -t
echo ""
echo "----------------------------------------------------------------"
echo ""
echo " ** ls -lF /dev/disk/by-id/ ** "
echo ""
sudo ls -lF /dev/disk/by-id/ 
echo ""
echo "----------------------------------------------------------------"
echo ""
echo " ** findmnt ** "
echo ""
sudo findmnt --list --real --output-all --notruncate
echo ""
echo "----------------------------------------------------------------"
echo ""
echo " ** lshw -short -C disk ** "
echo ""
sudo lshw -short -C disk 
echo ""
echo "----------------------------------------------------------------"
echo ""
echo " ** sfdisk -d disk ** "
echo ""
echo "----------------------------------------------------------------"
echo ""
echo " ** hdparm ** "
echo ""
sudo hdparm -I /dev/sd*

ls -1 "/dev/sd"? | while read device; do
    echo ""
    sudo sfdisk -d "$device" 
    echo ""
done



echo "================================================================"
echo "## report end ##"
LC_ALL=C sed -i 's/[^\x0-\xB1]//g' "$logfile"
echo "Report file: $logfile"

exit 0
