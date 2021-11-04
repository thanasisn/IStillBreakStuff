#!/bin/bash

#### Unmount mounted user home and clos LUKS

##TODO luksClose don't always close

mountpath="/home/athan"
cryptname="crypthome"


## unmount home
if mountpoint -q "$mountpath"; then
    echo "$mountpath is mounted"
    sudo /usr/bin/umount -v -l -f "$mountpath"
else
    echo "$mountpath NOT mounted"
fi

if mountpoint -q "$mountpath"; then
    echo "$mountpath is STILL mounted"
fi

## close LUKS

sudo /sbin/cryptsetup -v luksClose "$cryptname"


## should try to close all connected programs first

