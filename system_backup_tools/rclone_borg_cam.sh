#!/bin/bash

####  Uploads borg  CAME  backup to multiple gmail accounts with rclone

## profil
PNAME="CAME"
Pname="came"


## allow only one instance
LOCK_FILE="/dev/shm/rclone_borg_$PNAME.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9  ; then
    echo "another instance is running";
    exit 99
fi


## ignore errors
set +e
## start watchdog
# PID=$$
# (sleep $((60*60*24)) && info "Timeout!!"  && kill "$PID") &
# watchdogpid=$!
## always kill watchdog and lock if this script ends
cleanup() {
(
    set +e
    info " ... clean up trap ... "
    info "Total status:$fstatus"
    info "All status-1:${stats[@]:1}"
    rm -fvr "$TEMP_FOLDER"
    rm -fv  "$LOCK_FILE"
    scriptpt="$(basename "${0}")"
    # pgrep -l -f ".*${scriptpt%.*}.*"
    pkill -9 -e ".*${scriptpt%.*}.*"
) >> "$LOG_FILE"
}

trap 'echo $( date )  $0 interrupted >&2;' INT TERM
trap cleanup 0 1 2 3 6 8 14 15

##-------------------------##
##   logging definitions   ##
##-------------------------##

ldir="$HOME/LOGs/SYSTEM_LOGS/"
mkdir -p "$ldir"

ID="$1"
: "${ID:=$(hostname)}"
SCRIPT="$(basename "$0")"

fsta="${ldir}/$(basename "$0")_$ID.status"
info()   { echo "$(date +'%F %T') ::INF::${SCRIPT}::${ID}:: $* ::" | tee -a "$fsta"; }
status() { echo "$(date +'%F %T') ::STA::${SCRIPT}::${ID}:: $* ::" | tee -a "$fsta"; }

info "script started"

## set variables according to host

## this actually uploads
if [[ $(hostname) == "blue" ]]; then
    BORG_FOLDER="/media/free/.BORGbackup/crane_$PNAME"
    RCLONE_ROOT="/media/free/.BORGbackup"
fi
## the rest are for monitoring with dry run
if [[ $(hostname) == "crane" ]]; then
    BORG_FOLDER="/media/free/.BORGbackup/crane_$PNAME"
    RCLONE_ROOT="/media/free/.BORGbackup"
fi
if [[ $(hostname) == "kostas" ]]; then
    BORG_FOLDER="/media/stor/borg/crane_$PNAME"
    RCLONE_ROOT="/media/stor/borg"
fi
if [[ $(hostname) == "sagan" ]]; then
    BORG_FOLDER="/home/folder/BORG/crane_$PNAME"
    RCLONE_ROOT="/home/folder/BORG"
fi

## variables for all hosts
TEMP_FOLDER="/dev/shm/borg_to_rclone_$PNAME"
RCLONE="$HOME/PROGRAMS/rclone"
RCLONE_CONFIG="$HOME/Documents/rclone.conf"
LOG_FILE="/tmp/$(basename "$0")_$(date +%F_%R).log"
ERR_FILE="/tmp/$(basename "$0")_$(date +%F_%R).err"
DIR_PREF="rclone_storage"


## start log files
exec  > >(tee -i "$LOG_FILE")
exec 2> >(tee -i "$ERR_FILE")

## set the size for each account
breakin=$(( 14850 * 1048576 ))

## set the bandwidth limit
BWLIM=${1:-50}
BWLIM_K=${1:-50}

## list of configured accounts to iterate
## an empty element for array for 1
drive=( "" $("$RCLONE" --config "$RCLONE_CONFIG" listremotes | grep "^c[0-9][0-9]_") )
MAX_ACCOUNTS=$(( ${#drive[@]} - 1 ))

## list of status output for each account
declare -a stats=( 0 $(for i in $(seq 1 $MAX_ACCOUNTS ); do echo 1; done) )

printf "%0.s-" {1..50}; echo
echo   " This will upload the backup from:"
echo   "                      $BORG_FOLDER "
echo   " To $((MAX_ACCOUNTS)) google accounts: "
printf "                      %s \n" "${drive[@]}"
printf "%0.s-" {1..50}; echo
echo   ""

## _ MAIN _ ##

## output folder
rm    -rf "$TEMP_FOLDER"
mkdir -p  "$TEMP_FOLDER"

## copy borg exec to archive
cp "$(which "borg")" "$BORG_FOLDER"

## create a list of all files present in the borg archive
find "$BORG_FOLDER" | sort -V > "$BORG_FOLDER/filelist.lst"


##---------------------------------------------------------##
##   break borg archive to lists of files with set size    ##
##---------------------------------------------------------##

sum=0
list=1
find "$BORG_FOLDER" -type f -printf "%s %p\n" | sort -t' ' -k2 -V | while read line; do
    asize="$(echo "$line" | sed 's/ .*//')"
    afile="$(echo "$line" | sed 's/^[0-9]\+ //')"
    sum=$((sum+asize))

        if [[ $sum -ge $breakin ]]; then
            listname=$(printf "file_list_%02d" "$list")
            echo "${listname}"
            echo "$sum bytes"
            echo $sum | awk '{ byte =$1 /1024/1024/1024; print byte " GB" }'
            sum=0
            list=$((list+1))
        fi

    listname=$(printf "file_list_%02d" "$list")

#     echo $asize $afile $sum $list $listname
    echo "$afile" >> "${TEMP_FOLDER}/${listname}"

done


## fix relative paths for rclone
find ${TEMP_FOLDER} -type f -iname "file_list_*" | sort | while read line; do
    sed -i 's,'"$RCLONE_ROOT"',,g' "$line"
    echo "Made $line paths relative"
done

## warn when data are going to spill out of available accounts
oversized="$(find ${TEMP_FOLDER} -type f -iname "file_list_*" | wc -l)"
if [[ $oversized -gt $MAX_ACCOUNTS ]]; then
    notify-send -u critical "rclone $PNAME has gone oversize" "have to configure new gmail account for the extra data"
fi



##--------------------------------------------##
##   use rclone to upload files to gdrives    ##
##--------------------------------------------##

## common rclone options
otheropt=" --checkers=20 --delete-before --delete-excluded --stats=60s --progress --drive-use-trash=false "
bwlimit="  --bwlimit=${BWLIM_K}k"

if [[ $(hostname) != "blue" ]]; then
    echo ""
    echo " *** NOT BLUE, WILL DO A DRY-RUN!! *** "
    echo ""
    otheropt=" --checkers=20 --delete-before --delete-excluded --stats=60s --progress --dry-run "
    bwlimit="  --bwlimit=${BWLIM}k"
fi

info "rclone started"

for ii in $(seq 1 "$MAX_ACCOUNTS"); do
    ## numeric index
    jj=$ii
    ## padded index
    ii="$(printf %02d "$ii")"

    info "Start  $jj / $MAX_ACCOUNTS  ${drive[$jj]}:/$DIR_PREF  $bwlimit"

    [[ ! -f "${TEMP_FOLDER}/file_list_$ii" ]] && echo " * No list to do ! * " && stats["$jj"]=0 && continue

    ## dedupe
    ${RCLONE}         --stats=0 --config "$RCLONE_CONFIG"  dedupe newest "${drive[$jj]}"

    ## empty trash
    ${RCLONE}         --stats=0 --config "$RCLONE_CONFIG"  cleanup       "${drive[$jj]}"

    ## sync
    drivelogfl="/dev/shm/rc_${PNAME}_borg_${ii}.log"
    echo "Start" > "$drivelogfl"
    "$RCLONE" ${otheropt} ${bwlimit} --config       "$RCLONE_CONFIG"                \
                                     --include-from "${TEMP_FOLDER}/file_list_$ii"  \
                                     --log-file     "$drivelogfl"                   \
                                     sync "$RCLONE_ROOT" "${drive[$jj]}/$DIR_PREF"
    stats["$jj"]=$?
    status "Drive:${jj}  Status:${stats[$jj]}  Drive:${drive[$jj]}"
    echo "---------------------------------------------------------"
done


## check output status for all drives
fstatus=$(IFS=+; echo "$((${stats[*]}))")
info "Total status:$fstatus"
info "All status-1:${stats[@]:1}"
if [[ $fstatus -eq 0 ]]; then
    echo ""
    echo "******* SUCCESSFUL UPLOAD  (rclone home) ********"
    echo ""
    echo "$(date +"%F %R:%S") $fstatus SUCCESSFUL UPLOAD (rclone $PNAME) ${0}"
    status "Success $fstatus"
    status "${stats[@]}"
else
    echo ""
    echo "******* UPLOAD NOT SUCCESSFUL (rclone home) ********"
    echo ""
    echo "$(date +"%F %R:%S") ${stats[*]} UPLOAD FAILED (rclone $PNAME) ${0}"
    status "Fail  $fstatus"
    status "${stats[@]}"
fi



##-----------------------------------------------##
##   report on used capacity for each account    ##
##-----------------------------------------------##

TOTAL=0
USED=0
FREE=0
TRASH=0
OTHER=0
FOLDR=0
WASTE=0

for ii in $(seq 1 "$MAX_ACCOUNTS"); do
    ## padded
    jj=$(printf %02d "$ii")

    echo " $ii/$MAX_ACCOUNTS  ${drive[$ii]}/$DIR_PREF "

    ## info on the gdrive account
    rinfo=$(${RCLONE} --stats=0 --config "$RCLONE_CONFIG"  about  "${drive[$ii]}/"          )

    ## info for the backup storage folder
    rdire=$(${RCLONE} --stats=0 --config "$RCLONE_CONFIG"  size   "${drive[$ii]}/$DIR_PREF" )

    echo "$rinfo"
    echo "$rdire"
    echo ""

    ## capture sizes from accounts
    stotal=$(echo "$rinfo" | grep "Total"   | grep -o "[.0-9]\+[ ]*[KkMmGgTt]" | sed -e 's/[Kk]/\*1024/g' -e 's/[Mm]/\*1024*1024/g' -e 's/[Gg]/\*1024*1024*1024/g' | bc)
    sused=$( echo "$rinfo" | grep "Used"    | grep -o "[.0-9]\+[ ]*[KkMmGgTt]" | sed -e 's/[Kk]/\*1024/g' -e 's/[Mm]/\*1024*1024/g' -e 's/[Gg]/\*1024*1024*1024/g' | bc)
    sfree=$( echo "$rinfo" | grep "Free"    | grep -o "[.0-9]\+[ ]*[KkMmGgTt]" | sed -e 's/[Kk]/\*1024/g' -e 's/[Mm]/\*1024*1024/g' -e 's/[Gg]/\*1024*1024*1024/g' | bc)
    strash=$(echo "$rinfo" | grep "Trashed" | grep -o "[.0-9]\+[ ]*[KkMmGgTt]" | sed -e 's/[Kk]/\*1024/g' -e 's/[Mm]/\*1024*1024/g' -e 's/[Gg]/\*1024*1024*1024/g' | bc)
    sother=$(echo "$rinfo" | grep "Other"   | grep -o "[.0-9]\+[ ]*[KkMmGgTt]" | sed -e 's/[Kk]/\*1024/g' -e 's/[Mm]/\*1024*1024/g' -e 's/[Gg]/\*1024*1024*1024/g' | bc)
    ## capture size of folders
    folde=$(echo "$rdire" | grep -o "([0-9]\+ Bytes)" | grep -o "[.0-9]\+")

    ## set empty to zero
    stotal=${stotal:-0}
    sused=${sused:-0}
    sfree=${sfree:-0}
    strash=${strash:-0}
    sother=${sother:-0}
    folde=${folde:-0}

    ## we ignore fractional bytes
    TOTAL=$(( TOTAL + ${stotal%.*} ))
    USED=$((  USED  + ${sused%.*}  ))
    TRASH=$(( TRASH + ${strash%.*} ))
    OTHER=$(( OTHER + ${sother%.*} ))
    FOLDR=$(( FOLDR + folde ))

    ## we only want the free size after any incomplete account
    if [[ "$ii" -ge "$oversized" ]]; then
        FREE=$((  FREE  + ${sfree%.*} ))
    else
        WASTE=$(( WASTE + ${sfree%.*} ))
    fi

done


bytesToHuman() {
    b=${1:-0}; d=''; s=0; S=("      B" {K,M,G,T,P,E,Z,Y}iB)
    while ((b > 1024)); do
        d="$(printf ".%03d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        (( s++ ))
    done
#     echo   "$b$d ${S[$s]}"
    printf "%5s%s %s" "$b" "$d" "${S[$s]}"
}


status "TOTAL:        $(bytesToHuman $TOTAL)"
status "USED:         $(bytesToHuman $USED)"
status "FREE:         $(bytesToHuman $FREE)"
status "WASTE:        $(bytesToHuman $WASTE)"
status "TRASH:        $(bytesToHuman $TRASH)"
status "OTHER:        $(bytesToHuman $OTHER)"
status "FOLDERS:      $(bytesToHuman $FOLDR)"
status "AVAIL ACCNTS: $((MAX_ACCOUNTS))"
status "USED  ACCNTS: $oversized"


# echo "  TOTAL  $TOTAL" | numfmt --to=iec-i --field=2 --padding=10 --invalid=ignore --format "%10f"



##------------------------------------##
##   clear an account to be reused    ##
##------------------------------------##

otheropt=" --delete-before --delete-excluded --drive-use-trash=false"

# ${RCLONE} --config "$RCLONE_CONFIG" ${otheropt} purge   "skts01:/hde_1"
# ${RCLONE} --config "$RCLONE_CONFIG" ${otheropt} cleanup "skts01:/"

# kill "$watchdogpid"
info "Script ends here"
exit 0
