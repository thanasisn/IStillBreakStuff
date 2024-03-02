#!/bin/bash
## created on 2020-11-27

#### Gather info of a system in order to be able to reconfigure it
## It gathers info commands and output in log files## It gathers info commands and output in log files## It gathers info commands and output in log files

ldir="/home/athan/LOGs/SYSTEM_LOGS/"
mkdir -p "$ldir"

ID="$1"
: ${ID:=$(hostname)}
SCRIPT="$(basename "$0")" 


LOG_FILE="${ldir}/${SCRIPT}_${ID}_$(date +%F).log"
PAC_LIST="${ldir}/${SCRIPT}_${ID}_$(date +%F).tar.xz"

echo
echo "OUTPUT: $LOG_FILE" 
echo

set +e

## run a command and capture output
run() { 
    echo "--------------------------------------" | tee -a "$LOG_FILE"
    echo "$*"                                     | tee -a "$LOG_FILE"
    echo "--------------------------------------" | tee -a "$LOG_FILE"
    $*                                            | tee -a "$LOG_FILE"
    echo "--------------------------------------" | tee -a "$LOG_FILE"
    echo ""                                       | tee -a "$LOG_FILE"
}


## display section name
dis() {
    echo ""    | tee -a "$LOG_FILE"
    echo "$*"  | tee -a "$LOG_FILE"
    echo ""    | tee -a "$LOG_FILE"
}


dis " ** $(hostname) SYSTEM INFO $(date +%F) ** "
dis "INFO: OS"

run cat /etc/os-release
run lsb_release -a
run hostnamectl
run uname -a



dis "INFO: Disk and partitions"

run lsblk
run lsblk -f
run sudo parted -l
run sudo fdisk -l
run df -h
run hdparm -i /dev/sd?



dis "INFO: mount"

run mount -l
run findmnt



dis "INFO: btrfs"

run sudo btrfs filesystem show

##TODO info for btrfs subvolumes



dis "INFO: raid md"

run cat /proc/mdstat
run sudo mdadm --query /dev/md*
run sudo mdadm --query --detail /dev/md*



dis "INFO: Hardware"

run lscpu
run sudo lshw
run sudo hwinfo --short
run sudo hwinfo


dis "INFO: inxi"

run inxi -F



dis "INFO: list of packages"

run dpkg --get-selections
run aptitude search '~i!~M'
run apt-mark showmanual



dis "LIST END"
echo "OUTPUT: $LOG_FILE"


echo "CREATE ARCHIVE"
## this is also used by an old scheme but is still useful

dpkg     --get-selections                     > "/dev/shm/$(hostname)"_$(date +"%F")_1.packlist
aptitude search '~i!~M'                       > "/dev/shm/$(hostname)"_$(date +"%F")_2.packlist
dpkg     --get-selections | grep -v deinstall > "/dev/shm/$(hostname)"_$(date +"%F")_3.packlist


sudo tar --ignore-failed-read -cvf - \
    "/etc"                                          \
    "/home/athan/.ssh"                              \
    "/root/.ssh"                                    \
    "/home/ppss/.ssh"                               \
    "/var/spool/cron"                               \
    "$LOG_FILE"                                     \
    "/dev/shm/$(hostname)"_$(date +"%F")_1.packlist \
    "/dev/shm/$(hostname)"_$(date +"%F")_2.packlist \
    "/dev/shm/$(hostname)"_$(date +"%F")_3.packlist |\
              xz -9 -c - > "$PAC_LIST"


echo "OUTPUT: $PAC_LIST"


exit
