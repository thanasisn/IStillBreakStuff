#!/bin/bash
## created on 2019-03-10

#### Export bookmarks from a pdf for edit

## This is a method to edit multiple pdf bookmarks with a text editor
## Useful to fix bookmarks and indexes of pdf files without having the source

FILE="$1"

## check input
[[ ! -f "$FILE" ]] && echo "Not file input" && echo "exit" && exit 1
if [[ ! "$(file --mime-type -b "$FILE")" == application/pdf ]]; then
    echo "Not a pdf !!"
    exit
fi

## this converts to human readable syntax
decodepdf="pdf_decode_bm.sh"

NAME="${FILE%.*}"
INFO="${NAME}.pdf.info"
BMAR="${NAME}.pdf.bm"
NEWF="${NAME}.new.pdf"

echo "$FILE"
echo "$INFO"
echo "$NEWF"
echo

## export info from file
pdftk "$FILE" dump_data_utf8 > "$INFO"

## export bookmarks from info to human
$decodepdf "$INFO" > "$BMAR"

echo " ## Bookmarks ## "
echo
cat "$BMAR"

echo
echo "Update bookmarks in >> ${BMAR} <<"
echo "and run pdf_set_bookmarks.sh"

exit 0
