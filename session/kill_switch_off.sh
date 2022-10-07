#!/bin/bash
## created on 2017-05-25

#### Remove kill switches

KILLDIR="/dev/shm/KILL_SWITCH/"

## check if any lock exist
if [[ $(find "$KILLDIR" -type f | wc -l) -le 0 ]]; then
    echo
    echo "There are no KILL files."
    echo
    exit 0
fi

## ask for each lock
for afile in "$KILLDIR"*; do
    echo "" ; input=0
    echo    "LOCK         : $(basename "$afile") "
    echo -n "remove (y/n)?: "
    read -n 1 input
    if [ "$input" == "y" -o "$input" == "Y" ] ; then
        echo
        rm -v "$afile"
    fi
done

echo
echo "FINISH"
echo
exit 0
