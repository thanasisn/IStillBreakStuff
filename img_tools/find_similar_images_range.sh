#!/bin/bash
## created on 2019-01-08

#### Find similar images in a folder within a range of similarity

FOLDER="$1"
THRESHMIN="$2"
THRESHMAX="$3"
TOMANY="$4"

## default threshold and max group size to display
THRESHMIN="${THRESHMIN:-90}"
THRESHMAX="${THRESHMAX:-100}"
TOMANY="${TOMANY:-16}"

PID="$$"

echo "$@"

if [[ ! -d "$FOLDER" ]];then
    echo "Give a folder to process"
    echo "$(basename $0) <folder> [threshold min $THRESHMIN] [threshold max $THRESHMIN] [max group size $TOMANY]"
    exit
fi

if [[ $THRESHMIN -lt 1 ]] || [[ $THRESHMIN -gt 99 ]]; then
    echo "Invalid min threshold $THRESHMIN"
    exit 1
fi

if [[ $THRESHMAX -le $THRESHMIN ]] || [[ $THRESHMAX -gt 100 ]]; then
    echo "Invalid max threshold $THRESHMAX"
    exit 1
fi

## create files to store results
## these are excluded from borg
fingerpr="$FOLDER/.fingerprinds.db"
ignorelist="$FOLDER/.ignorelist.list"
dupsimgsMAX="$FOLDER/.dupimg_$THRESHMAX.list"
dupsimgsMIN="$FOLDER/.dupimg_$THRESHMIN.list"
dupsimgs="$FOLDER/.dupimg_${THRESHMIN}_${THRESHMAX}.list"
dupsdirs="$FOLDER/.dupdir_${THRESHMIN}_${THRESHMAX}.list"

touch "${ignorelist}"

echo ""
echo " >> Create fingerprints and find duplicate images << "
echo ""
echo "Fingerprints : $fingerpr"
echo "Dups         : $dupsimgs"
echo "Dir Dups     : $dupsdirs"
echo "Threshold    : $THRESHMIN - $THRESHMAX  "
echo "Set limit    : $TOMANY  "

REPLY="N"

if [ -f "$dupsimgs" ]; then
    echo "Duplicates sets file found ("$dupsimgs")"
    echo "With  "$(wc -l "$dupsimgs" | cut -d' ' -f1 )"  sets"
    echo ""
    read -p "Use old list y/n? " -n1
    echo ""
    echo ""
fi

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo " Skipping fingerprinding and matching "
    echo
else
    echo " Redo fingerprinding and matching"

    ## empty dups file
    truncate -s 0 "$dupsimgsMAX"
    truncate -s 0 "$dupsimgsMIN"

    echo " Do fingerprinding max threshold"
    #### create a list of dups with max threshold ####
    findimagedupes           \
                --quiet      \
                --recurse    \
                --prune      \
                --threshold    "$THRESHMAX"   \
                --fingerprints "$fingerpr"    \
                "$FOLDER" | sed 's@\(.*\)@"\1"@g ; s@ /@" "/@g' | while read line;do
                    echo "$line" >> "$dupsimgsMAX"
                done

    echo " Do fingerprinding min threshold"
    #### create a list of dups with min threshold ####
    findimagedupes           \
                --quiet      \
                --recurse    \
                --prune      \
                --threshold    "$THRESHMIN"   \
                --fingerprints "$fingerpr"    \
                "$FOLDER" | sed 's@\(.*\)@"\1"@g ; s@ /@" "/@g' | while read line;do
                    echo "$line" >> "$dupsimgsMIN"
                done
fi


echo ""
echo "Display a folder frequency count"
echo ""

cat "$dupsimgsMIN" | while read line ;do
    echo "$line" | sed 's@" "@"\n"@g' | while read ff;do
        ## remove quotes
        ff=${ff#\"}
        ff=${ff%\"}
        echo "\"$(dirname "$ff")\""
    done | sort -u | tr '\n' ' '
    echo
done | sort | uniq -c | sort -bg > "$dupsdirs"

cat "$dupsdirs"



## sort each line
cat "$dupsimgsMIN" | while read line ;do
    echo "$line" | sed 's@" "@"\n"@g' | while read ff;do
        ## remove quotes
        ff=${ff#\"}
        ff=${ff%\"}
        echo "\"$ff\""
    done | sort | tr '\n' ' '
    echo
done > "${dupsimgsMIN}.tmp"
sort "${dupsimgsMIN}.tmp" > "${dupsimgsMIN}"

cat "$dupsimgsMAX" | while read line ;do
    echo "$line" | sed 's@" "@"\n"@g' | while read ff;do
        ## remove quotes
        ff=${ff#\"}
        ff=${ff%\"}
        echo "\"$ff\""
    done | sort | tr '\n' ' '
    echo
done > "${dupsimgsMAX}.tmp"
sort "${dupsimgsMAX}.tmp" > "${dupsimgsMAX}"
rm  "${dupsimgsMAX}.tmp" "${dupsimgsMIN}.tmp"

## find only within the range
comm -2 -3 "${dupsimgsMIN}" "${dupsimgsMAX}" > "$dupsimgs"


sets="$(wc -l $dupsimgs | cut -d' ' -f1 )"
echo "Found  $sets  sets ($dupsimgs) "
echo ""

if [[ $sets -lt 1 ]]; then
    echo "No sets remaining"
    exit 0
fi


## get max monitor dimenstions
Xaxis=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f1 | sort -n | tail -1)
Yaxis=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f2 | sort -n | tail -1)

thumbwidth="$((Xaxis/4))"
thumbheith="$((Xaxis/4))"
ncols=2

## we will use half width for thumbnails and rest for preview
echo ""
echo "Feh display options (half screen thumbs, half preview)"
echo "geometry width: $((Xaxis/2))"
echo "thumb    width: $((Xaxis/(ncols+2)))"

sets="$(wc -l $dupsimgs | cut -d' ' -f1 )"
echo "Found  $sets  sets ($dupsimgs) "

echo ""
read -p "Display dups sets with feh y/n? " -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo " ...starting feh... "
    echo " ...use an empty desktop..."

    cnt=1
    #### send each set of dups to feh for display
    \cat "$dupsimgs" | while read line ;do

        ## count images in the set

        nset="$(echo "$line" | sed 's@" "@"\n"@g' | wc -l)"
        nrows="$((  ( nset + ncols - 1 )  / ncols))"

        echo "SET: $((cnt++))/$sets  $ncols x $nrows = $nset "

        if [[ $nset -gt $TOMANY ]]; then
            echo "Too many matches ($nset), SKIP!"
            continue
        fi

        (echo "$line" | sed 's@" "@"\n"@g' | while read ff;do
            ## remove quotes
            ff=${ff#\"}
            ff=${ff%\"}
            echo "$ff"
        done) | sort | feh  -f -                                            \
                    --draw-actions                                          \
                    --draw-filename                                         \
                    --draw-exif                                             \
                    --draw-tinted                                           \
                    --verbose                                               \
                    --scale-down                                            \
                    --info "echo %V %S %wx%h $cnt/$sets  $(basename %F)"   \
                    --action1 "[recycle & exit]trash-put %F; killall feh"   \
                    --action3 "[recycle]trash-put %F"                       \
                    --action5 ';[open folder]caja "$(dirname %F)" &'        \
                    --action7 "[Ignore set]echo "$ff" &"        \
                    --action9 "[quit view]killall feh"                      \
                    --thumbnails                                            \
                    --thumb-height $thumbheith                              \
                    --thumb-width  $thumbwidth                              \
                    --limit-width  $((thumbwidth*ncols))                    \
                    --limit-height $(((thumbheith+5)*nrows))                \
                    --index-info ''
    done
fi

# read -p "Open duplicate directories y/n? " -r
# echo ""
# if [[ $REPLY =~ ^[Yy]$ ]]; then
#     \cat "$dupsdirs" | while read line ;do
#
#         line="$(echo "$line" | cut -d' ' -f2-)"
#
#         nset="$(echo "$line" | sed 's@" "@"\n"@g' | wc -l)"
#
#         if [[ $nset -gt 4 ]]; then
#             echo "Too many matches ($nset), SKIP!"
#             continue
#         fi
#
#         args=( $line )
#         caja "${args[@]}"
# #         caja $line
# #         caja "$line"
#
# #         (echo "$line" | sed 's@" "@"\n"@g' | while read ff;do
# #             ## remove quotes
# #             ff=${ff#\"}
# #             ff=${ff%\"}
# #             echo "$ff"
# # #         [[ -e $ff ]] &&  echo "EXIST $ff"
# #         done)  #| gthumb
#
#     done
# fi

exit 0
