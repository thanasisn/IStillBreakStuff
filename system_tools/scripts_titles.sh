#!/bin/bash

#### Get info for scripts containing a specified header

key="####"
folder="$1"


find "$folder" -maxdepth 1 -type f |\
    sort                           |\
    egrep -i '*.sh$|*.R$|*.py$'    |\
    while read line; do
       ff="$(echo "$line" | sed -e "s@$folder/@@g")"
       tt="$(cat "$line" | grep "$key" | head -n1  | sed  "s@.*$key@;@g")" #-e "/$key/d")"
       echo "$ff $tt"
    done | column -t -s ";"



exit


grep "$key" $(find "$folder" -maxdepth 1 -type f  | sort) |\
        sed -e "s@$folder/@@g" -e "s@:$key@;@g" -e "/$key/d" |\
        column -t -s ";"


