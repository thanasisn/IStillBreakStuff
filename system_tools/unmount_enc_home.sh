#!/usr/bin/env bash

#### Unmount mounted user home and close LUKS

mountpath="/home/athan"
cryptname="crypthome"

## unmount home
if mountpoint -q "$mountpath"; then
    echo "$mountpath is mounted"
    sudo /usr/bin/umount -v -f "$mountpath"
    sudo /usr/bin/umount -v -l "$mountpath"
else
    echo "$mountpath NOT mounted"
fi

if mountpoint -q "$mountpath"; then
    echo "$mountpath is STILL mounted"
fi

## close LUKS
sudo /sbin/cryptsetup -v luksClose "$cryptname"
sudo /sbin/cryptsetup -v close "$cryptname"
sudo /sbin/cryptsetup -v status "$cryptname"

echo " - - end - - "
echo " run 'cd' "
exit
