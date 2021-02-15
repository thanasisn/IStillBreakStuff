#!/bin/bash
## created on 2019-03-10

#### Write bookmarks to a pdf after using pdf_get_bookmarks.sh 

## This is a method to edit multiple bookmarks with a text editor

FILE="$1"

[[ ! -f "$FILE" ]] && echo "Not file input" && echo "exit" && exit 1
if [[ ! "$(file --mime-type -b "$FILE")" == application/pdf ]]; then
    echo "Not a pdf !!"
    exit
fi

NAME="${FILE%.*}"
INFO="${NAME}.pdf.info"
BMAR="${NAME}.pdf.bm"
NEWF="${NAME}.new.pdf"

if [[ ! -f "$INFO" ]]; then
    echo "Missing "$INFO""
    exit 1
fi

if [[ ! -f "$BMAR" ]]; then
    echo "Missing "$BMAR""
    exit 1
fi

encodepdf="pdf_encode_bm.sh"

echo "$FILE"
echo "$INFO"
echo "$NEWF"
echo


## remove all bookmarks from info file
sed -i '/^Bookmark/d' "$INFO"

## encode pdf and append to info
$encodepdf "$BMAR" >> "$INFO"

## update info in pdf
pdftk "$FILE" update_info_utf8 "$INFO" output "$NEWF"

## replace with new file
mv -i "$NEWF" "$FILE"

## clean extra files
trash "$INFO"
trash "$BMAR"


exit 0
