#!/bin/bash

####  Uploads borg  CAME  backup to multiple gmail accounts with rclone

## profil
PNAME="CAME"
remotespattern="^c[0-9][0-9]_"

## allow only one instance
LOCK_FILE="/dev/shm/rclone_borg_$PNAME.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9  ; then
    echo "another instance is running";
    exit 9
fi

if [[ $(hostname) != "blue" ]]; then
    echo "This script should run only on blue"
    exit
fi


## ignore errors
set +e
## start watchdog to kill self kill after long time
# PID=$$
# (sleep $((60*60*24)) && info "Timeout!!"  && kill "$PID") &
# watchdogpid=$!
## always kill watchdog and lock if this script ends
cleanup() {
(
  set +e
  info " ... clean up trap ... "
  fstatus=$(IFS=+; echo "$((${stats[*]}))")
  Astatus="${stats[*]:1}"
  info "End status: $fstatus"
  info "All status: $Astatus"
  /home/athan/CODE/system_tools/telegram_status.sh "$(hostname) rclone $PNAME" "Bad: $fstatus  Per Account: $Astatus"
  rm -fvr "$TEMP_FOLDER"
  rm -fv  "$LOCK_FILE"
  scriptpt="$(basename "${0}")"
  # pgrep -l -f ".*${scriptpt%.*}.*"
  pkill -9 -e ".*${scriptpt%.*}.*"
) >> "$LOG_FILE"
}

trap 'echo $( date )  $0 interrupted >&2;' INT TERM
trap cleanup 0 1 2 3 6 8 14 15

## logging definitions  --------------------------------------------------------

ldir="/home/athan/LOGs/SYSTEM_LOGS/"
mkdir -p "$ldir"

ID="$1"
: "${ID:=$(hostname)}"
SCRIPT="$(basename "$0")"

fsta="${ldir}/$(basename "$0")_$ID.status"
info()   { echo "$(date +'%F %T') ::INF::${SCRIPT}::${ID}:: $* ::" | tee -a "$fsta";}
status() { echo "$(date +'%F %T') ::STA::${SCRIPT}::${ID}:: $* ::" | tee -a "$fsta";}

info "script started"

## Get telegram credentials  ---------------------------------------------------

if [ -f ~/.ssh/telegram/unikey_$(hostname) ]; then
    . ~/.ssh/telegram/unikey_$(hostname)
  else
    . ~/.ssh/telegram/unikey_hosts
fi

## set upload variables

BORG_FOLDER="/media/free/.BORGbackup/crane_$PNAME"
RCLONE_ROOT="/media/free/.BORGbackup"
TEMP_FOLDER="/dev/shm/borg_to_rclone_$PNAME"
RCLONE="/home/athan/PROGRAMS/rclone"
RCLONE_CONFIG="/home/athan/Documents/rclone.conf"
LOG_FILE="/tmp/$(basename "$0")_$(date +%F_%R).log"
ERR_FILE="/tmp/$(basename "$0")_$(date +%F_%R).err"
DIR_PREF="rclone_storage"
REPORT_SCRIPT="/home/athan/CODE/system_backup_tools/rclone_remotes_usage.sh"

## start log files
exec  > >(tee -i "$LOG_FILE")
exec 2> >(tee -i "$ERR_FILE")

## set the size for each account
breakin=$(( 14840 * 1048576 ))

## set the bandwidth limit
BWLIM=${1:-60}
BWLIM_K=${1:-60}

## list of configured accounts to iterate
## an empty element for array for 1
drive=( "" $("$RCLONE" --config "$RCLONE_CONFIG" listremotes | grep "$remotespattern") )
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


## _ MAIN _  -------------------------------------------------------------------

## prepare output folder
rm    -rf "$TEMP_FOLDER"
mkdir -p  "$TEMP_FOLDER"

## create a list of all files present in the borg archive
find "$BORG_FOLDER" | sort -V > "$BORG_FOLDER/filelist.lst"


##  break borg repo to lists of files with set size  ---------------------------

sum=0
list=1
find "$BORG_FOLDER" -type f -printf "%s %p\n" | sort -t' ' -k2 -V | while read line; do
  asize="$(echo "$line" | sed 's/ .*//')"
  afile="$(echo "$line" | sed 's/^[0-9]\+ //')"
  sum=$((sum+asize))
  ## count cumulative size and break
  if [[ $sum -ge $breakin ]]; then
    listname=$(printf "file_list_%02d" "$list")
    echo "${listname}"
    echo "$sum bytes"
    echo $sum | awk '{ byte =$1 /1024/1024/1024; print byte " GB" }'
    sum=0
    list=$((list+1))
  fi
  ## name of the current list
  listname=$(printf "file_list_%02d" "$list")
  ## add file in current list
  echo "$afile" >> "${TEMP_FOLDER}/${listname}"
done
info "$list lists created"

## fix relative paths for rclone
find ${TEMP_FOLDER} -type f -iname "file_list_*" | sort | while read line; do
  sed -i 's,'"$RCLONE_ROOT"',,g' "$line"
  echo "Made $line paths relative"
done

## warn when data are going to spill out of available accounts
## TODO use the global notify system
oversized="$(find ${TEMP_FOLDER} -type f -iname "file_list_*" | wc -l)"
if [[ $oversized -gt $MAX_ACCOUNTS ]]; then
  /home/athan/CODE/system_tools/telegram_status.sh "!! rclone $PNAME has gone oversize" "have to configure new gmail account for the extra data"
  notify-send -u critical "rclone $PNAME has gone oversize" "have to configure new gmail account for the extra data"
fi


##  use rclone to upload files to gdrives  ------------------------------------

## common rclone options
otheropt=" --checkers=20 --delete-before --delete-excluded --stats=60s --progress --drive-use-trash=false --transfers=1 "
bwlimit="  --bwlimit=${BWLIM_K}k"

info "rclone started"

for ii in $(seq 1 "$MAX_ACCOUNTS"); do
  ## numeric index
  jj=$ii
  ## zero padded index
  ii="$(printf %02d "$ii")"
  info "Start  $jj / $MAX_ACCOUNTS  ${drive[$jj]}:/$DIR_PREF"
  ## work on list of actual data
  [[ ! -f "${TEMP_FOLDER}/file_list_$ii" ]] && echo " * No list to do ! * " && stats["$jj"]=0 && continue
  ## dedupe remote
  ${RCLONE}         --stats=0 --config "$RCLONE_CONFIG"  dedupe newest "${drive[$jj]}"
  ## empty trash in remote
  ${RCLONE}         --stats=0 --config "$RCLONE_CONFIG"  cleanup       "${drive[$jj]}"
  ## sync to remote!
  drivelogfl="/dev/shm/rc_${PNAME}_borg_${ii}.log"
  echo "Start" > "$drivelogfl"
  "$RCLONE" ${otheropt} ${bwlimit} --config       "$RCLONE_CONFIG"                \
                                   --include-from "${TEMP_FOLDER}/file_list_$ii"  \
                                   --log-file     "$drivelogfl"                   \
                                   --stats        "10m"                           \
                                   sync "$RCLONE_ROOT" "${drive[$jj]}/$DIR_PREF"
  stats["$jj"]=$?
  # /home/athan/CODE/system_tools/telegram_status.sh "rclone $PNAME" "Drive:${jj}  Status:${stats[$jj]}  Drive:${drive[$jj]}"
  mes="rclone $PNAME
  Drive:${jj}  Status:${stats[$jj]}  Drive:${drive[$jj]}"
  curl -s -X POST                                             \
    "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_ID"                                 \
    -d text="$mes"
  status "Drive:${jj}  Status:${stats[$jj]}  Drive:${drive[$jj]}"
  echo "-----------------------------------------------------------------"
done


##  check output status for all drives  -----------------------------------------

fstatus=$(IFS=+; echo "$((${stats[*]}))")
if [[ $fstatus -eq 0 ]]; then
  echo ""
  echo "******* SUCCESSFUL UPLOAD  (rclone $PNAME) ********"
  echo "$(date +"%F %R:%S") $fstatus SUCCESSFUL UPLOAD (rclone $PNAME) ${0}"
  status "Success $fstatus"
  /home/athan/CODE/system_tools/telegram_status.sh "$(hostname) rclone $PNAME" "$fstatus SUCCESSFUL UPLOAD (rclone $PNAME) ${0}"
else
  echo ""
  echo "******* UPLOAD NOT SUCCESSFUL (rclone $PNAME) ********"
  echo "$(date +"%F %R:%S") ${stats[*]} UPLOAD FAILED (rclone $PNAME) ${0}"
  status "Fail  $fstatus"
  /home/athan/CODE/system_tools/telegram_status.sh "$(hostname) rclone $PNAME" "${stats[*]} UPLOAD FAILED (rclone $PNAME) ${0}"
fi

info "All status:${stats[*]:1}"
echo ""


##  report on used capacity for each account  ----------------------------------

echo "run: $REPORT_SCRIPT" "$remotespattern"
"$REPORT_SCRIPT" "$remotespattern"


##  clear an account to be reused  ---------------------------------------------

# otheropt=" --delete-before --delete-excluded --drive-use-trash=false"
# ${RCLONE} --config "$RCLONE_CONFIG" ${otheropt} purge   "skts01:/hde_1"
# ${RCLONE} --config "$RCLONE_CONFIG" ${otheropt} cleanup "skts01:/"

# kill "$watchdogpid"
# cleanup
info "Script ends here"
exit 0
