#!/bin/bash
## created on 2022-09-21
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### Compress individual files after testing for best compression method for each file

## The intend is to be used for archiving original data like .csv .dat .txt
## Most programming languages can read this files directly anyway
## Can be run interactively or in batch mode for scripting

## Defaults ##
SHOW_TABLE="no"
APPLY_COMPRESSION="yes"
REMOVE_ORIGINAL="no"
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
        --algorithm       [bzip2 gzip xz] (${ALGO[@]}) Give a specific algorithm to use quote and space for multiple .
        --ask-human       [yes/no] ($INTERACTIVE) Ask human for input. Setting to 'no' may be dangerous.
        --compress        [yes/no] ($APPLY_COMPRESSION) Write file with the best compressed. If no just test for best algorithm.
        --remove-source   [yes/no] ($REMOVE_ORIGINAL) Remove source file if compression was successful.
        --show-table      [yes/no] ($SHOW_TABLE) Show stats table for all tests
        --threshold-bytes [yes/no] ($BYTES_REDUCTION) Don't compress if benefit is less than $BYTES_REDUCTION bytes
        --overwrite       [yes/no] ($OVERWRITE) Overwrite existing files
        --help            Show this message and exit.

    Notes:
        Will try  ${ALGO[@]}  compressions with all levels add will stop when it finds the best.
        Will ignore folders.
        Will not try to compress an already compressed file.

EOF
}

ARGUMENT_LIST=(
    "algorithm"
    "ask-human"
    "compress"
    "help"
    "overwrite"
    "remove-source"
    "show-table"
    "threshold-bytes"
)

bytesToHuman() {
    b=${1:-0}; d=''; s=0; S=("      B" {K,M,G,T,P,E,Z,Y}iB)
    while ((b > 1024)); do
        d="$(printf ".%03d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        (( s++ ))
    done
#     echo   "$b$d ${S[$s]}"
    printf "%5s%s %s" "$b" "$d" "${S[$s]}"
}



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
        --algorithm  )     ALGO=( $2 );            shift 2 ;;
        --show-table )     SHOW_TABLE="$2";        shift 2 ;;
        --compress   )     APPLY_COMPRESSION="$2"; shift 2 ;;
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
echo "ALGORITHM:          ${ALGO[@]}"
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
            echo ""
            echo "EXIT"
            exit 0
        fi
    fi
    else
    echo "RUNNING IN NON INTERACTIVE MODE!"
    echo
fi



## MAIN LOGIC ##
totalsize="0"
totalcompressed="0"

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
    echo "BEST:     c:${Scodecs[0]} l:${Sclevel[0]} b:${Sfsizes[0]} r:${Scratio[0]}% $af "
    echo "BENEFIT:  $(( FILESIZE - Sfsizes[0] )) b"
    totalsize=$(( totalsize + FILESIZE ))
    totalcompressed=$(( totalcompressed + Sfsizes[0] ))

    ## check benefit
    if [[ $(( FILESIZE - Sfsizes[0] )) -lt $BYTES_REDUCTION  ]]; then
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

## get relative numbers
rcom="$( echo "scale=2; 100 * ${totalcompressed}/${totalsize}" | bc )"
rben="$( echo "scale=2; 100 * ( $totalsize - $totalcompressed) /${totalsize}" | bc )"

echo
echo "FINISHED"
echo
echo "Total input:      $(bytesToHuman $totalsize)  100%   $totalsize b"
echo "Total compressed: $(bytesToHuman $totalcompressed)  ${rcom}%  $totalcompressed b"
echo "Total benefit:    $(bytesToHuman $(( totalsize - totalcompressed )))  ${rben}%  $(( totalsize - totalcompressed )) b"


exit
