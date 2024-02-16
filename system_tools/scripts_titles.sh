#!/usr/bin/env bash
## https://github.com/thanasisn <natsisphysicist@gmail.com>


#### Get info for scripts containing a specified header

key="####"
folder="$1"


find "$folder" -maxdepth 1 -type f |\
    sort                           |\
    egrep -i '*.sh$|*.R$|*.py$'    |\
    while read line; do
       ff="$(echo "$line" | sed -e "s@$folder/@@g" | sed 's/.\///')"
       tt="$(cat "$line" | grep "$key" | head -n1  | sed "s@.*$key@;@g" | sed 's/;[ \t]*/; /')"
       echo "$ff $tt"
    done | column -t -s ";"


exit 0

