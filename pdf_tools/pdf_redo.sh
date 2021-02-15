#!/bin/bash

#### Read and write a pdf with pdftk

## the intend is to clean pdf from bad data
## this usually fixes bad pdfs

## preserves metadata
## preserves index bookmarks
## preserves annotations
## shows output sizes
## ask for overwrite


for ff in "$@"; do
    ## check input is a pdf
    if [[ ! $(file --mime-type -b "$ff") == "application/pdf" ]]; then
        continue
    fi
    echo "-------------------------------------"
    echo "PROCESS:: $ff"

    name="${ff%.*}"

    newpdf="${name}.newpdf"
    newpdf2="${name}.newpdf2"
    meta="${name}.metapdf"
    
    ## re-create the pdf file
    pdftk "$ff" cat output "$newpdf"
	## export pdf metadata
    pdftk "$ff" dump_data_utf8 > "$meta"
    
    ## loosing bibtex entries
    ## copy xmp data from old to new
    exiftool -overwrite_original -TagsFromFile "$ff" -all:all "$newpdf"

    ## restore bibtex ?
    pdftk "$newpdf" update_info_utf8 "$meta" output "$newpdf2"
    
    ## remove metadata file
    trash "$meta"
    ## remove intermediate pdf
    trash "$newpdf"

    Sori="$(du -b "$ff" | cut -d$'\t' -f1)"
    Snew="$(du -b "$newpdf2" | cut -d$'\t' -f1)"
    
    echo "-------------------------------------"
    printf "Original size: %10s \n"  "$Sori"
    printf "New file size: %10s \n"  "$Snew"
    printf "Diff         : %10s  %0.3f%% \n"  "$((Snew-Sori))"  "$(echo "scale=3; 100*($Snew-$Sori)/$Sori " | bc)"
    echo "-------------------------------------"

    echo -n "Replace old file with new (y/n)? "
    read answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then
        trash "$ff"
        mv "$newpdf2" "$ff"
        echo "Old file was trashed and replaced."
    else
        rm "$newpdf2"
    fi
   
done

exit 0
