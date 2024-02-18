#!/bin/bash

#############################################################
##  Natsis Athanasios (c) 2018 <natsisthanasis@gmail.com>  ##
##  created 2018-11-01                                     ##
##                                                         ##
##  Used to check borg backups with different profiles     ##
##  used for borg 1.1.7 as a cron job                      ##
#############################################################



## executable path
# BORG="/home/athan/PROGRAMS/borgtest/borg-1.2.0a7"
# BORG="/home/athan/PROGRAMS/borgtest/borg-1.2.4"
## Debian 12 has 1.2.4 as default
BORG="borg"

## check requirements
command -v nc    >/dev/null 2>&1 || { echo >&2 "nc NOT INSTALLED. Aborting."; exit 1; }
command -v $BORG >/dev/null 2>&1 || { echo >&2 "borg NOT INSTALLED. Aborting."; exit 1; }


##-------------------------##
##   logging definitions   ##
##-------------------------##

## use full path for root access
ldir="/home/athan/LOGs/SYSTEM_LOGS/"
mkdir -p "$ldir"

ID="$1"
: ${ID:=$(hostname)}
SCRIPT="$(basename "$0")"
SCRIPT_ROOT="$(dirname $(readlink -f "$0"))"

fsta="${ldir}/$(basename "$0")_$ID.status"
info()   { echo "$(date +'%F %T') ::INF::${SCRIPT}::${ID}:: $* ::" >>"$fsta"; }
status() { echo "$(date +'%F %T') ::STA::${SCRIPT}::${ID}:: $* ::" >>"$fsta"; }


info "Script root $SCRIPT_ROOT"
##---------------------------------------------------##
##   get check prepare read the configuration file   ##
##---------------------------------------------------##

PROFILE="$1"
PROFILE="${PROFILE%.*}"
PROFILE_FOLDER="/home/athan/BASH/CRON/borg_profiles"

CONF_FILE="${PROFILE_FOLDER}/${PROFILE}.conf"
CONF_SECU="${PROFILE_FOLDER}/.${PROFILE}.conf"
LOCK_FILE="/dev/shm/borg_check_${PROFILE}.lock"

# NOTIFY_SEND="notify-send"
NOTIFY_SEND="/home/athan/BASH/TOOLS/pub_messages.py"
LOCATION_DET="/home/athan/CODE/conky/scripts/location.R"


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

## get location info in case of just booting up
$LOCATION_DET

# ## check if we have to run as root 
# if echo "$PROFILE" | grep -q "[Cc][Aa][Mm]"; then
#     ## check if we are root
#     if [[ $EUID -ne 0 ]]; then
#         echo
#         echo "**  You have to run as root  **"
#         echo
#         exit 98
#     fi
#
#     ## set variables for root
#     NOTIFY_SEND="sudo -u athan DISPLAY=:0 notify-send"
#
# fi

info "script started"


## filter the original to a new file
grep -E '^#|^[^ ]* *= *[^;&]*'  "$CONF_FILE" | sed 's/ \+= \+/=/g' > "$CONF_SECU"
CONF_FILE="$CONF_SECU"

## some helpers and error handling:
info2() { echo "$(date +%F_%T) -- $* ------" >&2; }
# trap 'echo $( date ) Backup ${PROFILE} interrupted >&2; exit 2' INT TERM
trap 'echo $( date ) Backup ${PROFILE} interrupted >&2;' INT TERM
trap cleanup 0 1 2 3 6


##---------------##
##   VARIABLES   ##
##---------------##


## read the configuration file
source "$CONF_FILE"

cleanup() {
    ## make all files accessible when running as root
    chmod a+rw  "${LOG_ROOT_PATH}_${PROFILE}"*
    chown athan "${LOG_ROOT_PATH}_${PROFILE}"*

    chmod a+rw  "${CONF_SECU}"
    chown athan "${CONF_SECU}"

    chmod a+rw  "${fsta}"
    chown athan "${fsta}"

    rm -f "$LOCK_FILE"
    exit
}


if [ $LOCAL_BORG_REP = true ]; then
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
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

## print configuration variables
# cat "$CONF_FILE" | sed '/^#/d'
# set


## check whether the variables are set and not null
: "${BORG_REPO:?}"
: "${BORG_PASSPHRASE:?}"
: "${BORG_RSH:?}"
: "${BORG:?}"
: "${CHK_FILE:?}"
: "${RATE_LIM:?}"
: "${EXCLUDE_FILE:?}"
: "${INCLUDE:?}"
: "${FIL_FILE:?}"
: "${KEEP:?}"
: "${PRU_FILE:?}"
: "${REPO_ROOT:?}"
: "${SSH_IDENTITY:?}"
: "${STORAGE:?}"
: "${LOG_FILE:?}"
: "${ERR_FILE:?}"


## magic redirection for the whole script
exec  > >(tee -i "${CHK_FILE}")
exec 2> >(tee -i "${CHK_FILE}" >&2)



## change upload limit based on location
if grep -iq "home: false" /dev/shm/locations.log ; then
    echo "Not in home: increase bandwidth"
    RATE_LIM=999999
    CHKPNT_INT=600
fi

if grep -iq "155\.207\." /dev/shm/CONKY/last_location.dat ; then
    echo "In university network: increase bandwidth"
    RATE_LIM=999999
    CHKPNT_INT=600
fi

echo "Bandwidth set to $RATE_LIM kb"
echo "------------------------------------------------------------------------------"

##------------------##
##   check backup   ##
##------------------##

info "Check repository for ${PROFILE}"

## check the repository only
${BORG} check          \
        --progress     \
        --show-rc      \
        --info
## get check status
check_exit=$?
echo "------------------------------------------------------------------------------"
echo "$( date +%F_%T ) S:$check_exit " 
status "${check_exit}"

echo

# --archives-only
# --repository-only
# --verify-data


if   [ ${check_exit} -eq 0 ]; then
    echo "$PROFILE CHECK status     NORMAL    ${check_exit}"
    $NOTIFY_SEND -u low -t 60000 "$PROFILE CHECK status NORMAL ${check_exit}"
elif [ ${check_exit} -eq 1 ]; then
    echo "$PROFILE CHECK status  * WARNING *  ${check_exit}"
    $NOTIFY_SEND -u normal       "$PROFILE CHECK status * WARNING * ${check_exit}"
elif [ ${check_exit} -gt 1 ]; then
    echo "$PROFILE CHECK status *** ERROR *** ${check_exit}"
    $NOTIFY_SEND -u critical     "$PROFILE CHECK status *** ERROR *** ${check_exit}"
fi



exit ${check_exit}
