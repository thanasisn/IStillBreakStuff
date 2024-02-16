#!/usr/bin/env bash
## created on 2023-04-27

#### Create or reuse a named tmux session to run commands 

SESSION="$1"

## simple check on arguments
if [[ "$#" -lt 2 ]]; then
    echo
    echo "Too few arguments!! Exit!!"
    echo
    echo "Usage:"
    echo "    $(basename $0) session_name \"command1; command2; ... \""
    echo
    exit 1
fi

## show info
echo
echo "Session name:: $SESSION" 
echo "Rest of Args:: ${@:2}"

## prettify execution
EXECUTE="echo; date +'%F %T %Z'; echo; ${@:2}; echo"

## init tmux session
tmux has-session -t "$SESSION" 2>/dev/null
if [ "$?" -eq 1 ] ; then
     echo "Creating session:: $SESSION"
     EXECUTE="$SHELL; $EXECUTE"
     tmux new-session -d -s "$SESSION"
else
     echo "Existing session:: $SESSION"
fi

## send commands to session
tmux send-keys -t "$SESSION" "$EXECUTE" Enter
echo
echo "Commands send to session!"

exit 0 
