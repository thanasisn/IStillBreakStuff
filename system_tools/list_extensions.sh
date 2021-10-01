#!/bin/bash
## created on 2016-09-24
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### list unique extensions and count them

folder="$1"
: ${folder:="./"}

if [ ! -d "$folder" ];then
    echo "Give a folder"
    exit 1
fi

## list counts of each tipe
echo " FOLDER:  $folder "
echo ""
echo "----  Counts  ----"
echo ""

find "$folder" -type f -iname "*.*" |\
    grep -o -E "\.[^\.]+$"          |\
    awk '{print tolower($0)}'       |\
    sort                            |\
    uniq -c                         |\
    sort -n
echo " $(find "$folder"  -type f ! -name "*.*" | wc -l)  NO EXTENSION "

## list just the extensions
echo ""
echo "----  Sorted    ----"
echo ""

find "$folder" -type f -iname "*.*" |\
    grep -o -E "\.[^\.]+$"          |\
    awk '{print tolower($0)}'       |\
    sort -u



# find "$folder" -type f | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort -u

# find "$folder" -type f | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort | uniq -c | sort -n

# find "$folder" -type f -iname "*.*" | grep -o -E "\.[^\.]+$" | awk '{print tolower($0)}' | sort -u

exit 0
