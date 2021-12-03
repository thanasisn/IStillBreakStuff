#!/bin/bash -x
set +e
## created on 2016-06-05

#### Start up script for xorg user
## with set +e we can run everything existing or not

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

kill_run () {
    killall -s "$1"
    nohup      "$1" &
}




# kill "$(ps -ef | grep "languagetool.jar" | grep -v grep | awk '{print $2}')"
# nohup java -jar ~/PROGRAMS/LanguageTool-4.1/languagetool.jar  --tray &


## to have iso date in pcmanfm
## have to do dpkg-reconfigure and activate en_DK.UTF-8
export LC_TIME=en_DK.UTF-8

## use numbers on num keyboard
numlockx on


## -------------------
## Application Daemons
## -------------------


killall -9  nm-applet
nohup       nm-applet &

# killall -9  skypeforlinux
# nohup       skypeforlinux &


# for java
wmname LG3D



kill_run  system-config-printer-applet
kill_run  dunst
kill_run  kdeconnect-indicator
kill_run  volumeicon
kill_run  sxhkd




if [[ $(hostname) == "crane" ]]; then
    ## make menu key for logitek keyboard
    /usr/bin/xmodmap -e "keysym ISO_Level3_Shift = Menu"
#     /usr/bin/xmodmap -e "keysym 0xff67 = Menu"
#     /usr/bin/xmodmap -e "keycode 108 = Menu"

fi



if [[ $(hostname) == "tyler" ]]; then
    # dont have full keyboard
    numlockx off
fi



# killall -s 9 evolution
# nohup $HOME/BASH/deamonize.sh "evolution -c calendar --name Evolution_i3" &

# killall -s 9 thunderbird
# nohup $HOME/BASH/deamonize.sh "thunderbird" &

# pkill evolution
# nohup $HOME/BASH/deamonize.sh "evolution" &



killall -s 9 stalonetray
nohup $HOME/BASH/deamonize.sh "stalonetray --sticky true -bg black --window-strut right --icon-size 19 --grow-gravity W --skip-taskbar --geometry  4x1-650-6 --icon-gravity W --kludges fix_window_pos" &




## start conky
# export DISPLAY=0 && $HOME/BASH/STARTUP/conky_chooser.sh
export DISPLAY=:0 ;  $HOME/CODE/conky/conky_choose_bigger.sh &

## update backgrounds on all screens
export DISPLAY=:0 ; $HOME/CODE/conky/scripts/update_background.sh &

## start all conky cron scripts and truncate status logs
$HOME/CODE/conky/crons/run_all_crons.sh &



# zeitgeist-daemon --quit
# killall zeitgeist-daemon
# export ZEITGEIST_DATABASE_PATH="$HOME/.config/zeitgeist/$(hostname)/activity.sqlite" && nohup   zeitgeist-daemon -r &
# killall -9 zeitgeist-datahub
# nohup      zeitgeist-datahub -r &


# pkill -f "$HOME/BASH/Desktop_App/main/desktop_app.py"
# "$HOME/BASH/Desktop_App/main/desktop_app.py"


# mkdir -p "$HOME/.config/zeitgeist/$(hostname)/activity.sqlite"
# export ZEITGEIST_DATABASE_PATH="$HOME/.config/zeitgeist/$(hostname)/activity.sqlite"
# exec "$@" &


exit 0
