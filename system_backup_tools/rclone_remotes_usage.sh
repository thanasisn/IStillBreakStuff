#!/bin/bash

#### Report on storage usage of rclone remotes
## accept a grep pattern to match rclone remotes

remotespattern="${1:-.*}"
echo "Remotes pattern:  $remotespattern"

## allow only one instance
LOCK_FILE="/dev/shm/$(basename "${0}").lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9  ; then
    echo "another instance is running";
    exit 99
fi

## ignore errors
set +e

## always kill watchdog and lock if this script ends
## hope we don't unlock when we shouldn't
cleanup() {
    rm -f "$LOCK_FILE"
    kill -9 "$watchdogpid"
}

trap 'echo $( date )  $0 interrupted >&2;' INT TERM
trap cleanup 0 1 2 3 6

##-------------------------##
##   logging definitions   ##
##-------------------------##

ldir="$HOME/LOGs/SYSTEM_LOGS/"
mkdir -p "$ldir"

ID="$1"
: "${ID:=$(hostname)}"
SCRIPT="$(basename "$0")"

fsta="${ldir}/$(basename "$0").log"
info()   { echo -e "$(date +'%F %T') ::INF::${SCRIPT}::${ID}:: $* ::" | tee -a "$fsta"; }
status() { echo -e "$(date +'%F %T') ::STA::${SCRIPT}::${ID}:: $* ::" | tee -a "$fsta"; }

mainpid=$$
(sleep $((60*60*30)) && info "Timeout!!"  && kill -9 $mainpid) &
watchdogpid=$!

info "script started"

## variables for all hosts
RCLONE="$HOME/PROGRAMS/rclone"
RCLONE_CONFIG="$HOME/Documents/rclone.conf"
LOG_FILE="/tmp/$(basename "$0")_$(date +%F_%R).log"
ERR_FILE="/tmp/$(basename "$0")_$(date +%F_%R).err"

exec  > >(tee -i "$LOG_FILE")
exec 2> >(tee -i "$ERR_FILE")

## get a list of remotes to check
remotes=( $( "$RCLONE" --config  "$RCLONE_CONFIG"  listremotes | grep "$remotespattern" ) )

total=${#remotes[@]}

if [[ $total -lt 1 ]]; then
    echo "No remotes selected!!"
    echo "${remotes[@]}"
    echo "EXIT"
    exit
fi

echo "----------------------------"
printf "  %s \n" "${remotes[@]}"
echo "----------------------------"


##------------------------------------##
##   report on usage of each remote   ##
##------------------------------------##
TOTAL=0
USED=0
FREE=0
TRASH=0
OTHER=0
FOLDR=0
WASTE=0

for (( ii=0; ii<total; ii++ )); do
    echo ""

    ## get info of the remote
    rinfo=$(${RCLONE} --stats=0 --config "$RCLONE_CONFIG"  about         "${remotes[$ii]}/" )
    ## info for the backup storage folder
    rdire=$(${RCLONE} --stats=0 --config "$RCLONE_CONFIG"  size          "${remotes[$ii]}/" )

    ## display as it runs
    mes="\n"
    mes+="=====  $((ii+1)) / $total  ${remotes[$ii]}  ==================\n"
    mes+="$rinfo\n"
    mes+="$rdire\n"
    info "$mes"

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
    FREE=$((  FREE  + ${sfree%.*}  ))
    TRASH=$(( TRASH + ${strash%.*} ))
    OTHER=$(( OTHER + ${sother%.*} ))
    FOLDR=$(( FOLDR + folde ))
done


bytesToHuman() {
    b=${1:-0}; d=''; s=0; S=("      B" {K,M,G,T,P,E,Z,Y}iB)
    while ((b > 1024)); do
        d="$(printf ".%03d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        (( s++ ))
    done
    printf "%5s%s %s" "$b" "$d" "${S[$s]}"
}

## display summary
echo ""
echo "---------------------------"
status "TOTAL:   $(bytesToHuman $TOTAL)"
status "USED:    $(bytesToHuman $USED)"
status "FREE:    $(bytesToHuman $FREE)"
status "WASTE:   $(bytesToHuman $WASTE)"
status "TRASH:   $(bytesToHuman $TRASH)"
status "OTHER:   $(bytesToHuman $OTHER)"
echo "---------------------------"
status "FOLDERS: $(bytesToHuman $FOLDR)"
status "PARSED ACCOUNTS: $total"
echo "---------------------------"
echo ""

## send to telegram
$HOME/CODE/system_tools/telegram_status.sh "$(hostname) rclone storage $remotespattern" \
"
TOTAL:   $(bytesToHuman $TOTAL)
USED:    $(bytesToHuman $USED)
FREE:    $(bytesToHuman $FREE)
WASTE:   $(bytesToHuman $WASTE)
TRASH:   $(bytesToHuman $TRASH)
OTHER:   $(bytesToHuman $OTHER)
---------------------------
FOLDERS: $(bytesToHuman $FOLDR)
PARSED ACCOUNTS: $total
---------------------------"

kill "$watchdogpid"
exit 0
