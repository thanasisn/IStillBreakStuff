#!/bin/bash

#### Remove annotations from a pdf file

FILE="$1"
WDIR="$(dirname "$FILE")"

echo "REMOVE ANNOTATIONS:  $FILE"

uncpdf="$WDIR/unc.pdf"
strpdf="$WDIR/str.pdf"

## unpack pdf
pdftk "$FILE"   output "$uncpdf" uncompress
## remove annotations from file
LANG=C sed -n '/^\/Annots/!p' "$uncpdf" > "$strpdf"
## repack pdf
pdftk "$strpdf" output "$FILE" compress
## remove temp files
rm "$strpdf" "$uncpdf"

exit 0
