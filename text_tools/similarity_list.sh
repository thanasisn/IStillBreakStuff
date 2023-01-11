#!/bin/bash
## created on 2021-11-25

#### Print similarity distance of a piped list
## Use grep prefix to ignore folders or any other id before each line
## neads fstrcmp command, there is an alternative slower bash function

# Check to see if a pipe exists on stdin.
if [ -p /dev/stdin ]; then
    # echo "Data was piped to this script!"
    data="$(cat)"
else
    echo "No input was found on stdin, skipping!"
    # Checking to ensure a filename was specified and that it exists
    if [ -f "$1" ]; then
        echo "Filename specified: ${1}"
        echo "Doing things now.."
    else
        echo "No input given!"
    fi
fi


prefix=""
short="4"
useprefix=false
ignoreshort=false

Help () {
    echo
    echo " Print similarity distance between all elements in a list."
    echo " Reads from stdin. Use to find similar names, or lines of text in a file with appropriate pre formatting."
    echo " It is slow, so better redirect output to a file."
    echo
    echo "   -p <pattern>    grep pattern to get prefix"
    echo "   -i <#>          skip arguments sorter than # (default: $short)"
    echo "   -h  print this help text"
    echo
    echo " Usage:"
    echo "    ls | $(basename $0) "
    echo "    find -maxdepth 2 -iname "*.sh" -type f | $(basename $0) -p \".*/\" > similarfilenames.txt "
    echo "    sort similarfilenames.txt"
    echo ""
}

while getopts "hp::i::" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      p) # prefix pattern to ignore
         useprefix=true
         prefix=$OPTARG;;
      i) # ingore sort terms
         ignoreshort=true
         short=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

# [ "$useprefix" = true ]   && echo "Prefix to ignore:    $prefix "
# [ "$ignoreshort" = true ] && echo "Ignore shorter than: $short "

## alternative to fstrcmp
function levenshtein {
    if [ "$#" -ne "2" ]; then
        echo "Usage: $0 word1 word2" >&2
    elif [ "${#1}" -lt "${#2}" ]; then
        levenshtein "$2" "$1"
    else
        local str1len=$((${#1}))
        local str2len=$((${#2}))
        local d i j
        for i in $(seq 0 $(((str1len+1)*(str2len+1)))); do
            d[i]=0
        done
        for i in $(seq 0 $((str1len))); do
            d[$((i+0*str1len))]=$i
        done
        for j in $(seq 0 $((str2len))); do
            d[$((0+j*(str1len+1)))]=$j
        done
        for j in $(seq 1 $((str2len))); do
            for i in $(seq 1 $((str1len))); do
                [ "${1:i-1:1}" = "${2:j-1:1}" ] && local cost=0 || local cost=1
                local del=$((d[(i-1)+str1len*j]+1))
                local ins=$((d[i+str1len*(j-1)]+1))
                local alt=$((d[(i-1)+str1len*(j-1)]+cost))
                d[i+str1len*j]=$(echo -e "$del\n$ins\n$alt" | sort -n | head -1)
            done
        done
        echo ${d[str1len+str1len*(str2len)]}
    fi
}

## remove empty lines and colors from stdin
data="$(echo "$data" | sed '/^$/d' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" )"
## process terms longer than 1 character
data="$(echo "$data" | awk ' length($0) > 1  { print $0 } ')"

## create a table to process all terms
if [ "$useprefix" = true ]; then
    terms="$( echo "$data" | sed -n 's,'"$prefix"',,p')"
else
    terms="$data"
fi

counts="$( echo "$terms" | awk '{ print length($0) "\t" $0 }')"
table="$( paste <(echo "$counts") <(echo "$data") )"

# echo "terms"
# echo "$terms"   | head
# echo "table"
# echo "$table"  | head
# echo "counts"
# echo "$counts" | head
# echo "data"
# echo "$data"   | head
# echo "$terms"  | wc -l
# echo "$table"  | wc -l
# echo "$counts" | wc -l
# echo "$data"   | wc -l
# [[ $(echo "$count" | wc -l ) -ne $(echo "$data" | wc -l ) ]] && echo "missmatch 1" && exit


## remove too short arguments
if [ "$useprefix" = true ]; then
    table="$( echo "$table" | awk -v num=$short -F'\t' ' $1 > num { print $2 "\t" $3 } ' )"
else
    table="$( echo "$table" | awk -v num=$short -F'\t' ' $1 > num { print $2 } ' )"
fi

## count lines to iterate
tl="$(echo "$table" | wc -l )"

echo "Total terms: $tl"
[[ $tl -le 2 ]] && echo "Too few lines" && exit

## iterate between all elements in the list
for (( i=1; i<=$tl; i++ )); do
    for (( j=((i+1)); j<=$tl; j++ )); do

        ## prepare arguments
        one="$( echo "$table" | sed "${i}q;d" | cut -f1 )"
        two="$( echo "$table" | sed "${j}q;d" | cut -f1 )"
        oone="$(echo "$table" | sed "${i}q;d" | cut -f2 )"
        otwo="$(echo "$table" | sed "${j}q;d" | cut -f2 )"

        # echo "$one" "$oone" "$two" "$otwo"

        ## get distances
        if [ "$useprefix" = true ]; then
            printf "F:%6s \"%s\" \"%s\"  ::  \"%s\" \"%s\"\n" "$(fstrcmp -p  "$one" "$two")" "$one" "$two" "$oone" "$otwo"
            # printf "L:: %-6s %s %s  ::  %s %s\n" "$(levenshtein "$one" "$two")" "$one" "$two" "$oone" "$otwo"
        else
            printf "F:%6s \"%s\" \"%s\"\n" "$(fstrcmp -p  "$one" "$two")" "$one" "$two"
            # printf "L:: %-6s \"%s\" \"%s\"\n" "$(levenshtein "$one" "$two")" "$one" "$two"
        fi
    done
done

exit
