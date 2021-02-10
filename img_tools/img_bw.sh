#!/bin/bash
## created on 2020-02-08

#### Convert all images in a folder to black and white

FOLDER="$1"
: ${FOLDER:="./"}

if [[ ! -d "$FOLDER" ]]; then
    echo "You have to give a folder!"
    exit 0
fi

mogrify -colorspace Gray "$FOLDER/*"


exit 0 
