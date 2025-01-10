#!/usr/bin/env bash
## created on 2019-01-13

#### Keep a program always running and restart it if needed
## First arg a string to execute
## Second arg sleep command duration
## Should work from cron and for gui
## Will emit notifications to the system

COMMAND="$1"
SLEEP="$2"

## set the default wait
SLEEP=${SLEEP:-3m}

## kill Daemon on so many retries
KILL_COUNT=1000

## you have to set this
: ${COMMAND:?}

## unique name for deamon
name="$(echo "$COMMAND" | sed 's/[ ]*//g' | sed 's/[-]\+/-/g')"
pidfile="/dev/shm/${name}.deamon"

## custom notification program
NOTIFY_SEND="notify-send"

echo ""
echo "Command      : '$COMMAND' "
echo "Daemon cycle : $SLEEP     "
echo "Will try for : $KILL_COUNT"
echo "Daemon name  : $name      "
echo ""

export  DISPLAY"$(w -h $USER | awk '$3 ~ /:[0-9.]*/{print $3}' | sed 's/\:/=\:/' | head -1 )"

## first run
echo "STARTING:    ${COMMAND}"
((nruns++))
## run the command !
nohup $COMMAND &
PID="$!"
echo "$PID" > "$pidfile"
$NOTIFY_SEND -u low -t 30000  "Daemon started: $COMMAND "

## keep it running
nruns=0
while true; do
#     echo "File $pidfile"
#     echo "Variable $PID"
#     echo "filepid  $(cat $pidfile)"
    if ps -p "$(cat $pidfile)" > /dev/null; then
        echo "IS RUNNING: $PID ${COMMAND}"
    else
        echo "EXECUTE:    ${COMMAND}"
        ((nruns++))
        ## run the command !
        nohup $COMMAND &
        PID="$!"
        echo "$PID" > "$pidfile"
#        $NOTIFY_SEND -u low -t 30000  "Daemon Exec($nruns): $COMMAND "
    fi
    ## length out daemon
    if [[ $nruns -gt $KILL_COUNT ]]; then
#        $NOTIFY_SEND -u normal "Daemon Exited after $nruns tries, for $COMMAND"
        exit 9
    fi
    sleep "$SLEEP"
done

exit 0
