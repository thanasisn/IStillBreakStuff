#!/bin/bash
## created on 2013-09-14

#### Transcode music library image from FLAC to mp3
## The intentions is to make music available to other machines and mp3 devices
## We keep the folder structure to share playlist easily


## Original library
IN="/home/folder/Music/"
## Trascoded library
OUT="/media/barel/Music_img"

## Transcode quality target
QQ=1
## mp3 transcode threshold
BIT=240

if [ ! -d "$IN" ]; then
    echo "$IN is not a directory"
    exit 1
fi
mkdir -p "$OUT"

## logging definitions
ldir="/home/athan/LOGs/SYSTEM_LOGS/"
mkdir -p "$ldir"

ID="$1"
: ${ID:=$(hostname)}
SCRIPT="$(basename "$0")"

fsta="${ldir}/$(basename "$0")_$ID.status"
info()   { echo "$(date +'%F %T') ::INF::${SCRIPT}::${ID}:: $* ::" >>"$fsta"; }
status() { echo "$(date +'%F %T') ::STA::${SCRIPT}::${ID}:: $* ::" >>"$fsta"; }

LOG_FILE="/tmp/$(basename $0)_$(date +%F_%R).log"
ERR_FILE="/tmp/$(basename $0)_$(date +%F_%R).err"

exec  > >(tee -i "${LOG_FILE}")
exec 2> >(tee -i "${ERR_FILE}")


## to transcode
nflac="$(
( find "$IN" -iname "*.flac"
  find "$IN" -iname "*.wma") | wc -l)"
echo
echo "Transcode candidates flac and wma: $nflac"

nmp3="$(
(  find "$IN" -iname "*.mp3"
) | wc -l)"
echo "Copy candidates mp3:               $nmp3"
echo

## transcode lossless
info "Start lossless transcoding"
cc=0
(
find "$IN" -iname "*.flac"
find "$IN" -iname "*.wma"
) | while read mfile; do

    OF="$(echo "$mfile" |\
          sed 's@.flac$@.mp3@g' |\
          sed 's@.wma$@.mp3@g'  |\
          sed 's,'"$IN","$OUT\/"',g' )"
    dir="$(dirname "$OF")"

    mkdir -p "$dir"

    ## skip existing files
    if [ ! -e "$OF" ]; then
        echo "$cc/$nflac :: $(basename "$dir") :: $(basename "$OF") "
        # echo "$mfile -> $OF"
        #avconv -nostats -loglevel info  -i "$mfile" -codec:a libmp3lame -qscale:a $QQ  "$OF"
        ffmpeg -nostdin         \
               -loglevel error  \
               -i "$mfile"      \
               -aq "$QQ"        \
               -map_metadata 0  \
               -id3v2_version 3 \
               -write_id3v1 1   \
               "$OF" 2>/dev/null
    else
        echo "EXIST: $OF"
    fi
    cc=$((cc+1))
done



## transcode mp3s
info "Transcode mp3"
cc=0
echo
find "$IN" -iname "*.mp3" | while read mfile; do

    OF="$(echo "$mfile" | sed 's,'"$IN","$OUT\/"',g'  | sed 's@FLAC@MUSIC@' | sed 's@!NOFLAC@MUSIC@'  )"
    dir="$(dirname "$OF")"

    mkdir -p "$dir"

    ## get bitrate of original file
    bbt="$(file "$mfile" | sed 's/.*, \(.*\)kbps.*/\1/' | tr -d " ")"

    ## check bitrate
    if [[ $bbt -ge $BIT ]]; then
        ## re encode mp3
        if [ ! -e "$OF" ]; then
            echo "$cc/$nmp3 :: $(basename "$dir") :: $(basename "$OF") "
            # avconv -nostats -loglevel info  -i "$mfile" -codec:a libmp3lame -qscale:a $QQ  "$OF"
            ffmpeg -nostdin         \
                   -loglevel error  \
                   -i "$mfile"      \
                   -aq "$QQ"        \
                   -map_metadata 0  \
                   -id3v2_version 3 \
                   -write_id3v1 1   \
                   "$OF" 2>/dev/null
        else
            echo "EXIST: $OF"
        fi
    else
        ## copy mp3
        printf "$cc/$nmp3 "
        cp -v "$mfile" "$OF"
    fi
    cc=$((cc+1))
done



exit 0



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
