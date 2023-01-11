#!/bin/bash -x
set +e
## created on 2016-06-05

#### Start up script for xorg user
## with set +e we can run everything existing or not

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

daemonize="$HOME/CODE/system_tools/daemonize.sh"

kill_run () {
    killall -s "$@"
    pkill   -9 "$@"
    setsid     "$@" &
}


## test polybar
killall polybar
xrandr --listactivemonitors | sed 's/^.* //' | sed 1d | while read screen; do
    export MONITOR=$screen
    polybar -c $HOME/.config/polybar/config -r example &
done





exit 0
