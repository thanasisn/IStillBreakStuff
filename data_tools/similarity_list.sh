#!/bin/bash
## created on 2021-11-25

#### Print similarity distance of a piped list
## Use grep prefix to ignore folders or any other id before each line
## neads fstrcmp command

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

Help () {
    echo
    echo " Print similarity distance between all elements in a list."
    echo " Reads from stdin. Use to find similar names, or lines of text in a file with appropriate pre formatting."
    echo " It is slow, so better redirect output to a file."
    echo
    echo "   -p <pattern>    grep pattern to get prefix"
    echo "   -i <#>          skip arguments sorter than #"
    echo "   -h  print this help text"
    echo
    echo " Usage:"
    echo "    ls | $(basename $0) "
    echo "    find -maxdepth 2 -iname "*.sh" -type f | $(basename $0) -p \".*/\" > similarfilenames.txt "
    echo "    sort similarfilenames.txt"
    echo ""
}

prefix=""
useprefix=false
ignoreshort=false

while getopts "hp::i::" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      p) # prefix pattern
         useprefix=true
         prefix=$OPTARG;;
      i) # ingore sort arguments
         ignoreshort=true
         short=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

echo "Prefix to ignore:    $prefix "
echo "Ignore shorter than: $short "

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

## remove empty lines and colors
data="$(echo "$data" | sed '/^$/d' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" )"

# ## remove shorter lines
# if $ignoreshort; then
#     echo "$data" | sed '/^.\{,'"$short"'\}$/d'
# fi

## count lines to iterate
tl="$(echo "$data" | wc -l )"

echo "Total lines: $tl"
[[ $tl -le 2 ]] && echo "Too few lines" && exit

## iterate between all elements in the list
for (( i=1; i<=$tl; i++ )); do
    for (( j=((i+1)); j<=$tl; j++ )); do

        ## prepare arguments
        one="$(echo "$data" | sed "${i}q;d")"
        two="$(echo "$data" | sed "${j}q;d")"

        if $useprefix; then
            preone="$(echo "$one" | grep -o "$prefix")"
            oone="$one"
            one="$(echo "$one" | sed 's,'"$preone"',,')"

            pretwo="$(echo "$two" | grep -o "$prefix")"
            otwo="$two"
            two="$(echo "$two" | sed 's,'"$pretwo"',,')"
        fi
        # echo "$one" "$oone" "$two" "$otwo"

        ## skip short terms
        if $ignoreshort; then
            if [ ${#one} -lt $short ] || [ ${#two} -lt $short ] ; then
                continue
            fi
        fi

        ## get distances
        printf "F:%6s \"%s\" \"%s\"  ::  \"%s\" \"%s\"\n" "$(fstrcmp -p  "$one" "$two")" "$one" "$two" "$oone" "$otwo"
        # printf "L:: %-6s %s %s  ::  %s %s\n" "$(levenshtein "$one" "$two")" "$one" "$two" "$oone" "$otwo"

    done
done

exit
