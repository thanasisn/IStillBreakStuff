#!/bin/bash
## created on 2020-11-08
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### Gather information for hard disks and arrays
## For btrfs and raid arrays

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

set +x

## Variables
USER="athan"
LOGDIR="/home/$USER/LOGs/SYSTEM_LOGS"

mkdir -p "$LOGDIR"

logfile="${LOGDIR}/Disks_$(hostname)_$(date +'%F').check"
echo " " > "$logfile"

cleanup() {
    ## make all files accessible when running as root
    chown $USER "$LOGDIR"
    chmod a+rw  "$LOGDIR"*
    chown $USER "$LOGDIR"*
    chmod a+rw  "$logfile"
    chown $USER "$logfile"
}

trap cleanup 0 1 2 3 6

## magic redirection for the whole script
exec  > >(tee -i "${logfile}")
#exec 2> >(tee -i "${logfile}" >&2)

echo ""
echo "Log file: $logfile"
echo ""
echo "----------------------------------------------------------------"
echo ""
echo "$(date +%F_%R) ** RAID report start on $(hostname) ** "
echo ""

ls -d -1 "/dev/md"* | while read device; do
    echo ""
    echo "** REPORT FOR $device **"
    /usr/sbin/mdadm --detail "${device}"
    echo ""
done

echo ""
echo "$(date +%F_%R) ** RAID report end ** "
echo ""
echo "----------------------------------------------------------------"
echo ""
echo "$(date +%F_%R) BTRFS report start on $(hostname)"
echo ""
sudo -S /bin/btrfs fi show;
echo

sudo -S /bin/btrfs fi show | grep -o "/dev/.*" | while read device; do
    echo "** REPORT FOR $device"
    btrfs device stats "$device"
    echo ""
done

echo "$(date +%F_%R) ** RAID report end ** "
echo ""
echo "----------------------------------------------------------------"
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
sudo mount -l
echo ""
echo "----------------------------------------------------------------"
echo ""
echo " ** ls -lF /dev/disk/by-id/ ** "
echo ""
sudo ls -lF /dev/disk/by-id/ 
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

ls -1 "/dev/sd"? | while read device; do
    echo ""
    sudo sfdisk -d "$device" 
    echo ""
done

echo "----------------------------------------------------------------"

echo "## report end ##"
echo "Report file: $logfile"

exit 0
