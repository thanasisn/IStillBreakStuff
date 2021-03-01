#!/bin/bash
## 2017-03-10

#### Executioner of uvspec worker
## this is used to run multiple script instances


## this runs a uvspec
WORKER_sh="uvspec_worker_v1.sh"

## I/O folders
INPDIR="/path/to/files/for/INPUT/"
OUTDIR="/path/to/files/for/OUTPUT/"
ERRDIR="/path/to/files/for/error/"

## This may make people un-friend you
cores=8

## DELETE THIS VARIABLE
INPDIR="$HOME/LibRadTranM/clear_H2O_LAP/DATA"

## initial files count
total="$(find "${INPDIR}" -type f -iname "*.inp" | wc -l)"

## ask to continue
echo "" ; input=0
echo -n "Found $total input files continue  (y/n)?: "
read -n 1 input ; echo
if [ "$input" == "y" -o "$input" == "Y" ] ; then
    printf ""
else
    echo "exit now.."; exit 2
fi

## set some variables
Tic="$(date +%s%N)"    ## keep time
Tac="$(date +"%F %T")" ## keep time
cntt=0


#### THIS IS THE PARALLEL TRICK ####
## run all input files through the WORKER_sh
find "${INPDIR}" -type f -iname "*.inp" | while read line;do
    echo "$line" "$((++cntt))"
done | xargs -n 2 "$WORKER_sh" "${OUTDIR}" "${ERRDIR}" "$total" "$Tic"


## you are done, end report
T="$(($(date +%s%N)-Tic))"
S="$((T/1000000000))"
M="$((T%1000000000/1000000))"
echo ""
echo "    ____UVSPEC_runs_finished____"
printf "DONE in:        %02d %02d:%02d:%02d.%03d <\n" "$((S/86400))" "$((S/3600%24))" "$((S/60%60))" "$((S%60))" "${M}"
echo "From  : $Tac"
echo "Until : $(date +"%F %T")"

exit 0
