#!/bin/env bash
## created on 2024-01-10
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Start a new .md file with a given or current date
## This is only used to create entries in a specific location

## go to the journal folder
cd "$HOME/PANDOC/Notes/08_JOURNAL" || exit

## parse input or create the date variable
args="$*"
if [[ -z "$args" ]]; then
    echo "Using current date"
    stamp="$(date +"%s")"
else
    stamp="$(date -d "${args}" +"%s")"
    [[ $? -gt 0 ]] && echo "Can not parse input as date" && exit 1
fi

datestr="$(date -d@"${stamp}" +"%F %H:%M")"
datestrs="$(date -d@"${stamp}" +"%F %T")"
datenme="$(date -d@"${stamp}" +"%Y-%m-%d_%H%M")"
year="$(date -d@"${stamp}" +"%Y")"
goto="9"

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
    echo "tags:   [ empty ]"
    echo "scope:  Personal Journal"
    echo "creted: $datestrs"
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

