#!/bin/bash
## created on 2013-09-14

#### Transcode music library image from FLAC to mp3 and trim silence
## The intentions is to make music available to other machines and mp3 devices
## We keep the folder structure to share playlist easily


## Original library
IN="/home/folder/Music/"
## Trascoded library
OUT="/media/barel/Music_img"

## Transcode quality target
QQ=1
## mp3 transcode/copy threshold
BIT=220

## duration of non silence
sl_start_duration="2"
## silense volume
sl_start_threshold="-29dB"
## detection method "rms" or "peak"
sl_detection="rms"

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

mkdir -p "$(dirname "$0")/LOGs/"
LOG_FILE="$(dirname "$0")/LOGs/$(basename "$0")_$(date +%F_%T).log"
ERR_FILE="$(dirname "$0")/LOGs/$(basename "$0")_$(date +%F_%T).err"
touch "$LOG_FILE" "$ERR_FILE"

exec  > >(tee -i "${LOG_FILE}")
exec 2> >(tee -i "${ERR_FILE}")


## count files to transcode
nflac="$(
( find "$IN" -type f -iname "*.flac"
  find "$IN" -type f -iname "*.wma") | wc -l)"
echo
echo "Transcode candidates flac and wma: $nflac"

nmp3="$(
(  find "$IN" -iname "*.mp3"
) | wc -l)"
echo "Copy candidates mp3:               $nmp3"
echo



info "Transcode lossless to mp3"
cc=0
(
find "$IN" -type f -iname "*.flac"
find "$IN" -type f -iname "*.wma"
) | while read mfile; do

    ## skip deleted files
    if [ -e "$mfile" ] ; then

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
            ## trim silence after transcoding
            tmpfl="$OF.tmp.mp3"

            ## try to trim the file
            ffmpeg -y            \
                -nostdin         \
                -loglevel error  \
                -i "$OF"         \
                -aq "$QQ"        \
                -map_metadata 0  \
                -id3v2_version 3 \
                -write_id3v1 1   \
                -af              \
                "silenceremove=\
                start_periods=1:\
                start_duration=$sl_start_duration:\
                start_threshold=$sl_start_threshold:\
                detection=$sl_detection,\
                aformat=dblp,areverse,silenceremove=\
                start_periods=1:\
                start_duration=$sl_start_duration:\
                start_threshold=$sl_start_threshold:\
                detection=$sl_detection,\
                aformat=dblp,areverse" "$tmpfl"

            ## replace original file
            if [ -e "$tmpfl" ]; then
                echo "Removed silense"
                mv "$tmpfl" "$OF"
            fi
        else
            echo "EXIST: $OF"
        fi
    else
        echo "Missing source $mfile"
    fi

    cc=$((cc+1))
done



info "Transcode or copy mp3"
cc=0
echo
find "$IN" -type f -iname "*.mp3" | while read mfile; do

    ## skip deleted files
    if [ -e "$mfile" ] ; then

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
                ## trim silence after transcoding
                tmpfl="$OF.tmp.mp3"

                ## try to trim the file
                ffmpeg -y            \
                    -nostdin         \
                    -loglevel error  \
                    -i "$OF"         \
                    -aq "$QQ"        \
                    -map_metadata 0  \
                    -id3v2_version 3 \
                    -write_id3v1 1   \
                    -af              \
                    "silenceremove=\
                    start_periods=1:\
                    start_duration=$sl_start_duration:\
                    start_threshold=$sl_start_threshold:\
                    detection=$sl_detection,\
                    aformat=dblp,areverse,silenceremove=\
                    start_periods=1:\
                    start_duration=$sl_start_duration:\
                    start_threshold=$sl_start_threshold:\
                    detection=$sl_detection,\
                    aformat=dblp,areverse" "$tmpfl"

                ## replace original file
                if [ -e "$tmpfl" ]; then
                    echo "Removed silense"
                    mv "$tmpfl" "$OF"
                fi
            else
                echo "EXIST: $OF"
            fi
        else
            ## copy mp3
            printf "$cc/$nmp3 "
            cp -vu "$mfile" "$OF"
            ## trim silence after copying
            tmpfl="$OF.tmp.mp3"

            ## try to trim the file
            ffmpeg -y            \
                -nostdin         \
                -loglevel error  \
                -i "$OF"         \
                -aq "$QQ"        \
                -map_metadata 0  \
                -id3v2_version 3 \
                -write_id3v1 1   \
                -af              \
                "silenceremove=\
                start_periods=1:\
                start_duration=$sl_start_duration:\
                start_threshold=$sl_start_threshold:\
                detection=$sl_detection,\
                aformat=dblp,areverse,silenceremove=\
                start_periods=1:\
                start_duration=$sl_start_duration:\
                start_threshold=$sl_start_threshold:\
                detection=$sl_detection,\
                aformat=dblp,areverse" "$tmpfl"

            ## replace original file
            if [ -e "$tmpfl" ]; then
                echo "Removed silense"
                mv "$tmpfl" "$OF"
            fi
        fi
    else
        echo "Missing source $mdile"
    fi

    cc=$((cc+1))
done



info "Copy covers to image library"
## list all folders with music
( find "$IN" -type f -iname "*.flac"
  find "$IN" -type f -iname "*.wma"
  find "$IN" -type f -iname "*.mp3") | xargs -I {} dirname {} | sort -u | while read adir ; do

  ## list all images
  find "$adir" -type f -maxdepth 1 -iname "*.jpg" | while read aimg; do
    target="$(echo "$aimg" | sed 's,'"$IN","$OUT\/"',g')"
    cp -vu "$aimg" "$target"
  done
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
