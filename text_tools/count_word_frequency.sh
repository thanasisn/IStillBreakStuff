#!/bin/bash
## created on 2019-10-27
## https://github.com/thanasisn <lapauththanasis@gmail.com>

#### Count word frequency in a file
## Language agnostic
## Shows:  Word Index; Ocurances; Relative Ocurances; Word

# 1. Substitute all non alphanumeric characters with a blank space.
# 2. All line breaks are converted to spaces also.
# 3. Reduces all multiple blank spaces to one blank space
# 4. All spaces are now converted to line breaks. Each word in a line.
# 5. Convert all words to lower case
# 6. Sorts words
# 7. Counts and remove the equal lines
# 8. Sorts reverse in order to count the most frequent words
# 9. Add a line number to each word in order to know the word position


AFILE="$1"

if [ ! -f "$AFILE" ]; then
    echo "Give a file"
    exit 1
fi

## Get all words
words="$(
sed -e 's/[^[:alpha:]]/ /g' "$AFILE" |\
    tr '\n' " "                      |\
    tr '\r' " "                      |\
    tr -s " "                        |\
    tr " " '\n'                      |\
    awk '{print tolower($0)}'        |\
    sed '/^$/d'                      |\
    sort
)"


totalw="$(echo "$words" | wc -l)"

## Count word frequency
echo "----------------------------"
echo "$words" | uniq -c | sort -n | awk -v total=$totalw '{printf "%6s %7.3f%%  %s\n",  $1, 100 * $1/total, $2;}' | nl
echo "----------------------------"

## Total words
echo "Total words:  $totalw"


exit 0
