#!/bin/bash

#### Report on the usage of all rclone remotes


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
    echo "CLEANING UP"
    rm -rf "$TEMP_FOLDER"
    rm -f "$LOCK_FILE"
    # pkill rclone
    pkill -9 -e ".*rclone.*"
    kill -9 "$watchdogpid"
}

trap 'echo $( date )  $0 interrupted >&2;' INT TERM
trap cleanup 0 1 2 3 6

##-------------------------##
##   logging definitions   ##
##-------------------------##

ldir="/home/athan/LOGs/SYSTEM_LOGS/"
mkdir -p "$ldir"

ID="$1"
: ${ID:=$(hostname)}
SCRIPT="$(basename "$0")"

fsta="${ldir}/$(basename "$0").log"
info()   { echo -e "$(date +'%F %T') ::INF::${SCRIPT}::${ID}::  $*" >>"$fsta"; }
status() { echo -e "$(date +'%F %T') ::STA::${SCRIPT}::${ID}::  $*" >>"$fsta"; }

mainpid=$$
(sleep $((60*60*30)) && info "Timeout!!"  && kill -9 $mainpid) &
watchdogpid=$!

info "script started"

## variables for all hosts
TEMP_FOLDER="/dev/shm/borg_to_rclone_hom"
RCLONE="$HOME/PROGRAMS/rclone"
RCLONE_CONFIG="$HOME/Documents/rclone.conf"
LOG_FILE="/tmp/$(basename $0)_$(date +%F_%R).log"
ERR_FILE="/tmp/$(basename $0)_$(date +%F_%R).err"


exec  > >(tee -i "$LOG_FILE")
exec 2> >(tee -i "$ERR_FILE")


remotes=( $( "$RCLONE" --config  "$RCLONE_CONFIG"  listremotes ) )
total=${#remotes[@]}


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
    echo "  ===  $((ii+1)) / $total  ${remotes[$ii]}  === " ;

#     ## do a dedupe
#     ${RCLONE}         --stats=0 --config "$RCLONE_CONFIG"  dedupe newest "${remotes[$ii]}"
#     ## do empty trash
#     ${RCLONE}         --stats=0 --config "$RCLONE_CONFIG"  cleanup       "${remotes[$ii]}"

    ## info on the gdrive account
    rinfo=$(${RCLONE} --stats=0 --config "$RCLONE_CONFIG"  about         "${remotes[$ii]}/" )
    ## info for the backup storage folder
    rdire=$(${RCLONE} --stats=0 --config "$RCLONE_CONFIG"  size          "${remotes[$ii]}/" )

    ## display as it runs
    echo "$rinfo"
    echo "$rdire"
    mes="\n"
    mes+="--- ${remotes[$ii]} ---\n"
    mes+="$rinfo\n"
    mes+="$rdire\n"
    info "$mes"

    ## capture sizes from accounts
    stotal=$(echo "$rinfo" | grep "Total"   | grep -o "[.0-9]\+[KkMmGgTt]" | sed -e 's/[Kk]/\*1024/g' -e 's/[Mm]/\*1024*1024/g' -e 's/[Gg]/\*1024*1024*1024/g' | bc)
    sused=$( echo "$rinfo" | grep "Used"    | grep -o "[.0-9]\+[KkMmGgTt]" | sed -e 's/[Kk]/\*1024/g' -e 's/[Mm]/\*1024*1024/g' -e 's/[Gg]/\*1024*1024*1024/g' | bc)
    sfree=$( echo "$rinfo" | grep "Free"    | grep -o "[.0-9]\+[KkMmGgTt]" | sed -e 's/[Kk]/\*1024/g' -e 's/[Mm]/\*1024*1024/g' -e 's/[Gg]/\*1024*1024*1024/g' | bc)
    strash=$(echo "$rinfo" | grep "Trashed" | grep -o "[.0-9]\+[KkMmGgTt]" | sed -e 's/[Kk]/\*1024/g' -e 's/[Mm]/\*1024*1024/g' -e 's/[Gg]/\*1024*1024*1024/g' | bc)
    sother=$(echo "$rinfo" | grep "Other"   | grep -o "[.0-9]\+[KkMmGgTt]" | sed -e 's/[Kk]/\*1024/g' -e 's/[Mm]/\*1024*1024/g' -e 's/[Gg]/\*1024*1024*1024/g' | bc)
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
#     echo   "$b$d ${S[$s]}"
    printf "%5s%s %s" "$b" "$d" "${S[$s]}"
}

echo ""
echo "---------------------------"
echo "   TOTAL   $(bytesToHuman $TOTAL)"
echo "   USED    $(bytesToHuman $USED) "
echo "   FREE    $(bytesToHuman $FREE) "
echo "   WASTE   $(bytesToHuman $WASTE)"
echo "   TRASH   $(bytesToHuman $TRASH)"
echo "   OTHER   $(bytesToHuman $OTHER)"
echo "---------------------------"
echo "   FOLDERS $(bytesToHuman $FOLDR)"
echo "---------------------------"
echo ""

status "TOTAL:   $(bytesToHuman $TOTAL)"
status "USED:    $(bytesToHuman $USED)"
status "FREE:    $(bytesToHuman $FREE)"
status "WASTE:   $(bytesToHuman $WASTE)"
status "TRASH:   $(bytesToHuman $TRASH)"
status "OTHER:   $(bytesToHuman $OTHER)"
status "FOLDERS: $(bytesToHuman $FOLDR)"
status "AVAILABLE ACCOUNTS:$total"



##------------------------------------##
##   clear an account to be reused    ##
##------------------------------------##

otheropt=" --delete-before --delete-excluded --drive-use-trash=false"

# ${RCLONE} --config "$RCLONE_CONFIG" ${otheropt} purge   "skts01:/hde_1"
# ${RCLONE} --config "$RCLONE_CONFIG" ${otheropt} cleanup "skts01:/hde_1"
# ${RCLONE} --config "$RCLONE_CONFIG" ${otheropt} cleanup "skts01:/"

kill "$watchdogpid"
exit 0
