#!/bin/bash
## created on 2021-11-08

#### Example of xargs usage in parallel

## Run 30 commands in groups of 10, using 10 cores/threads


## test parallel usage, execute each piped line

## timing the execution
time for i in {1..30}; do echo "sleep 1"; done | xargs -i -t -P 10 sh -c "{}"

## without timing
for i in {1..30}; do echo "sleep 1"; done | xargs -i -t -P 10 sh -c "{}"




## test serial usage, execute each piped line one by one

## timnig the execution
time for i in {1..30}; do echo "sleep 1"; done | xargs -i -t -P 1 sh -c "{}"

## without timing
for i in {1..30}; do echo "sleep 1"; done | xargs -i -t -P 1 sh -c "{}"



## if you have a file with the commands and the argument in one line then
cat "file_with_commands.txt" | xargs -i -t -P 10 sh -c "{}"


## if you have a folder with input files, check 'xargs_parallel_v2.sh' script


exit 0
