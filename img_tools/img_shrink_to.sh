#!/bin/bash
## created on 2019-01-06

#### Mass shrink images to a maximum specified dimension
## Image metadata are not preserved


DIM="${1}"
FOLDER="$2"
QUAL="100"

usage(){
	echo ""
	echo "Usage:   $0 <one dimension limit> <folder>"
	echo "example: $0   1200   ./photos_dir"
	echo ""
}

if [[ ! -d "$FOLDER" ]]; then
    echo "You have to give a folder!"
    usage
    exit 0
fi
if [[ ! "$DIM" -gt 1 ]]; then
    echo "Dimension limit must be greater than 1"
    usage
    exit 0
fi

OFOLDER="${FOLDER}_tagged"
DIMEN="${DIM}x${DIM}"

echo "Folder : $FOLDER"
echo "Output : $OFOLDER"
echo "Dim lim: $DIMEN"
echo "Quality: $QUAL"

echo
echo -n "Continue ? "
read -n1  cont
echo

if   [[ $cont != "y" ]]; then
    echo "EXIT"
    exit

fi

mkdir -p "$OFOLDER"

find "${FOLDER}" -type f | while read line ;do
    
    in_name="$line"
    out_name="$(echo "$line" | sed -e "s@${FOLDER}@${OFOLDER}@g"  )"
    
    out_name="${out_name%.*}.jpg"

    echo "IN:  $in_name"
    echo "OUT: $out_name"
    echo

    convert  \( "${in_name}"      \
                -strip            \
		        -resize "$DIMEN"  \
		        -quality "$QUAL"  \
		        -auto-orient \)   \
        "${out_name}"

done

exit 0 
