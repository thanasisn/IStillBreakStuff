#!/bin/bash
## created on 2021-10-22

#### Create list of filename (ignoring extensions) occurrences recursively

## Use this list to remove files conditionally that dont match
## example cat ./1_occurances.list | grep "props" | xargs -d '\n' trash

folder="$1"
[ ! -d "$folder" ] && echo "$folder  NOT A FOLDER" && exit


find "$folder" -type f -exec bash -c 'basename "$0" ".${0##*.}"' {} \; |\
    sort |\
    uniq -c  |\
    sort -n  |\
    while read afn ; do
        cnt="$(echo "$afn" | cut -d' ' -f1)"
        pat="$(echo "$afn" | cut -d' ' -f2-)"

        outputfile="${folder}/${cnt}_occurances.list"

        find "$folder" -type f -iname "*${pat}*" >> "$outputfile"

        sort -u  -o "$outputfile" "$outputfile"
    done

exit 0
