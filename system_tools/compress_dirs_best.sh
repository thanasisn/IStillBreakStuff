#!/bin/bash
## created on 2022-09-21
## https://github.com/thanasisn <natsisphysicist@gmail.com>


#### Compress individual folders after testing for best compression method for each folder

## The intend is to be used for archiving folders
## Can be run interactively or in batch mode for scripting

## Defaults ##
SHOW_TABLE="no"
APPLY_COMPRESSION="yes"
REMOVE_ORIGINAL="no"
INTERACTIVE="yes"
BYTES_REDUCTION="1024"
OVERWRITE="yes"
PROGRESS="yes"

ALGO=( bzip2 gzip xz brotli zstd )

## Check available compression algorithms
for i in ${!ALGO[@]}; do
    ## remove not existing
    if ! command -v "${ALGO[i]}" &> /dev/null; then
        # echo "NOT available: ${ALGO[i]}" 
        unset "ALGO[i]"
    # else
    #     echo "Available  ${ALGO[i]}"
    fi
done
echo ""
echo "Available codecs:  ${ALGO[@]}"

function _usage()
{
cat <<EOF

$*

    Usage: $(basename "${0}") <[options]> ./Glob/path/*/

    Options:
        --algorithm       [<an algorithm>] (${ALGO[@]}) Give a specific algorithm to use quote and space for multiple .
        --ask-human       [yes/no] ($INTERACTIVE) Ask human for input. Setting to 'no' may be dangerous.
        --compress        [yes/no] ($APPLY_COMPRESSION) Write file with the best compressed. If no just test for best algorithm.
        --remove-source   [yes/no] ($REMOVE_ORIGINAL) Remove source file if compression was successful.
        --show-table      [yes/no] ($SHOW_TABLE) Show stats table for all tests
        --threshold-bytes [yes/no] ($BYTES_REDUCTION) Don't compress if benefit is less than $BYTES_REDUCTION bytes
        --overwrite       [yes/no] ($OVERWRITE) Overwrite existing files
        --show-progress   [yes/no] ($PROGRESS) Show some progress info while trying to find the best
        --help            Show this message and exit.

    Notes:
        Will try  ${ALGO[@]}  compressions with all levels add will stop when it finds the best.
        Will ignore folders.
        Will not try to compress an already compressed file.

    Examples:
        $(basename "${0}") ./data 
        $(basename "${0}") --show-table=yes ./data 
        $(basename "${0}") --compress y ./data 

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
    "show-progress"
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

##TODO check if input is no or yes
while [[ $# -gt 0 ]]; do
    case "$1" in
        --algorithm       )  ALGO=( $2 );            shift 2 ;;
        --show-table      )  SHOW_TABLE="$2";        shift 2 ;;
        --show-progress   )  PROGRESS="$2";          shift 2 ;;
        --compress        )  APPLY_COMPRESSION="$2"; shift 2 ;;
        --remove-source   )  REMOVE_ORIGINAL="$2";   shift 2 ;;
        --ask-human       )  INTERACTIVE="$2";       shift 2 ;;
        --overwrite       )  OVERWRITE="$2";         shift 2 ;;
        --threshold-bytes )  BYTES_REDUCTION="$2";   shift 2
                             if [ "$BYTES_REDUCTION" -eq "$BYTES_REDUCTION" ] 2>/dev/null; then
                                 : #echo "$BYTES_REDUCTION : is a number"
                             else
                                 _usage " >>> threshold-bytes: $BYTES_REDUCTION NOT A NUMBER <<< "&& exit
                             fi ;;
        --help            )  _usage && exit ;;
        --                )  shift          ;;
        *                 )  break          ;;
    esac
done
# echo $#
[ $# = 0 ] && _usage " >>> NO TARGET GIVEN <<<  " && exit

echo
echo "$@"
echo
echo "THE ABOVE PATHS WILL BE PROCESSED!"
echo "Algorithm:          ${ALGO[*]}"
echo "Show table:         $SHOW_TABLE"
echo "Show progress:      $PROGRESS"
echo "Apply compression:  $APPLY_COMPRESSION"
echo "Remove original:    $REMOVE_ORIGINAL"
echo "Ask human:          $INTERACTIVE"
echo "Bytes gain limit:   $BYTES_REDUCTION"
echo "Overwrite:          $OVERWRITE"
echo
## to enter interactive mode
if [[ ! "$INTERACTIVE" == "no" ]]; then
    read -p "Are you sure? " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
    else
        echo ""
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
    [[ ! -d "$af" ]] && echo "NOT A FOLDER: $af" && continue

    ## initialize stats for a file
    FILESIZE=$(tar -cf - "$af" 2> >(grep -v "Removing leading") | wc -c   )
    fsizes=()
    codecs=()
    clevel=()
    cratio=()
    cdurat=()
    echo "--------------------------------------------------"
    echo "SIZE:     $FILESIZE  $af"

    ## compression commands to test
    for com in "${ALGO[@]}"; do
        bsize=$FILESIZE
        ## compression levels to test
        for cl in {1..9}; do
            ## test compression command
            tic=$SECONDS
            size=$(tar -cf - "$af" 2> >(grep -v "Removing leading") | $com -c -"$cl" - | wc -c)
            tac=$((SECONDS - tic))
            ## info 
            [[ $PROGRESS =~ ^[Yy] ]] && echo "Tested: $com $cl in $((tac/60)):$((tac%60))"
            ## keep stats in arrays
            cdurat+=( "$tac"  )
            codecs+=( "$com"  )
            fsizes+=( "$size" )
            clevel+=( "$cl"   )
            cratio+=( "$(echo "scale=3; 100*($size - $FILESIZE)/$FILESIZE" | bc | sed -e 's/^-\./-0./' -e 's/^\./0./')" )
            ## stop when no further improvement
            [[ $size -ge $bsize ]] && break
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
        Scdurat+=( "${cdurat[$i]}" )
    done

    ## print stats table
    if [[ $SHOW_TABLE =~ ^[Yy] ]]; then
        paste <(printf "%s\n"    "${Scodecs[@]}") \
              <(printf "%s\n"    "${Sclevel[@]}") \
              <(printf "%s\n"    "${Sfsizes[@]}") \
              <(printf "%s %%\n" "${Scratio[@]}") \
              <(printf "%s s\n"  "${Scdurat[@]}")
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

    newfile="${af%/}.tar.${ext}"
    ## apply best compression to file
    if [[ $APPLY_COMPRESSION =~ ^[Yy] ]]; then
        ## avoid overwrite
        if [[ $OVERWRITE == "no" ]] && [[ -e "$newfile" ]] ; then
            echo "SKIP:     File exist:  $newfile"
            continue
        fi
        echo "COMPRESS: ${Scodecs[0]} -c -${Sclevel[0]} $af > $newfile "
        tar -cf - "$af" 2> >(grep -v "Removing leading") | ${Scodecs[0]} -c -"${Sclevel[0]}" - > "$newfile"
        status=$?
        newsize=$(stat -c%s "$newfile")
        ## remove original file if new non empty
        if [ "$newsize" -gt 0 ]; then
            if [[  $REMOVE_ORIGINAL =~ ^[Yy] ]]; then
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
