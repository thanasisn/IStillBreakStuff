#!/bin/bash
## created on 2022-09-21

#### Compress individual files after testing for best compression method for each file

## The intend is to be used for archiving original data like .csv .dat .txt
## Most programming languages can read this files directly anyway
## Can be run interactively or in batch mode for scripting

## Defaults ##
SHOW_TABLE="yes"
APPLY_COMPRESSION="yes"
REMOVE_ORIGINAL="yes"
INTERACTIVE="yes"
BYTES_REDUCTION="10"
OVERWRITE="yes"

ALGO=( bzip2 gzip xz )

function _usage()
{
cat <<EOF

$*

    Usage: $(basename "${0}") <[options]> ./Glob/path/**/*.*

    Options:
        --ask-human       ($INTERACTIVE) Ask human for input. Setting to no may be dangerous.
        --compress        ($APPLY_COMPRESSION) Write file with the best compressed. If no just test for best algorithm.
        --help            Show this message and exit.
        --remove-source   ($REMOVE_ORIGINAL) Remove source file if compression was successful.
        --show-table      ($SHOW_TABLE) Show stats table for all tests
        --threshold-bytes ($BYTES_REDUCTION) Don't compress if benefit is less than $BYTES_REDUCTION bytes
        --overwrite       ($OVERWRITE) Overwrite existing files

    Notes:
        Will try  ${ALGO[@]}  compressions with all levels add will stop when it finds the best.
        Will ignore folders.
        Will not try to compress an already compressed file.

EOF
}

ARGUMENT_LIST=(
    "ask-human"
    "compress"
    "help"
    "remove-source"
    "show-table"
    "overwrite"
    "threshold-bytes"
)

# read arguments
opts=$(getopt \
    --longoptions "$(printf "%s:," "${ARGUMENT_LIST[@]}")" \
    --name "$(basename "$0")" \
    --options "" \
    -- "$@"
)

eval set --$opts

while [[ $# -gt 0 ]]; do
    case "$1" in
        --show-table )     SHOW_TABLE="$2";        shift 2 ;;
        --compress )       APPLY_COMPRESSION="$2"; shift 2 ;;
        --remove-source )  REMOVE_ORIGINAL="$2";   shift 2 ;;
        --ask-human )      INTERACTIVE="$2";       shift 2 ;;
        --overwrite )      OVERWRITE="$2";         shift 2 ;;
        --threshold-bytes) BYTES_REDUCTION="$2";   shift 2
                            if [ "$BYTES_REDUCTION" -eq "$BYTES_REDUCTION" ] 2>/dev/null; then
                                : #echo "$BYTES_REDUCTION : is a number"
                            else
                                _usage " >>> threshold-bytes: $BYTES_REDUCTION NOT A NUMBER <<< "&& exit
                            fi ;;
        --help )          _usage && exit ;;
        -- ) shift ;;
        * ) break ;;
    esac
done
[ $# = 0 ] && _usage " >>> NO TARGET GIVEN <<<  " && exit

echo
echo "$@"
echo
echo "THE ABOVE PATHS WILL BE PROCESSED!"
echo "SHOW TABLE:         $SHOW_TABLE"
echo "APPLY_COMPRESSION:  $APPLY_COMPRESSION"
echo "REMOVE_ORIGINAL:    $REMOVE_ORIGINAL"
echo "ASK HUMAN:          $INTERACTIVE"
echo "BYTES GAIN LIMIT:   $BYTES_REDUCTION"
echo "OVERWRITE:          $OVERWRITE"
echo
## to enter interactive mode
if [[ ! "$INTERACTIVE" == "no" ]]; then
    read -p "Are you sure? " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
    else
        echo "EXIT"
        exit 0
    fi

    if [[ $REMOVE_ORIGINAL == "yes" ]]; then
        echo
        echo "************************"
        echo "    LAST WARNING  !!    "
        echo " This will remove files "
        echo "************************"
        echo
        read -p "ARE YOU SURE? "  -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
        else
            echo "EXIT"
            exit 0
        fi
    fi
    else
    echo "RUNNING IN NON INTERACTIVE MODE!"
    echo
fi



## MAIN LOGIC ##

for af in "$@" ; do
    [[ ! -f "$af" ]] && echo "NOT A FILE: $af" && continue

    ## initialize stats for a file
    FILESIZE=$(stat -c%s "$af")
    fsizes=()
    codecs=()
    clevel=()
    cratio=()
    echo "--------------------------------------------------"
    echo "SIZE:     $FILESIZE  $af"

    ## compression commands to test
    for com in "${ALGO[@]}"; do
        bsize=$FILESIZE
        ## compression levels to test
        for cl in {1..9}; do
            ## test compression command
            size=$($com -c "$af" -"$cl" | wc -c)
            ## stop when no further improvement
            [[ $size -ge $bsize ]] && break
            ## keep stats in arrays
            codecs+=( "$com"  )
            fsizes+=( "$size" )
            clevel+=( "$cl"   )
            cratio+=( "$(echo "scale=3; 100*($size - $FILESIZE)/$FILESIZE" | bc | sed -e 's/^-\./-0./' -e 's/^\./0./')" )
            ## remember previous values
            bsize=$size
        done
    done

    ## get sorted indexes
    indexes=$( for k in "${!fsizes[@]}"; do
                    echo "$k" ' - ' "${fsizes["$k"]}"
                done | sort -n -k3 | cut -d' ' -f1 | tr '\n' ' ' | sed 's/,$//')
    ## sort arrays with indexes
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

    ## print stats table
    if [[ $SHOW_TABLE == "yes" ]]; then
        paste <(printf "%s\n" "${Scodecs[@]}") <(printf "%s\n" "${Sclevel[@]}") <(printf "%s\n" "${Sfsizes[@]}") <(printf "%s %%\n" "${Scratio[@]}")
    fi

    ## compression logic
    if [ ${#Scodecs[@]} -eq 0 ]; then
        echo "SKIP:     No compression benefits found:  $af"
        continue
    fi

    ext="$(echo "${Scodecs[0]}" | sed 's/ip//g')"
    ## useful to gather stats for multiple files compression analysis
    echo "BEST:     ${Scodecs[0]} ${Sclevel[0]} ${Sfsizes[0]} ${Scratio[0]}% $af "
    echo "BENEFIT:  $(( FILESIZE - Sfsizes[0] )) b"

    ## check benefit
    if [[ $(( FILESIZE - ${Sfsizes[0]} )) -lt $BYTES_REDUCTION  ]]; then
        echo "SKIP:     Benefit limit exceeded:  $af"
        continue
    fi

    ## avoid recompress a compressed file
    if ( file "$af" | grep -q compressed ) ;then
        echo "SKIP:    Source already compressed:   $af"
        continue
    fi

    newfile="${af}.${ext}"
    ## apply best compression to file
    if [[ $APPLY_COMPRESSION == "yes" ]]; then
        ## avoid overwrite
        if [[ $OVERWRITE == "no" ]] && [[ -e "$newfile" ]] ; then
            echo "SKIP:     File exist:  $newfile"
            continue
        fi
        echo "COMPRESS: ${Scodecs[0]} -c -${Sclevel[0]} $af > $newfile "
        ${Scodecs[0]} -c -"${Sclevel[0]}" "$af" > "$newfile"
        status=$?
        newsize=$(stat -c%s "$newfile")
        ## remove original file if new non empty
        if [ "$newsize" -gt 0 ]; then
            if [[  $REMOVE_ORIGINAL == "yes" ]]; then
                [[ $status -eq 0 ]] && trash "$af"
                echo "REMOVED:  $af"
            fi
        else
            echo "WARNING:  Empty file:  $newfile"
        fi
    fi
done
echo
echo "FINISHED"
echo
