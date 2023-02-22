#!/bin/bash
## created on 2022-12-19
## https://github.com/thanasisn <natsisphysicist@gmail.com>


#### Just create a new .md file with a given or current date 
## This is meant to run only within the Journal folder

## go to the folder
# cd "$HOME/PANDOC/Journal"

## parse or create the date variable
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

## create the folder
mkdir -p "./${year}"
filename="./${year}/${datenme}.md"

## open existing file
if [[ -f "$filename" ]] ; then
    echo "File $filename exist"
    vim "$filename"
    echo "exit"
    exit 0
fi

## open a new file
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
