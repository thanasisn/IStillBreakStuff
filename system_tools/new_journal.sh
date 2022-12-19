#!/bin/bash
## created on 2022-12-19
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### Just create a new .md file 
## This is meant to run only within the Journal folder

## parse or create the date variable

## go to the folder
cd "$HOME/PANDOC/Journal"

args="$*"

if [[ -z "$args" ]]; then
    echo "Using current date"
    stamp="$(date +"%s")"
else
    stamp="$(date -d "${args}" +"%s")"
    [[ $? -gt 0 ]] && echo "Can not parse input as date" && exit 1 
fi 

datestr="$(date -d@"${stamp}" +"%F %H:%M")"
datenme="$(date -d@"${stamp}" +"%Y%m%d_%H%M")"
year="$(date -d@"${stamp}" +"%Y")"
goto="6"

## create the file and/of folder

mkdir -p "./${year}"
filename="./${year}/${datenme}.md"

if [[ -f "$filename" ]] ; then
    echo "File $filename exist"
    vim -c "$goto" "$filename"
    echo "exit"
    exit 0
fi

echo  "Creating: $filename"
touch "$filename"
(
    echo ""
    echo "## ${datestr}"
    echo ""
    echo "[//]: # (Keywords: #key_1, #key_2)"
    echo ""
    echo ""
) > "$filename"

vim -c "$goto" "$filename"

exit 0
