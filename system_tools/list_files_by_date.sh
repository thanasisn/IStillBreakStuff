#!/usr/bin/env bash
## created on 2021-11-17

#### List file by date 
## This accepts multiple folders

FOLDER="$@"

find $FOLDER -type f -print0           |\
    xargs -0 stat --format '%Y :%y %n' |\
    sort -n                            |\
    cut -d: -f2-

exit 0 
