#!/bin/bash
## created on 2022-12-27

#### An execution lock mechanism based on how old a check file is

## variables
timelimit="$((3600*8))"
timefile="/tmp/.$(basename "$0").timecheck"

## checks
if [[ -f "$timefile" ]]; then
    echo "Existing $timefile"
    filesec="$(date -r "$timefile" +"%s")"
    timesec="$(date +"%s")"
    # echo $filesec $timesec
    diffsec="$((timesec - filesec))"
    if [[ $timelimit -gt $diffsec ]]; then
        echo
        echo "Will not run now!"
        # echo "$diffsec" 
        printf 'Oldness %02d:%02d:%02d\n' $((diffsec/3600)) $((diffsec%3600/60)) $((diffsec%60))
        echo
        exit
    fi
fi

## issue lock
echo
echo  "Issue new timestamp file $timefile"
touch "$timefile"
echo

exit 0 
