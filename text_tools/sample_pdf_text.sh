#!/usr/bin/env bash
## created on 2024-11-17

#### Get the text of a pdf for typographical statistics

FILE="$1"
OUT="$FILE.textsample"
SHORT_LIMIT="${2:-40}" ## lines with less characters will be removed
LONG_LIMIT="${3:-200}" ## lines with more characters will be removed

## dump text to file
pdftotext   \
  -nodiag   \
  -layout   \
  -nopgbrk  \
  "$FILE"   \
  "$OUT"

## remove multiple spaces and empty lines
sed -i -e 's/[ ]\+/ /g' -e 's/^ //g' -e '/^$/d' "$OUT"

## remove too short and too long lines
gawk -i inplace -v linemin="$SHORT_LIMIT" 'length($0)>linemin' "$OUT"
gawk -i inplace -v linemax="$LONG_LIMIT"  'length($0)<linemax' "$OUT"

## remove lines ending with numbers
sed -i '/[0-9]$/d' "$OUT"

## show execution info
echo
echo "Excluding lines with less than >>  $SHORT_LIMIT  << characters"
echo "Excluding lines with more than >>  $LONG_LIMIT  << characters"

## run statistics
"$HOME/CODE/text_tools/count_text.sh" "$OUT"

exit 0
