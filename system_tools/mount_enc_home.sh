#!/bin/bash

#### Mount an encrypted LUKS partition over users home

## can add to .profile
## . "$HOME/mount_enc_home.sh"

## or to session manager
## . xfce4-terminal -e "$HOME/mount_enc_home.sh"

## can add to /etc/sudoers
## athan ALL=(ALL) NOPASSWD:/sbin/cryptsetup luksOpen
## athan ALL=(ALL) NOPASSWD:/sbin/cryptsetup luksClose
## athan ALL=(ALL) NOPASSWD:/usr/sbin/dmsetup ls


cryptpart="/dev/sda2"
cryptname="crypthome"
mountpath="/home/athan"

## try to open crypt partition
if sudo /usr/sbin/dmsetup ls | grep -q "$cryptname"; then
    echo "$cryptname is open"
else
    echo "Open $cryptname"
    sudo /sbin/cryptsetup luksOpen "$cryptpart" "$cryptname"
fi

## check if it is open
if sudo /usr/sbin/dmsetup ls | grep -q "$cryptname"; then
    :
else
    echo "$cryptname NOT open"
    echo "Will not mount to $mountpath"
    exit 1
fi

## mount open partition
if mountpoint -q "$mountpath"; then
    echo "$mountpath is mounted"
    echo " - - done - - "
    exit 0
else
    echo "$mountpath NOT mounted"
    sudo /usr/bin/mount -v "/dev/mapper/$cryptname" "$mountpath"
fi

## now should be mounted
echo " - - end - - "
echo " run 'cd' "
exit
