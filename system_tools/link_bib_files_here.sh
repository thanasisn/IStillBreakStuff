#!/bin/bash
## created on 2022-10-15

#### Create links here to files included in a bib file

## The source files can be anywhere in the given folder.
## It is not very well tested for all the variations of bib syntax

infile="$1"
indire="$2"

echo "-----------------------------------------"
echo "Input file: $infile"
echo "Base folder: $indire"
echo "-----------------------------------------" 

## check input
[ ! -f "$infile" ]         && echo "Not a file $infile" && exit
[[ ! "$infile" == *.bib ]] && echo "Not a .bib file $infile" && exit
[ ! -d "$indire" ]         && echo "Not a directory $indire" && exit


## get file name from bib
grep "file[ ]\+=[ ]\+{" "$infile" | cut -d":" -f2- | sed 's/:.*//' | while read line;do
    ## find the actual file
    source="$(find "$indire" -name "$line")"

    echo "* * * * * *"
    echo "$source"
    echo "$line"
    ## link actual file to current folder
    ln -i -s "$source" "./${line}"  
done


exit 0 
