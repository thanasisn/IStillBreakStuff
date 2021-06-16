#!/bin/bash
## created on 2019-11-22

#### Display the keybinds of some programs by parsing their config files
## The config files have to be formatted in a specific way


## acceptable config files to show
configs=("sxhkd_bspwm" "sxhkd" "dwm" "zathura" "vim" "mpv")

## we have a parser for each file
mpv() {
    file="$HOME/.config/mpv/input.conf"
    echo
    echo " * * * CONFIG FROM $(basename "$file") * * * "
    cat "$file"               |\
    sed "/#/d"                |\
    sed '/^$/N;/^\n$/D'
}

vim() {
    file="$HOME/.vimrc"
    echo
    echo " * * * CONFIG FROM $(basename "$file") * * * "
    cat "$file"               |\
    sed "/^[ \t]*\"[\"]\+/d"  |\
    sed '/set /d'             |\
    sed '/let /d'             |\
    sed '/call /d'            |\
    sed '/if /d'              |\
    sed '/endif/d'            |\
    sed '/colo /d'            |\
    sed '/filetype /d'        |\
    sed '/syntax /d'          |\
    sed '/augroup /d'         |\
    sed '/Plugin /d'          |\
    sed '/Bundle /d'          |\
    sed '/autocmd[ !]/d'      |\
    sed '/^$/N;/^\n$/D'
}

zathura() {
    file="$HOME/.config/zathura/zathurarc"
    echo
    echo " * * * CONFIG FROM $(basename "$file") * * * "
    cat "$file"           |\
    sed "/^set /d"        |\
    sed '/^$/N;/^\n$/D'
}

sxhkd() {
    file="$HOME/.config/sxhkd/sxhkdrc"
    echo
    echo " * * * CONFIG FROM $(basename "$file") * * * "
    cat "$file"                       |\
        sed "/#'/d"                   |\
        sed 's/[ \t]*$//'             |\
        sed -n '1{/^$/p};{/./,/^$/p}' |\
        sed '/^$/N;/^\n$/D'
#         | pygmentize -l md -O style=colorful
}

sxhkd_bspwm() {
    file="$HOME/.config/sxhkd/sxhkdrc_bspwm"
    echo
    echo " * * * CONFIG FROM $(basename "$file") * * * "
    cat "$file"                       |\
        sed "/#'/d"                   |\
        sed 's/[ \t]*$//'             |\
        sed -n '1{/^$/p};{/./,/^$/p}' |\
        sed '/^$/N;/^\n$/D'
#         | pygmentize -l md -O style=colorful
}

dwm() {
    file="$HOME/PROGRAMS/dwm/dwm-6.2/config.h"
    echo
    echo " * * * DWM STANDARD $(basename "$file") * * * "
    echo
    cat "$file"              |\
    grep -v "^[ \t]*//"      |\
    grep -i "modkey\|button" |\
    sed '/\/\*/d'            |\
    sed "/^[ ]*#/d"          |\
    sed "/^[ ]*static/d"     |\
    sed '/^$/N;/^\n$/D'

    file="$HOME/PROGRAMS/dwm/dwm-6.2_luke/config.h"
    echo
    echo " * * * DWM LUKE $(basename "$file") * * * "
    echo
    cat "$file"              |\
    grep -v "^[ \t]*//"      |\
    grep -i "modkey\|button" |\
    sed '/\/\*/d'            |\
    sed "/^[ ]*#/d"          |\
    sed "/^[ ]*static/d"
}


## interactive UI
if [[ $# -lt 1 ]]; then
    echo "Choose from available"

    a_snap=""
    while true; do

        printf "%3d %s \n" "0" "Exit"
        for aa in $(seq 1 ${#configs[@]}); do
            ii=$((aa-1))
            printf "%3d %s \n" "$((aa))" "${configs[$ii]}"
        done
        read -p "Give number to display [1-${#configs[@]}]: " a_snap

        [ $a_snap == 0 ] && exit 0

        sel="${configs[$((a_snap-1))]}"

        ## display the config file
        $sel | less

    done
fi


exit 0
