#!/bin/bash 
## created on 2017-10-05

#### Rename pdfs using xmp metadata

## Main goal is to format academic pdf with a consistent manner
## we assume files include bibtexkey in xmp meta data
## Some formatted is done on filename
##
##    Preparation
## 1. use jabref to write keys on pdf
## 2. rename with script
## 3. import mendeley
## 4. export new bib file for jabref


## total file length limit
LIMIT=139

## for file names we use byte count instead of character count
## in order to be good for Greek filenames
## the imposed limit is for encfs files when synced with rsync or unison


## parse all files and folder given into an array
declare -a files
# for arg in "$@" ;do
#     [[ -f "$arg" ]] &&  echo "$arg" | grep ".pdf"
#     [[ -d "$arg" ]] &&  find "$arg" -iname "*.pdf"
# done


for arg in "$@" ;do
    ## gather files
    if [[ -f "$arg" ]]; then
        files[${#files[@]}+1]=$(echo "$arg")
    fi
    ## gather files in folders
    if [[ -d "$arg" ]]; then 
        while read fline; do
            echo "Add $fline"
            files[${#files[@]}+1]=$(echo "$fline")
        done < <(find "$arg" -iname "*.pdf")
    fi
done

for line in  "${files[@]}"; do
   
    echo ""
    TITLE=""; BBKEY=""

    ## get the info we want
    TITLE=$(exiftool -s -s -s -XMP:title     "$line")
    BBKEY=$(exiftool -s -s -s -XMP:bibtexkey "$line")

    ## protect from empty data
    if [[ -z "$TITLE" ]]; then
        echo "Emtpy title for $line"
        echo " ... skip ... "
        continue
    fi
    if [[ -z "$BBKEY" ]]; then
        echo "Emtpy bibkey for $line"
        echo " ... skip ... "
        continue
    fi

    ## get only file name
    fileN="$(basename "$line")"
    folder="$(dirname "$line")"
    
    ##FIXME change counting method
    ## this is not good for greek utf8

    ## replace some characters with spaces
    ## replace multiple spaces with single space
    ## remove first and last spaces
    ## sed 's/[–{}:,-\n]/ /g' |
    nn=$(echo "$TITLE" | sed "s/[[:punct:]]\+/ /g" | sed 's/ \+/ /g' | sed 's/^ //g' | sed 's/ $//g' )

    ## suffic for all
    last="_$BBKEY.pdf"
    
    ## count lengths
    last_byte="$(echo "$last" | wc -c )"
    last_char="$(echo "$last" | wc -m )"
    nn_byte="$(echo $nn | wc -c )"
    nn_char="$(echo $nn | wc -m )"
    
    ## preffix with limited length
    first=$(echo "${nn:0:$(($LIMIT-${#last}))}" | sed 's/ $//g')

    ## new filename
    fileNNN="${first}${last}"

    bytes=$(echo -n "$fileNNN" | wc -c)

    if [[ "$fileN" == "$fileNNN" ]]; then
        echo "NO NEW NAME:  ${fileN}"
        continue
    fi
    
    ## info
    echo "Key:  Bytes: $last_byte   Chars: $last_char"
    echo "Name: Bytes: $nn_byte   Chars: $nn_char"

    echo ""
    echo "TTL: $TITLE"
    echo "OLD: $fileN ${#fileN}"
    echo "NEW: ${fileNNN} $bytes ${#fileNNN}"

    ## ask to execute
    REPLY="N"
    echo ""
    read -p "Rename  (y/n)?: " -n1
    echo ""

    ## check for overwrite -i
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv -i -b                        \
           "${folder}/${fileN}"         \
           "${folder}/${first}${last}"

    fi
done

exit 0
