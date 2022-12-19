#!/bin/bash
## created on 2022-12-19
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### Just create a new md file with the current date and title

##TODO get all arguments and concat to one filename

[[ -z "$1" ]] && { echo "Give a name for the new file" ; exit 1; }

filename="${1}.md"

stamp="$(date +"%s")"
datestr="$(date -d@${stamp} +"%Y %b %d %A  #timestamp:'%F %T'")"

if [[ -f "$filename" ]] ; then
    echo "File $filename exist"
    echo "exit"
    exit 0
fi

echo  "Creating: $filename"
touch "$filename"

(
    echo ""
    echo "## ${1}"
    echo "Created: ${datestr}"
    echo ""
    echo ""
) > "$filename"

vim "$filename"


exit 0
