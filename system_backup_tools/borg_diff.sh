#!/bin/bash

#### Inspect the differece of borg snapshots within a repo

## Uses predifined profile files with variables
## Created 2018-11-06      


## executable path
BORG="$HOME/PROGRAMS/borgtest/borg-1.2.0a7"
BORG="/usr/local/bin/borg"

## requires some commands:
command -v nc    >/dev/null 2>&1 || { echo >&2 "nc NOT INSTALLED. Aborting."; exit 1; }
command -v $BORG >/dev/null 2>&1 || { echo >&2 "borg NOT INSTALLED. Aborting."; exit 1; }

##-------------------------##
##   logging definitions   ##
##-------------------------##

ldir="$HOME/LOGs/SYSTEM_LOGS/"
mkdir -p "$ldir"

ID="$1"
: ${ID:=$(hostname)}
SCRIPT="$(basename "$0")"
SCRIPT_ROOT="$(dirname $(readlink -f "$0"))"

fsta="${ldir}/$(basename "$0")_$ID.log"
info()   { echo "$(date +'%F %T') ::INF::${SCRIPT}::${ID}:: $* ::" >>"$fsta"; }
status() { echo "$(date +'%F %T') ::STA::${SCRIPT}::${ID}:: $* ::" >>"$fsta"; }


info "Script root $SCRIPT_ROOT"
##---------------------------------------------------##
##   get check prepare read the configuration file   ##
##---------------------------------------------------##

PROFILE="$1"
PROFILE="${PROFILE%.*}"
PROFILE_FOLDER="$HOME/BASH/CRON/borg_profiles"

CONF_FILE="${PROFILE_FOLDER}/${PROFILE}.conf"
CONF_SECU="${PROFILE_FOLDER}/.${PROFILE}.conf"
LOCK_FILE="/dev/shm/borg_diff_${PROFILE}.lock"

if [[ -f "$CONF_FILE" ]] ; then
    echo
    echo "Profile:   >>  ${PROFILE}  << "
else
    echo
    echo "NO PROFILE:  ---${PROFILE}---"
    echo "Use one of the following:"
    echo
    find "$PROFILE_FOLDER" -not -path "*/\.*" -iname "*.conf" -exec basename {} \; | sed 's/.conf//g'
    echo
    exit 10
fi

## allow only one instance
exec 9>"$LOCK_FILE"
if ! flock -n 9  ; then
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "Another profile is running: ${PROFILE}"
    echo "~~~~~~~~~~~~~~~~~~~ EXIT ~~~~~~~~~~~~~~~~~~~"
    exit 99
fi



## filter the original to a new file
grep -E '^#|^[^ ]* *= *[^;&]*'  "$CONF_FILE" | sed 's/ \+= \+/=/g' > "$CONF_SECU"
CONF_FILE="$CONF_SECU"

## some helpers and error handling:
info() { echo "$(date +%F_%T) -- $* ------" >&2; }
trap 'echo ; echo ; echo $( date ) Comparison for ${PROFILE} interrupted >&2; exit 2' INT TERM



##---------------##
##   VARIABLES   ##
##---------------##


## read the configuration file
source "$CONF_FILE"


if [ "$LOCAL_BORG_REP" = true ]; then
    ## Repo is on local ##
    BORG_REPO="${STORAGE}"
    REPO_ROOT="localhost"
else
    ## Repo is on a remote ##
    ## resolve ip to use
    for iip in "${HOST_IPS[@]}"; do
        ## listen with netcat
        nc -z -w "$TIMEOUT" "$iip" "$HOST_PORT" 2> /dev/null
        if [[ $? -eq 0 ]]; then
            echo "ACTIVE IP : $iip "
            FOUND=$iip
            ## break with the first success
            break
        else
            echo "NO TRAFIC : $iip "
        fi
    done
    FOUND="${FOUND:-${HOST_IPS[-1]}}"

    ## ip of host to use
    HOST_REPO="$FOUND"

    ## ssh location
    REPO_ROOT="${HOST_USER}@${HOST_REPO}"

    ## fullpath of the repository
    BORG_REPO="${REPO_ROOT}:${STORAGE}"
fi



## have to export these variables for all borg commands
export BORG_REPO="$BORG_REPO"
export BORG_RSH="$BORG_RSH"
export BORG_PASSPHRASE="$BORG_PASSPHRASE"


## print configuration variables
# cat "$CONF_FILE" | sed '/^#/d'
# set


## check whether the variables are set and not null
: "${BORG_REPO:?}"
: "${BORG_PASSPHRASE:?}"
: "${BORG_RSH:?}"
: "${BORG:?}"
: "${DIF_FILE:?}"


function bytesToHR()
{
  local SIZE=$1
  local UNITS="B KiB MiB GiB TiB PiB"
  for F in $UNITS; do
    local UNIT=$F
    test ${SIZE%.*} -lt 1024 && break;
    SIZE=$(echo "$SIZE / 1024" | bc -l)
  done

  if [ "$UNIT" == "B" ]; then
    printf "%4.0f    %s\n" "$SIZE" "$UNIT"
  else
    printf "%7.02f %s\n"  "$SIZE" "$UNIT"
  fi
}


## magic redirection for the whole script
# exec  > >(tee -i "${DIF_FILE}")
exec 2> >(tee -i "${DIF_FILE}" >&2)

echo " List of snapshots for  ${PROFILE}"
echo "--------------------------------------------------------------------------------------"



##------------------##
##   check backup   ##
##------------------##

archives=()
ii=0

while read line; do
    ii=$((ii+1))
    archives[$ii]="$line"
done < <( ${BORG} list                \
                 --sort-by timestamp  \
                 --format "{name}  {start}  {end} {NL}" )

if [[ ${#archives[@]} -eq 0 ]]; then
    echo "Could not find any archives."
    exit 20
fi

for aa in $(seq 1 ${#archives[@]}); do
    printf "%3d %s \n" "$aa" "${archives[$aa]}"
done

echo "--------------------------------------------------------------------------------------"


if [[ ${#archives[@]} -eq 1 ]]; then
    echo "Can not compare to anything else."
    exit 0
fi


echo ""

a_snap=""
while [[ $a_snap -lt 1 ]] || [[ $a_snap -gt  ${#archives[@]} ]]; do
    read -p "Give first base archive [1-${#archives[@]}]: " a_snap
done

b_snap=""
while [[ $b_snap -lt 1 || $b_snap -gt  ${#archives[@]} || $b_snap -eq $a_snap ]] ; do
    read -p "Give archive to compare [1-${#archives[@]}]: " b_snap
done

a_name="${archives[$a_snap]/ */}"
b_name="${archives[$b_snap]/ */}"

echo "Will compare second ( $b_name ) to first ( $a_name )"
echo
echo "--------------------------------------------------------------------------------------"

# ${BORG} list ::"${a_name}"



diffile="/dev/shm/${a_name}_${b_name}.bdiff"

## get all diffs to a file
${BORG} diff  \
        "$BORG_REPO::$a_name" "$b_name" > "${diffile}"

## show only some diffs
\cat "${diffile}" | grep -v "/.git/\|collectd/rrd"
# grep -v "/.git/" "${diffile}"


## count sizes
Rcnt=0
Rsum=0
Acnt=0
Asum=0

while read vv; do
    Rcnt=$((Rcnt+1))
    rem=$(echo "scale=0 ; $vv / 1" | sed 's/B//g ;  s/G/ * 1000 M/;s/M/ * 1000 k/;s/k/ * 1000/;' | bc)
    Rsum=$((rem + Rsum))
#     echo $vv $rem $sum

done < <( cat "${diffile}" | grep "^removed[ ]\+[0-9]" | cut -c-20 | sed 's/removed \+//g' )


while read vv; do
    Acnt=$((Acnt+1))
    rem=$(echo "scale=0 ; $vv / 1" | sed 's/B//g ;  s/G/ * 1000 M/;s/M/ * 1000 k/;s/k/ * 1000/;' | bc)
    Asum=$((rem + Asum))
#     echo $vv $rem $sum

done < <( cat "${diffile}" | grep "^added[ ]\+[0-9]" | cut -c-20 | sed 's/added \+//g' )


## display summaries
echo ""
echo "(Filtered out: git,rdd)"
echo ""
printf "Removed: %5s %12s\n" "$(cat "${diffile}" | grep -c "^removed")"  "$(bytesToHR $Rsum)"
printf "Added  : %5s %12s\n" "$(cat "${diffile}" | grep -c "^added")" "$(bytesToHR $Asum)"
printf "Changed: %5s\n" "$(cat "${diffile}" | grep -vc "^added\|^removed" )"
printf "Total  : %5s\n" "$(cat "${diffile}" | wc -l )"

echo
echo "Output file: ${diffile}"
echo "Profile    :  ${PROFILE}"
echo "Base  repo : ${BORG_REPO}::${a_name}"
echo "Other repo : ${BORG_REPO}::${b_name}"
echo "borg delete -s -v -p "


exit 0
