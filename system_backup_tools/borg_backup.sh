#!/bin/bash

#############################################################
##  Natsis Athanasios (c) 2018 <natsisthanasis@gmail.com>  ##
##  created:  2018-11-01                                   ##
##  updated:  2024-02-12                                   ##
#############################################################


##  Can create borg backups with different profiles
##  used with  borg 1.2.4 as a cron job
##  Creates backups and prunes the repo
##  Uses full paths for a regular user so root can also execute
##  Hopefully will issue warnings through custom notify-send


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
LOCK_FILE="/dev/shm/borg_backup_${PROFILE}.lock"

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
#     ## set variables for root
# #     NOTIFY_SEND="sudo -u athan DISPLAY=:0 notify-send"
#     NOTIFY_SEND="sudo -u athan DISPLAY=:0 /home/athan/BASH/TOOLS/pub_messages.py"
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

## remove existing log files to clear ownership
rm -f "${LOG_FILE}" "${ERR_FILE}" "${FIL_FILE}"

## magic redirection for the whole script
exec  > >(tee -i "${LOG_FILE}")
exec 2> >(tee -i "${ERR_FILE}" >&2)


## checkpoint interval default: 1800
CHKPNT_INT=600

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

##----------------------##
##   backup procedure   ##
##----------------------##

## in order to work unattended have to break any lock
## make sure only one instance is running !!!!!
info2 "Break lock of $BORG_REPO"
${BORG} break-lock
echo



## export some info before backup
${BORG} --remote-path "${BORG}" info
echo



info2 "Will start backup"
info  "start backup"
TIC=$(date +'%s')
## do the actual backup
${BORG} create                                 \
        --stats                                \
        --verbose                              \
        --filter AMEUx                         \
        --remote-ratelimit "${RATE_LIM}"       \
        --remote-path      "${BORG}"           \
        --checkpoint-interval "${CHKPNT_INT}"  \
        --list                                 \
        --progress                             \
        --show-rc                              \
        --nobsdflags                           \
        --compression         'auto,lzma,4'    \
        --exclude-if-present '.excludeBacula'  \
        --exclude-from       "${EXCLUDE_FILE}" \
                                               \
        ::'{hostname}-{now}'                   \
                                               \
        ${INCLUDE}                             > "$FIL_FILE" 2>&1
backup_exit=$?

TAC=$(date +'%s'); dura="$( echo "scale=6; ($TAC-$TIC)/60" | bc)"
printf "%s  S:%s T:%fmin " "$( date +%F_%T )" "$backup_exit" "$dura"
echo



info2 "Prune repository"
info  "start pruning"
TIC=$(date +'%s')
## The '{hostname}-' prefix is very important to limit prune's
## operation to this machine's archives and not apply to
## other machines' archives also:
${BORG} prune                                  \
        --list                                 \
        --stats                                \
        --remote-path "${BORG}"                \
        --prefix '{hostname}-'                 \
        --show-rc                              \
        -p                                     \
        ${KEEP}                                > "$PRU_FILE" 2>&1
prune_exit=$?

TAC=$(date +'%s'); dura="$( echo "scale=6; ($TAC-$TIC)/60" | bc)"
echo "Prune done in $dura minutes"             >> "$PRU_FILE"


## export some info after backup
${BORG} --remote-path "${BORG}" info
echo


info "Compact repository"
# ${BORG} --remote-path "${BORG}" compact "$BORG_REPO"
${BORG} --remote-path "${BORG}" compact --cleanup-commits "$BORG_REPO"



## get the actual size of the repo
if [ $LOCAL_BORG_REP = true ]; then
    ## Repo is on local machine
    rep_size=$(du -sh "$STORAGE")
    size_exit=$?
else
    ## Repo is on remote machine
    rep_size=$(ssh -q -o BatchMode=yes      \
                -o StrictHostKeyChecking=no \
                -i "${SSH_IDENTITY}"        \
                "${REPO_ROOT}"              \
                 du -sh "$STORAGE" )
    size_exit=$?
fi
status "size:$rep_size"

if [[ $size_exit ]]; then
    echo "$rep_size"
else
    echo " SSH FAIL "
fi
echo



##-----------------##
##   backup info   ##
##-----------------##

# ## list of snapshots (similar output to prune)
# info "Repository listing"
# ${BORG} list                                   > "$LST_FILE" 2>&1
# echo



## export some info after backup
${BORG} --remote-path "${BORG}" info
echo



echo  ""
echo  "******************  END REPORT  ******************"
date +"          %F %T"

if   [ ${backup_exit} -eq 0 ]; then
    echo " $PROFILE backup finished normally       ${backup_exit}"
    status "Backup finished normally ${backup_exit}"
    # $NOTIFY_SEND -u low    -t 6000  "$PROFILE backup finished normally ${backup_exit}"
elif [ ${backup_exit} -eq 1 ]; then
    echo " $PROFILE backup finished with a warning ${backup_exit}"
    status "Backup finished with a warning ${backup_exit}"
    # $NOTIFY_SEND -u normal -t 6000  "$PROFILE backup finished with a warning ${backup_exit}"
elif [ ${backup_exit} -gt 1 ]; then
    echo " $PROFILE backup finished with an ERROR! ${backup_exit}"
    status "Backup finished with an ERROR! ${backup_exit}"
    $NOTIFY_SEND -u critical         "$PROFILE backup finished with an ERROR! ${backup_exit}"
fi


if   [ ${prune_exit} -eq 0 ]; then
    echo " Prune $PROFILE finished normally       ${prune_exit}"
    info "Prune finished normally ${prune_exit}"
    # $NOTIFY_SEND -u low    -t 6000  "Prune $PROFILE finished normally ${prune_exit}"
elif [ ${prune_exit} -eq 1 ]; then
    echo " Prune $PROFILE finished with a warning ${prune_exit}"
    info "Prune finished with a warning ${prune_exit}"
    # $NOTIFY_SEND -u normal -t 6000  "Prune $PROFILE finished with a warning ${prune_exit}"
elif [ ${prune_exit} -gt 1 ]; then
    echo " Prune $PROFILE finished with an ERROR! ${prune_exit}"
    info "Prune finished with an ERROR! ${prune_exit}"
    $NOTIFY_SEND -u critical "Prune $PROFILE finished with an ERROR! ${prune_exit}"
fi

echo  "**************************************************"
echo  ""


## we care more for the backup status
exit ${backup_exit}
