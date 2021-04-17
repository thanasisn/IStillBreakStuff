#!/bin/bash
## created on 2019-01-08

#### Find similar images in a folder and display them and remove interactively

FOLDER="$1"
THRESH="$2"
TOMANY="$3"

## default threshold and max group size to display
THRESH="${THRESH:-90}"
TOMANY="${TOMANY:-10}"

PID="$$"

if [[ ! -d "$FOLDER" ]];then
    echo "Give a folder to process"
    echo "$(basename $0) <folder> [threshold] [max group size]"
    exit
fi

## create files to store results
## these are excluded from borg
fingerpr="$FOLDER/.fingerprinds.db"
dupsimgs="$FOLDER/.dupimg.list"
dupsdirs="$FOLDER/.dupdir.list"
excludef="$FOLDER/.exclude.temp"
EXCLUDE="$FOLDER/.exclude_image.list"


echo ""
echo " >> Create fingerprints and find duplicate images << "
echo ""
echo "Fingerprints : $fingerpr"
echo "Dups         : $dupsimgs"
echo "Dir Dups     : $dupsdirs"
echo "Threshold    : $THRESH  "
echo "Set limit    : $TOMANY  "

# find "$FOLDER" -name '*' -exec file {} \; | awk -F: '{if ($2 ~/image/) print $1}'

## check for fingerprints deeper
echo
echo " ... Fingerprints files in deeper folders ... "
find "$FOLDER" -mindepth 2 -iname ".fingerprinds.db"

echo
echo " ... Exclude list in deeper folders ... "
find "$FOLDER" -iname ".exclude_image.list"
echo


## gather exclude list to master file
find "$FOLDER" -iname ".exclude_image.list" | while read file;do
    echo "Parse $file"
    cat "$file" >> "$excludef"
done
sort -u -o "$excludef" "$excludef"



REPLY="N"

if [ -f "$dupsimgs" ]; then
    echo "Duplicates sets file found ("$dupsimgs")"
    echo "With  "$(wc -l "$dupsimgs" | cut -d' ' -f1 )"  sets"
    echo ""
    read -p "Use this or redo fingerprints y/n? " -n1
    echo ""
    echo ""
fi


if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo " Skipping fingerprinting and matching "
    echo
else
    echo " Redo fingerprinting and matching"

    ## empty dups file
    truncate -s 0 "$dupsimgs"

    #### create a list of dups and image fingerprints ####
    findimagedupes           \
                --quiet      \
                --recurse    \
                --prune      \
                --threshold    "$THRESH"   \
                --fingerprints "$fingerpr" \
                "$FOLDER" | sed 's@\(.*\)@"\1"@g ; s@ /@" "/@g' | while read line;do
                    echo "$line" >> "$dupsimgs"
                done
#     sort -o "$dupsimgs" "$dupsimgs"
    sort -R -o "$dupsimgs" "$dupsimgs"
fi

sets="$(wc -l $dupsimgs | cut -d' ' -f1 )"
echo "Found  $sets  sets ($dupsimgs) "
echo ""

## remove excluded images from the results
if [ -e "$excludef" ]; then
    echo "Exclude file $excludef exist"
    exn="$(wc -l $excludef | cut -d' ' -f1)"
    echo "$exn lines"
    ## remove from list
    if [[ "$exn" -gt 0 ]]; then
        cat "$excludef" | while read line ; do
            line="${line#\'}"
            line="${line%\'}"

            ## special rule case!!!
            line="$(echo "$line" | sed 's/\.art_screensaver/art/g')"
            echo "try remove: $line"

            line=$(echo $line | sed 's/\//\\\//g')
            sed -i "/$line/d" "$dupsimgs"

        done
    fi
fi

echo ""
echo "Display a folder frequency count"
echo ""

# \cat "$dupsimgs" | while read line ;do
#     ## remove file from folder
# #     echo "AAAAAAA"
#     (echo "$line" | sed 's@" "@"\n"@g' | while read path;do
#         echo -n "$(dirname "$path")\" "
#     done   #| sed 's@" "@"\n"@g' | sort -u | tr '\n' ' ' | sed 's@"  "@" "@g' | sed 's@"" @@g'
#     echo) | sed 's@" "@"\n"@g' | sed 's@"" *@@g' | sed '/^[[:space:]]*$/d'| sort -u | tr '\n' ' '
#     echo
# #     echo "ZZZZZZZ"
# done | sed 's@"  "@" "@g' | sed 's@ *$@@g'  | sort | uniq -c | sort -bgr > "$dupsdirs"

cat "$dupsimgs" | while read line ;do
    echo "$line" | sed 's@" "@"\n"@g' | while read ff;do
        ## remove quotes
        ff=${ff#\"}
        ff=${ff%\"}
        echo "\"$(dirname "$ff")\""
    done | sort -u | tr '\n' ' '
    echo
done | sort | uniq -c | sort -bg > "$dupsdirs"

cat "$dupsdirs"

## get max monitor dimensions for better display
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
    ## send each set of dups to feh for display
    \cat "$dupsimgs" | while read line ;do

        ## count images in the set
        nset="$(echo "$line" | sed 's@" "@"\n"@g' | wc -l)"
        nrows="$((  ( nset + ncols - 1 )  / ncols))"

        echo
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
    #         [[ -e $ff ]] &&  echo "EXIST $ff"
        done) | sort | feh  -f -                                            \
                    --draw-actions                                          \
                    --draw-filename                                         \
                    --draw-exif                                             \
                    --draw-tinted                                           \
                    --verbose                                               \
                    --scale-down                                            \
                    --info "echo %V %S %wx%h $cnt/$sets  $(basename %F)"    \
                    --action1 "[recycle & exit]trash-put %F; echo %F >> $EXCLUDE; killall feh"   \
                    --action3 "[recycle]trash-put %F; echo %F >> $EXCLUDE"     \
                    --action5 ';[open folder]caja "$(dirname %F)" &'        \
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
