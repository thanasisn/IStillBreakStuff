#!/bin/bash
## created on 2019-01-06

#### Convert all images in a folder to jpg with a max dimension ant add text on the corner
## Useful to post images on internet.
## exif meta data don't survive
## a new folder is created with the images


FOLDER="$1"
TEXT="${2:-puttexthere}"
DIM="${3:-1200}"
QUAL="${4:-95}"
BACK="${5:-#FFFFFF60}"
FILL="${6:-#000000}"
## text point size
POINT="${7:-22}"

## max allowed output resolution
DIMEN="${DIM}x${DIM}"


if [[ ! -d "$FOLDER" ]]; then
    echo "You have to give a folder!"
    echo "usage:"
    echo "$(basename "$0") <Folder> [text label] [max dimension ($DIM)] [quality ($QUAL)] [background color ($BACK)] [foreground color ($FILL)] [text pointsize ($POINT)]"
    exit 0
fi

OFOLDER="${FOLDER}_tagged"


# TEXT=\'$TEXT\'

echo "Folder : $FOLDER"
echo "Output : $OFOLDER"
echo "Tag    : $TEXT"
echo "Dim lim: $DIMEN"
echo "Quality: $QUAL"
echo "Backgrn: $BACK"
echo "Fill   : $FILL"
echo "Pointsi: $POINT"


echo
echo -n "Continue ? "
read -n1  cont
echo

if   [[ $cont != "y" ]]; then
    echo "EXIT"
    exit
fi


## create output folder
mkdir -p "$OFOLDER"

find "${FOLDER}" -type f | while read line ;do

    in_name="$line"
    out_name="$(echo "$line" | sed -e "s@${FOLDER}@${OFOLDER}@g"  )"

    out_name="${out_name%.*}.jpg"

    echo "$in_name"
    echo "$out_name"

    convert  \( "${in_name}" -strip  -resize "$DIMEN" -quality "$QUAL" -auto-orient \) \
        -background $BACK   \
        -pointsize  $POINT  \
        -fill       $FILL   \
        label:"$TEXT"       \
        -gravity southeast  \
        -geometry +10+10    \
        -composite          \
        "${out_name}"

#                 -limit memory 100mb -limit disk 1gb \
#                 -font "LinLibertine_R"   \

done


exit 0
