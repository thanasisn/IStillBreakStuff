#!/usr/bin/env bash

##  Initialisation
profile="$1"; shift
args="$*"
## Sanitize profile name for use in filename
sanitized_profile=$(echo "$profile" | sed 's/[^a-zA-Z0-9._-]/_/g')
lock="/dev/shm/$(basename "$0")_${sanitized_profile}.lock"
ldir="/home/athan/LOGs/SYSTEM_LOGS/"
killafter="8h"
##  Create lock file directory if needed
lock_dir=$(dirname "$lock")
mkdir -p "$lock_dir"

echo
echo "Profile:   $profile"
echo "Args:      $args"
echo "Die after: $killafter"

##  Allow only one instance
exec 9>"$lock"
echo "Lock:      $lock"
if ! flock -n 9  ; then
  echo "Another instance is running";
  exit 1
fi

: ${ID:=$(hostname)}
SCRIPT="$(basename "$0")"
info() { echo "$(date +'%F %T') ::INF::${SCRIPT}::${ID}::$*::" | tee "$LOGFILE"; }

set +e

##  Commands used must exist on remote server
UNISON="unison"
NOTIFY="$HOME/BASH/TOOLS/pub_messages.py"
TIMEOUT="/usr/bin/timeout"

##  Function to parse unison exit codes and emit notification to systems
emessage () {
    # echo "$1"
    case $1 in
        0)  emsg="Successful sync everything is synced"
            # timeout 1m $NOTIFY -u low      -t 1000 "$2 Unison" "$emsg"
            # /home/athan/CODE/system_tools/telegram_status.sh "$(hostname) unison $TAG" "$emsg"
            # /home/athan/CODE/system_tools/telegram_file.sh   "$(hostname) unison $TAG" "$applog"
            ;;
        1)  emsg="Files skipped transfers successful"
            # timeout 1m $NOTIFY -u low      -t 1000 "$2 Unison" "$emsg"
            # /home/athan/CODE/system_tools/telegram_status.sh "$(hostname) unison $TAG" "$emsg"
            # /home/athan/CODE/system_tools/telegram_file.sh   "$(hostname) unison $TAG" "$applog"
            ;;
        2)  emsg="Non fatal failures occurred"
            # timeout 1m $NOTIFY -u normal   -t 1000 "$2 Unison" "$emsg"
            # /home/athan/CODE/system_tools/telegram_status.sh "$(hostname) unison $TAG" "$emsg"
            # /home/athan/CODE/system_tools/telegram_file.sh   "$(hostname) unison $TAG" "$applog"
            ;;
        3)  emsg="Fatal error or execution interrupted"
            timeout 1m "$NOTIFY" -u critical -t 300000 "$2 Unison" "$emsg"
            /home/athan/CODE/system_tools/telegram_status.sh "$(hostname) unison $TAG" "$emsg"
            /home/athan/CODE/system_tools/telegram_file.sh   "$(hostname) unison $TAG" "$applog"
            ;;
        *)  emsg="Unknown error"
            timeout 1m "$NOTIFY" -u critical -t 300000 "$2 Unison" "$emsg"
            /home/athan/CODE/system_tools/telegram_status.sh "$(hostname) unison $TAG" "$emsg"
            /home/athan/CODE/system_tools/telegram_file.sh   "$(hostname) unison $TAG" "$applog"
            ;;
    esac
    echo "$emsg"
}

## have to go to home for unison to work
cd "/home/athan"

echo
echo ">>    $profile    <<"
echo "------------------------------------"
echo

LOGFILE="${ldir}/unison_tyler_sagan.status"
TAG="$profile"
applog="/tmp/unison_${TAG}_$(date +%F_%R).log"

info "Start::$TAG"
## print unison command to run
echo
echo  "$UNISON $profile -servercmd" "$UNISON" -logfile "${applog}" -batch "$@"
echo

## run unison with some specifications
$TIMEOUT -k 10 "$killafter" \
    nice -n 19              \
    $UNISON "$profile" -servercmd "$UNISON" -logfile "${applog}" -batch "$@"

## capture and notify on exit status
status="$?"
mmmm="$(emessage "$status")"
echo
info "$status::$TAG::$mmmm"
info "Finish::$TAG"
exit

set -e
exit 0

