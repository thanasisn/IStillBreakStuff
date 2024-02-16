#!/usr/bin/env bash
## created on 2022-01-14

#### Keep a record of all history from all hosts  

## master file
storage="$HOME/.global_hist"

find "$HOME" -maxdepth 1 -iname ".hist*" | while read line ;do
    echo "$line"
    ## file name
    name="$(basename "$line")"
    ## append to master file
    sed "s/^/$name::/" "$line" >> "$storage"
done

## sort unique
sort -u -o "$storage" "$storage"

wc -l "$storage"

exit 0 
