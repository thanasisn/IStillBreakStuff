#!/usr/bin/env bash
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Just create a new md file with the current date
## This is to create a quick note

stamp="$(date +"%s")"

filename="$(date -d@$stamp +"%Y%m%d_%H%M.md")"

stamp="$(date +"%s")"
datestr="$(date    -d@"${stamp}" +"%F %T %:z")"
dateUTC="$(date -u -d@"${stamp}" +"%F %T %:z")"
goto="11"

## open existing file
if [[ -f "$filename" ]] ; then
    echo "File $filename exist"
    vim  "$filename"
    echo "exit"
    exit 0
fi

## create new file and open
echo  "Creating: $filename"
touch "$filename"
(
  echo "---"
  echo "tags:      [  ]"
  echo "scope:     "
  echo "created:   $datestr"
  echo "cunixtime: ${stamp}"
  echo "UTC:       $dateUTC"
  echo "---"
  echo ""
  date -d@$stamp +"## %F %H:%M"
  echo ""
  echo ""
  echo ""
) > "$filename"

## open for edit
vim -c "$goto" "$filename"

echo  "Created: $filename"

exit 0
