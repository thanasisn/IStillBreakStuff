#!/usr/bin/env bash
set -x
set +e
## created on 2016-06-05

#### Start up script for xorg user
## with set +e we can run everything existing or not

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

daemonize="$HOME/CODE/system_tools/daemonize.sh"

display="$(w -hs | awk '{print $3}' | sort -u | grep ":[0-9]\+")"


kill_run () {
    killall -s "$@"
    pkill   -9 "$@"
    setsid     "$@" &
}


# kill "$(ps -ef | grep "languagetool.jar" | grep -v grep | awk '{print $2}')"
# nohup java -jar ~/PROGRAMS/LanguageTool-4.1/languagetool.jar  --tray &


## to have iso date in pcmanfm
## have to do dpkg-reconfigure and activate en_DK.UTF-8
export LC_TIME=en_DK.UTF-8
export _JAVA_AWT_WM_NONREPARENTING=1                                                             [7:36:07]

## use numbers on num keyboard
numlockx on


## -------------------
## Application Daemons
## -------------------


# for java
wmname LG3D


kill_run  nm-tray
kill_run  nm-applet
kill_run  system-config-printer-applet
kill_run  dunst
kill_run  kdeconnect-indicator
kill_run  volumeicon
# kill_run  $HOME/CODE/conky/scripts/top_ps.sh

if [[ $WM_NAME = "bspwm" ]]; then
    ## keybinds for bspwm
    skill_run xhkd -c "$HOME/.config/sxhkd/sxhkdrc_bspwm"
else
    ## any other wm
    kill_run sxhkd
fi

# kill_run  "python3 $HOME/PROGRAMS/noisy/noisy.py --config $HOME/PROGRAMS/noisy/config.json"


## restart sycnthing server
killall -9 syncthing
setsid syncthing -config="$HOME/.config/syncthing_$(hostname)" \
                 -data="$HOME/.config/syncthing_$(hostname)"   \
                 -audit                                        \
                 -no-browser                                   \
                 -auditfile="/dev/shm/syncthing_audit"         \
                 -logfile="/dev/shm/synchthing_log"            &

## restart applet
kill_run syncthing-gtk --minimized --home "$HOME/.config/syncthing_$(hostname)"


if [[ $(hostname) == "crane" ]]; then
    ## make menu key for logitek keyboard
    /usr/bin/xmodmap -e "keysym ISO_Level3_Shift = Menu"
fi

numlockx on

kill_run zeitgeist-daemon 


# killall -s 9 evolution
# nohup $HOME/BASH/deamonize.sh "evolution -c calendar --name Evolution_i3" &

killall -s 9 thunderbird
nohup $HOME/BASH/deamonize.sh "$HOME/.nix-profile/bin/thunderbird" &

# pkill evolution
# nohup $HOME/BASH/deamonize.sh "evolution" &


# killall -s 9 stalonetray
# nohup $daemonize "stalonetray --sticky -bg black --window-strut right --icon-size 19 --grow-gravity W --skip-taskbar --geometry  4x1-650-6 --icon-gravity W --kludges fix_window_pos" &


## a new toy
## this may break conky
# "$HOME/BASH/notification_log.sh" "$HOME/LOGs/SYSTEM_LOGS/Notification_$(hostname).log" &


## start conky
## update backgrounds on all screens
export DISPLAY=$display; "$HOME/CODE/conky/scripts/update_background.sh" &

# export DISPLAY=0 && $HOME/BASH/STARTUP/conky_chooser.sh
export DISPLAY=$display; "$HOME/CODE/conky/conky_choose_bigger.sh" &


## start all conky cron scripts and truncate status logs
"$HOME/CODE/conky/crons/run_all_crons.sh" &

## test polybar
killall polybar
xrandr --listactivemonitors | sed 's/^.* //' | sed 1d | while read screen; do
    export MONITOR=$screen

    ## use the right bar
    if [[ $WM_NAME = "i3" ]]; then
        polybar -c $HOME/.config/polybar/config -r i3bar &
    elif [[ $WM_NAME = "bspwm" ]]; then
        polybar -c $HOME/.config/polybar/config -r bspwmbar &
    else
        polybar -c $HOME/.config/polybar/config -r example &
    fi
done

## i3 auto layout
if [[ $WM_NAME = "i3" ]]; then
    setsid $HOME/.config/i3/i3-automatic-layout.py &
fi

exit 0
