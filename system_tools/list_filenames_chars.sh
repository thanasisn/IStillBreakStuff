#!/bin/bash
## created on 2018-12-19

#### list and count file names characters 
## Useful for detecting problematic characters or chars to clean

folder="$1"
: ${folder:="./"}

if [[ ! -d "$folder" ]];then
    echo "Give a folder to process"
    exit
fi

(
find "$folder" -type f -iname "*.*" | while read line;do
    filename="$(basename "${line}")"
    echo "$filename" | sed 's/\(.\)/\1\n/g'
done
) | sort | uniq -c 


exit 0 
