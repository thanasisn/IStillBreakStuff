#!/bin/bash

####  Simple worker to run one instance of uvspec with defined input and output files

## remove this delay
sleep $((RANDOM%10+1))

## this is just a print
echo "uvspec ${1}.inp ${2}.out"

## this is an execution
# uvspec ${1}.inp ${2}.out

