#!/usr/bin/env bash
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Just create a new md file with the current date and title
## This is to create notes with descriptive filenames

##TODO get all arguments and concat to one filename

[[ -z "$1" ]] && { echo "Give a name for the new file" ; exit 1; }

filename="${1%.md}.md"

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
  echo "## $(basename "${1}" | sed 's/_/ /g')"
  echo ""
  echo ""
  echo ""
) > "$filename"

## open for edit
vim -c "$goto" -c startinsert "$filename"

echo  "Created: $filename"

exit 0
