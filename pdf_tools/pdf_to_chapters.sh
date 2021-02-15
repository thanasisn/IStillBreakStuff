#!/bin/bash
## created on 2015-07-17

#### Split a pdf into chapters

## In some cases the chapters name will be wrong

infile="$1"             ## input pdf
prefix="${infile%.*}"   ## output prefix

[[ ! -f "$infile" ]] && echo "Not a file" && exit 2

metadata="$(pdftk "$infile" dump_data_utf8)"

numberofpages=$(echo "$metadata" | grep -i "^numberofpages" | cut -f2 -d' ')

outlist="$(
paste <(echo "$metadata" | grep "^BookmarkLevel" | sed 's/BookmarkLevel: //') \
      <(echo "$metadata" | grep "^BookmarkPageNumber" | sed 's/BookmarkPageNumber: //') \
      <(echo "$metadata" | grep "^BookmarkTitle" | sed 's/BookmarkTitle: //')
      )"

levels="$(echo "$metadata" | grep "^BookmarkLevel" | sed 's/BookmarkLevel: //' | sort -u | tr '\n' ' ' )"



## Show document outline

# printf "Level\tPage\tTitle\n"
# echo "$outlist"

echo "$outlist" | while read line; do
    level="$(echo "$line" | cut -f1)"
    page="$(echo "$line" | cut -f2)"
    title="$(echo "$line" | cut -f3-)"
    lsp="$(printf '%*s' $((4 * level - 4)) | tr ' ' '-')"

    printf "l:%2s   p:%4s   %s %s\n" "$level" "$page" "$lsp"  "$title"
done



## Choose levels to split

echo
echo "Pages: $numberofpages"
read -p "Choose level to split [ $levels]: "  uservar

splitlist="$(echo "$outlist" | grep "^${uservar}")"

echo 
echo "Check splits"
echo
echo "$splitlist"
# echo "$splitlist" > splitlist

echo
read -p "Continue with the split? " uservar
[[ $uservar =~ ^[Yy]$ ]] || exit 0



## Do the split

breaks=( $(echo "$splitlist" | cut -f2) )

## add first page if needed
[[ "${breaks[1]}" -ne "1" ]] && breaks=( 1 "${breaks[@]}" )
## add end
breaks=( "${breaks[@]}" "end" )

# echo ${breaks[@]}

for ((i=0; i < ${#breaks[@]} - 1; ++i)); do
    a=${breaks[i]}   # start page
    b=${breaks[i+1]} # end page
    [ "$b" = "end" ] || b=$[b-1]
    [ "$b" = 0     ] && continue
    ##FIXME do a better selection of the name have to use an array of titles
    title="$(echo "$splitlist" | grep -P "\t${a}\t" | head -n1 | cut -f3- | tr '\n' ' ')"
    title="$(echo "$title" | xargs echo -n)"
    filename="$(printf "%s_%04d-%s_%s.pdf"  "$prefix" "$a" "$b" "$title")"
    # echo $filename 
    pdftk "$infile" cat ${a}-${b} output "$filename"
    echo "Created: $filename"
done

echo "Finished"

exit 0
