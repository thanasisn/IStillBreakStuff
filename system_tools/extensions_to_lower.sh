#!/bin/bash
## created on 2020-11-02
## https://github.com/thanasisn <natsisphysicist@gmail.com>


#### Convert file extensions to lower case

FOLDER="$1"

if [[ ! -d "$FOLDER" ]]; then
    echo "Give a folder!"
    exit 0
fi

echo "Files with upper extensions"
find "${FOLDER}" -type f | egrep '\.[[:lower:]]*[[:upper:]]+[[:lower:]]*$'

echo "Does not list all files (when there is a number like .Mp3)"

echo
echo -n "Try to convert ALL extensions to lower ? "
read -n1  cont
echo

if   [[ $cont != "y" ]]; then
    echo "EXIT"
    exit
fi

## recursive rename extensions to lower
find "${FOLDER}" -type f -name '*.*' | while IFS= read -r f; do
  ## new filename
  a=$(echo "$f" | sed -r "s/([^.]*)\$/\L\1/");
  ## test and display
  # [ "$a" != "$f" ] && echo "$f" "$a"
  ## test and apply
  [ "$a" != "$f" ] && mv -nv "$f" "$a"
done


## Does not work when there is a number like .Mp3
# echo ""
# find "${FOLDER}" -type f | egrep '\.[[:lower:]]*[[:upper:]]+[[:lower:]]*$' | while read line ;do
# #     echo "$line"
#     e="${line##*.}"
#     b="${line%.*}"
#     mv -nv "$line"  "${b}.${e,,}"
# done
#
# echo ""
# echo "Remaining files"
# find "${FOLDER}" -type f | egrep '\.[[:lower:]]*[[:upper:]]+[[:lower:]]*$'
#


exit 0
