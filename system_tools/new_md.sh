#!/bin/bash
## created on 2020-04-02

#### Just create a new md file with the current date

stamp="$(date +"%s")"

filename="$(date -d@$stamp +"%Y%m%d_%H%M.md")"

if [[ -f "$filename" ]] ; then
    echo "File $filename exist"
    echo "exit"
    exit 0
fi

echo  "$filename"
touch "$filename"

(
echo ""
date -d@$stamp +"## %F %H:%M"
echo ""
) > "$filename"

exit 0
