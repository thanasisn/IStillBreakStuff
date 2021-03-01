#!/bin/bash

#### Worker to run one instance of uvspec

sleep $((RANDOM%10+1))


echo "uvspec ${1}.inp ${2}.out"

