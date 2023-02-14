#!/bin/bash

#### Executioner of uvspec worker

## test this script
## this script dont to like to be killed ctr+c
## use 'killall paraleltest.sh' to kill it
## or any other method

prs=0        ## counter of parallel executions
cores=8      ## number of available cores

((cores--))  ## we count from zero so we remove one
             ## maths can be done inside (( ))
             ## bash maths are always integer

for counter in $(seq 1 30) ; do  ## change this loop with your list loop

    ## run a job in a subshell
    (
      #### put uvspec execution inside these parenthesis
      # RR=$((RANDOM%5+5))
      RR=$((RANDOM%5+counter))
      printf " run: %3s   slept: %3s  prs: %3s \n" $counter $RR $prs;
      sleep $RR
      #### uvspec end
    ) &

    ## throttle execution
    if (( ++prs > cores )); then
        wait -n
        prs=$((prs-1))
        echo $prs
    fi

done

## wait for the last of the runs after the loop ends
for i in $(seq 1 $cores); do
    wait
done


exit 0
