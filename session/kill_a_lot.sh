#!/bin/bash
## created on 2014-08-15

#### Kill programs and services in order to obtain more POWERrrr

## list of prosses to kill
kkk=(
"Clamav:         'sudo killall -9 -v clamscan'                    "
"Clamav:         'sudo systemctl stop clamav-freshclam.service'   "
"Conky:          'killall -9 -v conky'                            "
"Dunst:          'killall -9 -v dunst'                            "
"Evolution:      'kill -9 \$(pgrep "evolution*")'                 "
"Hp-systray:     'killall -9 -v hp-systray'                       "
"Keyring daemon: 'killall -9 -v gnome-keyring-daemon'             "
"Thunderbird:    'killall -9 -v thunderbird'                      "
"Transmission:   'sudo killall -9 -v transmission-daemon'         "
"Transmission:   'sudo systemctl stop transmission-daemon.service'"
"Zeitgeist:      'kill -9 \$(pgrep  zeitgeist)'                   "
)

echo
for i in "${kkk[@]}"; do
    name=$(echo $i | cut -d":" -f1)
    comm=$(echo $i | cut -d":" -f2 | sed "s/^[ ]\+'//" | sed "s/'$//")
#     echo "$name"
#     echo "$comm"

    input=0
    echo "KILL:   $name "
    echo -n " (y/n)?: "
    read -n 1 input
    if [ "$input" == "y" -o "$input" == "Y" ] ; then
        echo ""
        echo "RUN: $comm"
        $comm
    fi
    echo
    echo "----------------------------------"
done

echo " "
echo " ~~ END ~~ "


##TODO kill browsers
##TODO kill recollindex

# sudo /etc/init.d/cups stop
# sudo /etc/init.d/bluetooth stop
# killall -i monitor_machines_z.sh
# killall gthumb



exit 0
