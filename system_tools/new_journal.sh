#!/bin/env bash
## created on 2022-12-19
## https://github.com/thanasisn <natsisphysicist@gmail.com>


#### Just create a new .md file with a given local time or current date
## This is meant to run only within the Journal folder

## parse input or create the date variable
args="$*"
if [[ -z "$args" ]]; then
    echo "Using current date"
    stamp="$(date +"%s")"
else
    stamp="$(date -d "${args}" +"%s")"
    [[ $? -gt 0 ]] && echo "Can not parse input as date" && exit 1
fi

datestr="$(date    -d@"${stamp}" +"%F %H:%M %Z")"
datestrs="$(date   -d@"${stamp}" +"%F %T %Z")"
dateUTC="$(date -u -d@"${stamp}" +"%F %T %Z")"
datenme="$(date    -d@"${stamp}" +"%Y-%m-%d_%H%M")"
year="$(date       -d@"${stamp}" +"%Y")"
goto="10"

## create the year folder
mkdir -p "./${year}"
filename="./${year}/${datenme}.md"

## open existing file if exist
if [[ -f "$filename" ]] ; then
    echo "File $filename exist"
    vim "$filename"
    echo "exit"
    exit 0
fi

## create new file with obsidian template
echo  "Creating: $filename"
touch "$filename"
(
    echo "---"
    echo "tags:    [  ]"
    echo "scope:   "
    echo "created: $datestrs"
    echo "UTC:     $dateUTC"
    echo "---"
    echo ""
    echo "## ${datestr}"
    echo ""
    echo ""
    echo ""
) > "$filename"

## open for edit
vim -c "$goto" "$filename"

exit 0
