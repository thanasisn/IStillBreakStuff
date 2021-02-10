#!/bin/bash

#### Remove or trash images based on given x, y or x*y

folder="$1"
: ${folder:="./"}

if [ ! -d "$folder" ];then
    echo "Give a folder"
    exit 1
fi

echo ""
read -p "Are you confident? " conf

if   [[ $conf == "yes" ]]; then
    echo "rm is for the masters of zen"
    redc="rm "
elif [[ $conf == "no" ]]; then
    echo "trash metal is for you"
    redc="trash-put "
else
    echo "You don't know how not speak!"
    exit 99
fi
echo ""

## get parameters to use for filtering
xlim=""
while [[ $xlim -lt  1  ]]; do
    read -p "Give   X   minimum in pixels: " xlim
done

ylim=""
while [[ $ylim -lt  1  ]]; do
    read -p "Give   Y   minimum in pixels: " ylim
done

lli=$((ylim*xlim))

xylim=""
while [[ $xylim -lt  1  ]]; do
    read -p "Give  X*Y  minimum in pixels (${lli}<): " xylim
done

echo
echo " X  lim: $xlim"
echo " Y  lim: $ylim"
echo "X*Y lim: $xylim"
echo

read -p "Continue with $redc ? " cont
if  [[ $cont == "y" ]]; then
    echo "Will remove images"
    echo
else
    exit 1
fi

## list image files to check
find "$folder" -type f -print | file -if - | grep "image" | awk -F: '{print $1}' |\
    while read fline; do
        res="$(identify -ping -format "%[width] %[height]" "$fline")"

        imXX="$(echo "$res" | cut -d' ' -f1)"
        imYY="$(echo "$res" | cut -d' ' -f2)"
        imXY="$((imXX*imYY))"

#         echo " $imXX $imYY $imXY  $fline"

        ## test three criteria for images and remove
        if   [[ $imXX -lt $xlim ]]; then
            $redc "$fline" && echo "removed: $imXX $imYY $imXY  $fline"
        elif [[ $imYY -lt $ylim ]]; then
            $redc "$fline" && echo "removed: $imXX $imYY $imXY  $fline"
        elif [[ $imYY -lt $ylim ]]; then
            $redc "$fline" && echo "removed: $imXX $imYY $imXY  $fline"
        fi
    done

echo "DONE"

exit 0
