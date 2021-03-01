#!/bin/bash

#### Executioner of uvspec worker

## test this script
## this script dont to like to be killed ctr+c
## use 'killall paraleltest.sh' to kill it
## or any other method

# find "/home/folder/natsisa/LibRadTranM/clear_H2O_LAP/DATA" -type f -iname "*.inp" | \
#     parallel --eta \
#              parallel_x.sh {} {.}
#
#
# exit


seq -w 1 20 | parallel --eta --progress   parallel_w.sh {}

# echo $(seq 1 20) | parallel   parallel_w.sh {}

exit

function a_lib_run {
      #### put uvspec execution inside these parenthesis
      RR=$((RANDOM%20+1))
      sleep $RR
      printf " run: %3s   slept: %3s \n" $counter $RR;
      #### uvspec end
}

export -f a_lib_run


for counter in $(seq 1 20) ; do  ## change this loop with your list loop
    echo $counter
done | parallel -j 4 -- a_lib_run '{1}'



exit 0
