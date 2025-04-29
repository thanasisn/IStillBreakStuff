#!/bin/bash

#### Directly sync folders from current to a remote
## Fast sync before unison
## This is DANGEROUS will remove files from remote

## This list CAN NOT COPE WITH SPACES !!
list=(
'/home/athan/.ENC'
'/home/athan/.dot_files'
'/home/athan/.dot_files_private'
'/home/athan/.dotfiles'
'/home/athan/.ssh'
'/home/athan/.unison'
'/home/athan/Aerosols'
'/home/athan/BASH'
'/home/athan/CODE'
'/home/athan/DATA'
'/home/athan/DATA_ARC'
'/home/athan/DATA_RAW'
'/home/athan/Documents'
'/home/athan/Ecotime_machine'
'/home/athan/GISdata'
'/home/athan/Improved_Aerosols_O3'
'/home/athan/LIBRARY'
'/home/athan/LOGs'
'/home/athan/LibRadTranG'
'/home/athan/LifeAsti'
'/home/athan/MANUSCRIPTS'
'/home/athan/MISC'
'/home/athan/PROGRAMS'
'/home/athan/PROJECTS'
'/home/athan/Pictures'
'/home/athan/TEACHING'
'/home/athan/TRAIN'
)


REMOTE_HOST="192.168.1.105"
REMOTE_HOST="mumra.ts"
REMOTE_USER="$USER"
REMOTE="${REMOTE_USER}@${REMOTE_HOST}"
OPTIONS=" --info=progress2 --info=name0 -arvh --stats --delete "
OPTIONS=" --info=progress2 --info=name0 -arvh --stats "

echo
echo "***********************************************"
echo "  THIS IS DANGEROUS !! "
echo "  YOU MAY LOSE DATA THAT EXIST ONLY ON $REMOTE_HOST "
echo "***********************************************"
echo
echo "This do an rsync from here to remote and also"
echo "delete files at remote. The intend is to do a"
echo "fast sync before doing an unison, in cases no"
echo "sync was done with unison for a while."
echo
echo "OPTIONS: $OPTIONS"
echo "REMOTE:  $REMOTE"
echo
echo "WILL OVERWRITE: "
echo
printf '%s\n' "${list[@]}"
echo
read -p "continue  yes/n? " -n3
echo ""
if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    #      --dry-run     \

    rsync $OPTIONS      \
          "${list[@]}"  \
          "${REMOTE}:/home/$REMOTE_USER/"

fi

echo "END"
exit 0
