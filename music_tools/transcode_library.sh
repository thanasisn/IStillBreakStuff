#!/bin/bash
## created on 2013-09-14

#### Transcode music library image from FLAC to mp3
## This is not perfect
## The intentions is to make music available to other machines and mp3 devices


IN="/home/folder/Music/"
if [ ! -d "$IN" ]; then
    echo "$IN is not a directory"
    exit 1
fi

OUT="/media/barel/Music_img"
if [ ! -d "$OUT" ]; then
    mkdir "$OUT"
fi

# set +e

## transcode quality target
QQ=1

## mp3 threshold
BIT=240


## to transcode
echo
echo "Transcode candidates flac and wma:"
(
    find "$IN" -iname "*.flac"
    find "$IN" -iname "*.wma"
) | wc -l

echo "Copy candidates mp3:"
(
    find "$IN" -iname "*.mp3"
) | wc -l



## do transcode
(
find "$IN" -iname "*.flac"
find "$IN" -iname "*.wma"
) | while read mfile; do

    OF="$(echo "$mfile" | sed 's@.flac$@.mp3@g' | sed 's@.wma$@.mp3@g' | sed 's,'"$IN","$OUT\/"',g' )"
    dir="$(dirname "$OF")"

    mkdir -p "$dir"

    ## skip existing
    if [ ! -e "$OF" ]; then
        echo
        echo ":: $(basename "$dir") :: $(basename "$OF") "
        echo "$mfile -> $OF"
        #avconv -nostats -loglevel info  -i "$mfile" -codec:a libmp3lame -qscale:a $QQ  "$OF"
        ffmpeg -loglevel error -i "$mfile" -aq "$QQ" -map_metadata 0 -id3v2_version 3 "$OF" 2>/dev/null
        wait
    else
        echo "EXIST: $OF"

    fi
done

exit

## do mp3s
echo
echo "Reduce large mp3 or copy:"
find "$IN" -iname "*.mp3" | wc -l

find "$IN" -iname "*.mp3" | while read mfile; do

    OF="$(echo "$mfile" | sed 's,'"$IN","$OUT\/"',g'  | sed 's@FLAC@MUSIC@' | sed 's@!NOFLAC@MUSIC@'  )"
    dir="$(dirname "$OF")"

    mkdir -p "$dir"

    bbt="$(file "$mfile" | sed 's/.*, \(.*\)kbps.*/\1/' | tr -d " ")"

    ## check bitrate
    if [[ $bbt -ge $BIT ]]; then
        ## re encode mp3
        if [ ! -e "$OF" ]; then
            echo ":: $(basename "$dir") :: $(basename "$OF") "
            # avconv -nostats -loglevel info  -i "$mfile" -codec:a libmp3lame -qscale:a $QQ  "$OF"
            # ffmpeg --quit -hide_banner -loglevel panic -i "$flac" -aq 2 -map_metadata 0 -id3v2_version 3 -write_id3v1 1 "$OF"
        fi
    else
        ## copy mp3
        cp -v "$mfile" "$OF"
    fi

done



exit 0



#
# Switch        Kbit/s        Bitrate range kbit/s
# -b 320        320           320 CBR
# -V 0          245           220...260
# -V 1          225           190...250
# -V 2          190           170...210
# -V 3          175           150...195
# -V 4          165           140...185
# -V 5          130           120...150
# -V 6          115           100...130
# -V 7          100            80...120
# -V 8           85            70...105
# -V 9           65            45...85
