#!/usr/bin/env bash
## created on 2021-10-22

#### Create list of filename (ignoring extensions) occurrences recursively

## Useful for checking of side files
## Use this list to remove files conditionally that don't match
## example cat ./1_occurances.list | grep "props" | xargs -d '\n' trash

folder="$1"
[ ! -d "$folder" ] && echo "$folder  NOT A FOLDER" && exit

suffix="occurrences.list"

## get filename at first "."
find "$folder" -type f -exec basename {} \; |\
    cut -d'.' -f1 |\
    sort          |\
    uniq -c       |\
    while read afn ; do
        cnt="$(echo "$afn" | cut -d' ' -f1)"
        pat="$(echo "$afn" | cut -d' ' -f2-)"
        outputfile="${folder}/${cnt}_f_${suffix}"
        find "$folder" -type f -iname "*${pat}*" >> "$outputfile"
        echo "" >> "$outputfile"
    done


## get filename at last "."
find "$folder" -type f -exec bash -c 'basename "$0" ".${0##*.}"' {} \; |\
    sort     |\
    uniq -c  |\
    sort -n  |\
    while read afn ; do
        cnt="$(echo "$afn" | cut -d' ' -f1)"
        pat="$(echo "$afn" | cut -d' ' -f2-)"
        outputfile="${folder}/${cnt}_l_${suffix}"
        find "$folder" -type f -iname "*${pat}*" | sort >> "$outputfile"
        echo "" >> "$outputfile"
    done


find "$folder" -type f -name "*${suffix}*" |\
    while read al; do
        echo "$al"
#        sort -u  -o "$al" "$al"
    done


exit 0
