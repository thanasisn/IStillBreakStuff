#!/bin/bash

#### Display images in a folder recursively

FOLDER="$1"
shift
OPTIONS="$@"


if [[ ! -d "$FOLDER" ]];then
    echo "Give a folder to process"
    exit
fi


feh --fullscreen                                                               \
    --font     "DejaVuSans/9"                                                  \
    --fontpath "/usr/share/fonts/truetype/dejavu"                              \
    --recursive                                                                \
    --auto-rotate                                                              \
    --sort filename                                                            \
    --version-sort                                                             \
    --verbose                                                                  \
    --info     'echo %S %wx%h %P $(ls $(dirname %F) | wc -l ) $(dirname %F) '  \
    --draw-filename                                                            \
    --action "trash-put %F"                                                    \
    --action8 'trash-put $(dirname %F) '                                       \
    $OPTIONS                                                                   \
    "$FOLDER"

echo "$OPTIONS"

cfiles="$(find $FOLDER -type f | wc -l )"
cdirs="$(find $FOLDER -type d | wc -l )"

echo "Files   : $cfiles"
echo "Folders : $cdirs"

exit 0

# --reverse
# --sort name
# --sort filename
# --sort dirname
# --sort width
# --sort height
# --sort pixels
# --sort size
# --sort format
