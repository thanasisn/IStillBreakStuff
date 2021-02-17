#!/bin/bash
## created on 2019-10-27

#### Count word frequency
## works for multiple languages

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
    sort 
)"

## Count word frequency
echo "----------------------------"
echo "$words" | uniq -c | sort -nr | nl
echo "----------------------------"

## Total words
echo "Total words:  $(echo "$words" | wc -l)"


exit 0
