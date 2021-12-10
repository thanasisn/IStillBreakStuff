#!/bin/bash
## created on 2021-12-08

#### Get all metatags from files, count and process
## Use exiftool to get and process tags

FOLDER="$1"
: ${FOLDER:="./"}

if [ ! -d "$FOLDER" ];then
    echo "Give a folder"
    exit 1
fi


tmpfile="$FOLDER/.tag.dump"
emptfile="$FOLDER/.tag.empty"


echo "get all tag data"
exiftool -a -s -G -r "$FOLDER" > "$tmpfile"



echo
echo " --- COUNT UNIQUE TAGS ---"
grep "^\[" "$tmpfile"  |\
    grep -v "\[File\]" |\
    cut -d':' -f1      |\
    sort               |\
    uniq -c            |\
    sort -k2



echo ""
echo " --- COUNT UNIQUE VALUES ---"
grep "^\[" "$tmpfile"  |\
    grep -v "\[File\]" |\
    sort               |\
    uniq -c            |\
    sort -k2



echo ""
echo " --- GET EMPTY TAGS ---"
emptytag="$(
cat "$tmpfile"         |\
    grep -v "\[File\]" |\
    grep "^\["         |\
    while read line;do
        tag="$(echo "$line" | cut -d":" -f1)"
        value="$(echo "$line" | cut -d":" -f2-)"
        [[ ! -z "$value" ]] || echo "$tag"
    done    |\
    sort    |\
    uniq -c |\
    sort -n
)"
echo "$emptytag"
echo "$emptytag" > "$emptfile"

## suggest some commands to use
echo ""
echo " --- PROCESS EMPTY TAGS ---"
echo "$emptytag" | while read line;do
    tagg="$(echo "$line" | cut -d"]" -f2 | sed 's/^[ ]*//')"
    echo "exiftool -a -s -G -r -if '\$$tagg eq \"\"' -\"*$tagg*\" \"$FOLDER\""
    echo "exiftool -a -s -G -r -if '\$$tagg eq \"\"' -\"*$tagg*\" \"$FOLDER\"" >> "$emptfile"
done

echo
echo " --- CLEAN ORIGINALS ---"
echo "find \"$FOLDER\" -name \"*_original\" "
echo ""
echo "$tmpfile" "$emptfile"

exit 0
