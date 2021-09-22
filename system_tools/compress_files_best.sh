#!/bin/bash
## created on 2022-09-21

#### Compress individual files after testing for best compression method for each file

## Use glob to pass files. Example: compress_file_best.sh ./**/*.dat
## Will ignore folders
## The intend is to be used for archiving original data like .csv .dat .txt
## Most programming languages can read this files directly
## Will try to compress already compressed files
## Will not recompress with the same algorith

# SHOW_TABLE=true
# APPLY_COMPRESSION=true
# REMOVE_ORIGINAL=true

## compression commands to test
ALGO=( bzip2 gzip xz )


echo
echo "$@"
echo
echo "THE ABOVE FILES WILL BE PROCESSED!"
echo "SHOW TABLE:         $SHOW_TABLE"
echo "APPLY_COMPRESSION:  $APPLY_COMPRESSION"
echo "REMOVE_ORIGINAL:    $REMOVE_ORIGINAL"
echo
read -p "Are you sure? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
else
    echo "EXIT"
    exit 0
fi

if [[ $REMOVE_ORIGINAL ]]; then
    echo
    echo "************************"
    echo "    LAST WARNING  !!    "
    echo " This will remove files "
    echo "************************"
    echo
    read -p "ARE YOUT SURE? "  -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
    else
        echo "EXIT"
        exit 0
    fi
fi


for af in "$@" ; do
    [[ ! -f "$af" ]] && echo "NOT A FILE: $af" && continue

    ## initialize stats for a file
    FILESIZE=$(stat -c%s "$af")
    fsizes=()
    codecs=()
    clevel=()
    cratio=()

    echo "$FILESIZE  $af"

    ## compression commands to test
    for com in "${ALGO[@]}"; do
        bsize=$FILESIZE
        ## compression levels to test
        for cl in {1..9}; do
            size=$($com -c "$af" -"$cl" | wc -c)
            # echo $com $cl $size

            ## stop when no improvement
            # [[ $size -ge $bsize ]] && echo "stop $com loop no improvement" && break
            [[ $size -ge $bsize ]] && break

            ## keep stats
            codecs+=( "$com"  )
            fsizes+=( "$size" )
            clevel+=( "$cl"   )
            cratio+=( "$(echo "scale=3; 100 * ($size - $FILESIZE)  / $FILESIZE" | bc | sed -e 's/^-\./-0./' -e 's/^\./0./')" )

            ## remember previous
            bsize=$size
        done
    done

    ## get sorted indexes
    indexes=$( for k in "${!fsizes[@]}"; do
                    echo "$k" ' - ' "${fsizes["$k"]}"
                done | sort -n -k3 | cut -d' ' -f1 | tr '\n' ' ' | sed 's/,$//')
    ## sorted arrays
    Sfsizes=()
    Scodecs=()
    Sclevel=()
    Scratio=()
    for i in $indexes; do
        Sfsizes+=( "${fsizes[$i]}" )
        Scodecs+=( "${codecs[$i]}" )
        Sclevel+=( "${clevel[$i]}" )
        Scratio+=( "${cratio[$i]}" )
    done

    ## just show stats table
    if [ $SHOW_TABLE ]; then
        paste <(printf "%s\n" "${Scodecs[@]}") <(printf "%s\n" "${Sclevel[@]}") <(printf "%s\n" "${Sfsizes[@]}") <(printf "%s %%\n" "${Scratio[@]}")
    fi

    ## compression logic
    if [ ${#Scodecs[@]} -eq 0 ]; then
        echo "No compression benefits found for file"
    else
        ext="$(echo "${Scodecs[0]}" | sed 's/ip//g')"
        ## usefull to gather stats for multiple files
        echo "BEST found:        ${Scodecs[0]} ${Sclevel[0]} ${Sfsizes[0]} ${Scratio[0]}% $af "

        ## skip if file has the same extension
        fname="$(basename "$af")"
        oldexten="${fname##*.}"

        ## just avoid recompress with the same algorithm
        if [ "$oldexten" == "$ext" ]; then
            echo "Same extensions $oldexten $ext"
            echo "Skip compression!!"
        else
            newfile="${af}.${ext}"
            ## apply best compression to file
            if [ $APPLY_COMPRESSION ]; then
                echo "APPLY COMPRESSION: ${Scodecs[0]} -c -${Sclevel[0]} $af > $newfile "
                ${Scodecs[0]} -c -"${Sclevel[0]}" "$af" > "$newfile"
                status=$?
                ## remove original file
                if [ $REMOVE_ORIGINAL ]; then
                    [[ $status -eq 0 ]] && trash "$af"
                    echo "Removed:           $af"
                fi
            fi
        fi
    fi
    echo
done

echo
echo "FINISHED"
echo
exit

