#!/bin/bash

#### Worker to run one instance of uvspec

#### put uvspec execution inside 

## example code
RR=$((RANDOM%10+1))
sleep $RR

printf " run: %3s   slept: %3s \n" $1 $RR;
#### uvspec end

exit

