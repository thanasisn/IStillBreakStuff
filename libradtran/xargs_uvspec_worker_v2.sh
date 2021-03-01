#!/bin/bash
## 2017-03-10

#### Worker to run one instance of uvspec
## This is to be used by another script for parallel execution of uvspec

## get arguments
OUTDIR="${1}"
ERRDIR="${2}"
total="${3}"
Tic="${4}"
INPUTF="${5}"
cntt="${6}"

## file to log this run
logfile="/path/to/a/log/file/JOB_$(date +"%F").log"

## set libradtran executable path
UVSPEC="/path/to/uvspec"

## check how many arguments
if [ $# -ne 6 ] ; then  echo " 6 arguments needed" ;  exit 1 ; fi

## input base file name
fname="$(basename $INPUTF)"

## out and error file names
OUTFIL="${OUTDIR}/${fname%.*}.out"
ERRFIL="${ERRDIR}/${fname%.*}.err"

## print some info while running
TOT=$(echo "scale=1; (($cntt*100/$total))" | bc)
ETA=$(($(($((total-cntt))*$(($(date +%s%N)-Tic))/60000000000))/cntt))
printf " %5s %5s/$total %5s%%  ETA: %4s min\n" $((total-cntt))  $cntt $TOT $ETA

## keep a log of what happened
echo "$(date +"%F %T") $fname $cntt" >> "${logfile}"

## HERE PUT THE HEAVY LOAD ##

####TEST#### First try this to check
echo "( ( "${UVSPEC}" < "${INPUTF}" ) | gzip > "${OUTFIL}.gz" )  2> ${ERRFIL}"
sleep $((RANDOM%5+2))

## Then use this to run the load
# ( ( "${UVSPEC}" < "${INPUTF}" ) | gzip > "${OUTFIL}.gz" )  2> ${ERRFIL}


exit 66
