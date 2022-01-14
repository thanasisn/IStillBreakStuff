#!/bin/bash
## created on 2022-01-14

#### Keep a record of all history from all hosts  

storage="$HOME/.global_hist"

find "$HOME"  -maxdepth 1 -iname ".hist*" | while read line ;do
    echo "$line"
    name="$(basename "$line")"
    sed "s/^/$name::/" "$line" >> "$storage"
done    

sort -u -o "$storage" "$storage"

wc -l "$storage"

exit 0 
