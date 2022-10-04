#!/bin/bash
## created on 2017-05-25

#### Example of a kill switch use in bash script

## kill switch block
#####################################################################
killfile="/dev/shm/KILL_SWITCH/$(basename "$0")"
[[ -f "$killfile" ]] && echo && echo "KILL SWITCH: $killfile !!!" && exit 999
#####################################################################

echo
echo "I CAN RUN FREE"
echo

