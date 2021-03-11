#!/bin/bash
## created on 2020-11-13

#### Convert mp3 play list from master library to image library

infolder="$HOME/Documents/Playlist"
outfolder="${infolder}_blue"

## image root dir
iroot="/media/barel/Music_img"
## library root dir
mroot="/home/folder/Music"

mkdir -p "$outfolder"

find "$infolder" -type f -iname "*.m3u" | while read line; do
    echo "$line"
    
    outfile="$outfolder/$(basename $line)"
    
    cat "$line" |\
        sed "s@$mroot@${iroot}@g"  |\
        sed 's@\.flac@\.mp3@'              > "$outfile"

done    



exit 0 
