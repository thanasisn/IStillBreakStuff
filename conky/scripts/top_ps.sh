#!/bin/bash


exec 9>"/dev/shm/$(basename $0).lock"
if ! flock -n 9  ; then
    echo "another instance is running";
    exit 1
fi

## max lines to output
lines=${1:-50}
## rate of execustion
rate=${2:-10}

mkdir -p "/dev/shm/CONKY"
OUTPUT="/dev/shm/CONKY/top.dat"
LOGPS="/dev/shm/CONKY/logps.dat"

# printf "epoch\tPS\taPS\tTasks\n" > "$LOGPS"

while true; do
    
    ## create of procceses for conky display
    (echo "cpu mem user ctime cmd"
    /bin/ps -eo pcpu,pmem,user,time,comm                   |\
        sed '1d'                                           |\
        awk '{c=0;for(i=1;i<=2;++i){c+=$i};print  c, $0 }' |\
        sort -gr | sed 's/^[.0-9]\+ //' | head -n "$lines"       ) | column -c 5 -t > "$OUTPUT"


    printf "%s\t%s\t%s\t%s\n" "$(date +"%s")"\
                              "$(ps -e | wc -l)" "$(ps -U athan -u athan u | wc -l)"\
                              "$(ps axjf | grep --invert-match '^[ ]*2 ' | wc --lines)" >> "$LOGPS" 

    sleep "$rate"

done

