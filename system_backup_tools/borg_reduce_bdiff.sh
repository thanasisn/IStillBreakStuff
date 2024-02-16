#!/bin/bash
## created on 2024-02-04

#### Clean bdiff files for easier inspection


file="$1"


if [ "${file: -6}" == ".bdiff" ]; then
    echo "Got a bdiff file "
else
    echo "Not a .bdiff file"
    exit 9
fi

echo "Lines Initial         :  $(wc -l "$file" | cut -d' ' -f1)"

## Remove .git repo entries
sed -i '/\/.git\//d'      "$file"
sed -i '/\/.dotfiles\//d' "$file"
echo "Without git enties    :  $(wc -l "$file" | cut -d' ' -f1)"

## Remove ctime only changes
sed -i '/^\[ctime/d' "$file"
echo "Without ctimes changes:  $(wc -l "$file" | cut -d' ' -f1)"

## Remove ctime edits changes
sed -i '/\[ctime/d' "$file"
echo "Without ctimes edits  :  $(wc -l "$file" | cut -d' ' -f1)"


## Remove PROGRAMS changes
sed -i '/\/PROGRAMS\//d' "$file"
echo "Without PROGRAMS edits:  $(wc -l "$file" | cut -d' ' -f1)"


## end coding
exit 0 
