#!/bin/bash

#### Display images in a folder recursively sorted by resolution

FOLDER="$1"
: ${FOLDER:="./"}
OPTIONS=" --sort pixels "

if [[ ! -d "$FOLDER" ]];then
    echo "Give a folder to process"
    exit
fi

## create a sorted filelist for faster loading 
cachelist="$FOLDER/.pixels.feh_list"
cachelistrev="$FOLDER/.pixels_rev.feh_list"

echo "Sort by pixels"
echo "$cachelist"

if [[ -f "$cachelist" ]]; then
    echo "Exist         : $cachelist"

    lastmod="$(find "$FOLDER" ! -name ".fingerprinds.db" ! -name ".dupimg.list" -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")"

    echo "Last modified : $lastmod"

    if [[ "$lastmod" -ef "$cachelist" ]]; then
        echo "List is the last NO NEED TO BUILD"
    else
        echo "SHOULD rebuild list !"
    fi

    read -p "Delete old list and create new? " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "delete list"
        trash "$cachelist"
        ## load list and sort
        OPTIONS="$(echo "${OPTIONS} --recursive --filelist "${cachelist}" ")"
    else
        ## load from list no sort
        OPTIONS=" --filelist ${cachelist} "
    fi
else
    echo "Don't exist $cachelist"
    OPTIONS="$(echo "${OPTIONS} --recursive --filelist "${cachelist}" ")"
fi

echo "$OPTIONS"

feh --fullscreen                                   \
    --draw-actions                                 \
    --font     "DejaVuSans/9"                      \
    --fontpath "/usr/share/fonts/truetype/dejavu"  \
    --verbose                                      \
    --info     "echo %S %wx%h %P"                  \
    --draw-filename                                \
    --action  "trash-put %F"                       \
    --action8 'trash-put $(dirname %F) '           \
    $OPTIONS                                       \
    "$FOLDER"

echo "$OPTIONS"

cfiles="$(find "$FOLDER" -type f | wc -l )"
cdirs="$(find "$FOLDER" -type d | wc -l )"

echo "Files   : $cfiles"
echo "Folders : $cdirs"

# echo "invert $cachelist"
# tac      "$cachelist" > "$cachelistrev"

##FIXME the reverse option will reverse the  list each time it uses it!!
## so the first time the normal copy will be good but the next time will reverse it

cp -v "$cachelist" "$cachelistrev"
touch -r "$cachelist"   "$cachelistrev"

exit 0

# feh --filelist by_width -S width --reverse --list .
#    Write a list of all images in the directory to by_width, sorted by width (widest images first)


# -f, --filelist file
# This option is similar to the playlists used by music software. If file exists, it will be read for a list of files to load, in the order they appear. The format is a list of image filenames, absolute or relative to the current directory, one filename per line.
#
# If file doesn't exist, it will be created from the internal filelist at the end of a viewing session. This is best used to store the results of complex sorts (-Spixels for example) for later viewing.
#
# Any changes to the internal filelist (such as deleting a file or it being pruned for being unloadable) will be saved to file when feh exits. You can add files to filelists by specifying them on the command line when also specifying the list.


# --reverse
# --sort name
# --sort filename
# --sort dirname
# --sort width
# --sort height
# --sort pixels
# --sort size
# --sort format
