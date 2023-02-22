#!/bin/bash
## https://github.com/thanasisn <natsisphysicist@gmail.com>


#### Randomize files and folders dates
## The dates are ranged so that it will be difficult to be recognized in the system
## Although different schemes may be more appropriate

ARG=$1

if [ -z "$ARG" ]; then
    echo "Nothing to do"
    exit
fi

## get an early date of the system
filetoread="$(ls -t / | tail -n1)"
datebase="$(stat -c %Y "/$filetoread")"
## gen now date
datenow="$(date +%s)"

## mean date
## comment the others if you want closer spread
datestart=$(((datebase + datenow)/2 - 3600*($RANDOM/3600) - 24*3600*($RANDOM/3600) - 66*3600*($RANDOM/3600) ))

# date -d "@$datebase" +'%F %T'
# echo $datestart
# date -d "@$datestart" +'%F %T'

## apply inside a folder structure
if [[ -d $ARG ]]; then
    find "${ARG}" | while read alink; do
        ## mean date
        datestart=$(((datebase + datenow)/2 - 3600*($RANDOM/3600) - 24*3600*($RANDOM/3600) - 66*3600*($RANDOM/3600) ))
        ## some more pertubation
        number=$RANDOM
        let "number %= 96400"
        newdate="$((number + datestart))"

        # date -d "@$newdate"
        touch -c -d "@$newdate"  "${alink}"
    done
## or apply on file
elif [[ -f $ARG ]]; then
    ## mean date
    datestart=$(((datebase + datenow)/2 - 3600*($RANDOM/3600) - 24*3600*($RANDOM/3600) - 66*3600*($RANDOM/3600) ))
    ## some more pertubation
    number=$RANDOM
    let "number %= 96400"
    newdate="$((number + datestart))"

    touch -c -d "@$newdate"  "${ARG}"
    # date -d "@$newdate"
fi

exit 0
