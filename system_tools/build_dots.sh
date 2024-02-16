#!/usr/bin/env bash
## created on 2024-01-11

#### Builds pdf and png for *.dot files in the folder
## Use to update all dot graphs in a folder structure

folder="$1"

## check input
if [ -d "$folder" ]; then
    echo "Rucurse in: $folder" 
    echo
else
    echo "Not a folder: $folder"
    exit
fi

## run for all dot files
find "$folder" -iname "*.dot" 2> /dev/null | while read line; do
    dotfile="$line"
    pdffile="${line%.[Dd][Oo][Tt]}.pdf"
    pngfile="${line%.[Dd][Oo][Tt]}.png"
    echo "$dotfile" 

    if [ "$dotfile" -nt "$pdffile" ]; then
        echo "Create PDF: $pdffile"
        dot -Tpdf "$dotfile" -o "$pdffile"
    fi

    if [ "$dotfile" -nt "$pngfile" ]; then
        echo "Create PNG: $pngfile"
        dot -Tpng "$dotfile" -o "$pngfile"
    fi
done

exit 0 
