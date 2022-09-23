#!/bin/bash

#### Directly sync folders from current to a remote
## Fast sync before unison
## This is DANGEROUS will remove files from remote

## This list CAN NOT COPE WITH SPACES !!
list=(
'/home/athan/BASH'
'/home/athan/PROGRAMS'
)


REMOTE_HOST="crane"
REMOTE_USER="$USER"
REMOTE="${REMOTE_USER}@${REMOTE_HOST}"
OPTIONS=" --info=progress2 --info=name0 -arvh --stats --delete "

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
