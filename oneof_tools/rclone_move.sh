#!/bin/bash
## created on 2021-06-08

#### Find and copy files inside google drive
## Usefull for moving a lot of files

rclone --config ~/Documents/rclone.conf lsf "natsisthanasis:/" --include="/sms-*.xml" |\
    rclone --config ~/Documents/rclone.conf copy "natsisthanasis:/"  "natsisthanasis:/sms" --include-from=- -vv

rclone --config ~/Documents/rclone.conf lsf "natsisthanasis:/" --include="/calls-*.xml" |\
    rclone --config ~/Documents/rclone.conf copy "natsisthanasis:/"  "natsisthanasis:/sms" --include-from=- -vv


exit 0
