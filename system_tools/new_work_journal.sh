#!/bin/env bash
## created on 2024-01-10
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Start a new enty in work journal with the current or given system date
## This is only used to create entries in a specific location

## go to the journal folder
ROOTDIR="$HOME/NOTES/09_JOURNAL_WORK"
cd "$ROOTDIR" || exit

## parse input or create the date variable
args="$*"
if [[ -z "$args" ]]; then
    echo "Using current date"
    stamp="$(date +"%s")"
else
    stamp="$(date -d "${args}" +"%s")"
    [[ $? -gt 0 ]] && echo "Can not parse input as date" && exit 1
fi

datestr="$(date    -d@"${stamp}" +"%F %H:%M %:z")"
datestrs="$(date   -d@"${stamp}" +"%F %T %:z")"
dateUTC="$(date -u -d@"${stamp}" +"%F %T %:z")"
datenme="$(date    -d@"${stamp}" +"%Y-%m-%d_%H%M")"
year="$(date       -d@"${stamp}" +"%Y")"
goto="11"

## create the year folder
mkdir -p "${ROOTDIR}/${year}"
filename="${ROOTDIR}/${year}/${datenme}.md"

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
    echo "tags:      [  ]"
    echo "scope:     Work Journal"
    echo "created:   $datestrs"
    echo "cunixtime: ${stamp}"
    echo "UTC:       $dateUTC"
    echo "---"
    echo ""
    echo "## ${datestr}"
    echo ""
    echo ""
    echo ""
) > "$filename"

## open for edit
vim -c "$goto" "$filename"

echo  "Created: $filename"

exit 0
