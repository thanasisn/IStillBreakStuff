#!/bin/bash
## created on 2021-01-07

#### Print a random message from the rules

## width of output length
WIDTH=${1:-110}

## keep a fixed number of lines for conky print
NLINE=30


outputdir="/dev/shm/CONKY/"
mkdir -p "$outputdir"
OUTPTFILE="${outputdir}inspmessage.log"

rlsdr="$HOME/Documents/to/rls"

## list of files to use for tyler
ltyler=(
    "$rlsdr/rls_A.md"
    "$rlsdr/rls_General.md"
    "$rlsdr/rls_Inspiration.md"
    "$rlsdr/rls_Technical.md"
)

## list of files to use for sagan
lsagan=(
    "$rlsdr/rls_General.md"
)

## select a random message from files
show() {
    cat $* | grep "##" | sed 's/^[ ]*##[ ]*//' | shuf -n1 -
}


## choose message for all cases
message="$(show "${lsagan[@]}" | fold -s -w $WIDTH)"

## choose based on host
[[ $(hostname) == "tyler" ]] && message="$(show "${ltyler[@]}" | fold -s -w $WIDTH)"

## get the number of lines we have to perpend in order to hit bottom
elines="$((NLINE - $(echo "$message" | wc -l)))"

## show on stout
# echo "$message"

## input file for conky
(
    for ii in $(seq 1 $elines);do
        printf " \n"
    done
    echo "$message"
) > "$OUTPTFILE"


exit 0
