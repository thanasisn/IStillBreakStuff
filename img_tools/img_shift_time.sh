#!/bin/bash
## created on 2021-01-14

#### Shift CreateDate and DateTimeOriginal by a fixed amount.
## Works on whole folders
## I haven't pass glob patterns to script

TIME="$1"
GLOB="$2"

echo
echo "usage: <+/- HH:MM:SS> <glob>"
echo "$TIME  $GLOB"
echo

: "${TIME:?}"
: "${GLOB:?}"

sign="$(echo "$TIME" | cut -c 1)"
valu="$(echo "$TIME" | cut -c 2-)"

[[ "$sign" != [-+] ]] && echo "Must include sign!" && exit 2

valu="$(echo $valu)"
valu="$(echo "$valu" | grep "[0-9]\{1,2\}:[0-9]\{1,2\}:[0-9]\{1,2\}")"

: "${valu:?}"

echo "Shift images:  $GLOB "
echo "Time shift:    $sign $valu"

read -p "Continue? " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Start shift"
    echo
else
    echo "bye"
    exit 0
fi


echo "SOME TESTING NEEDED"
exit

##TODO can be combined to one command
exiftool -recurse -verbose -preserve \"-CreateDate${sign}=00:00:00 ${valu}\" "${GLOB}"
exiftool -recurse -verbose -preserve \"-DateTimeOriginal${sign}=00:00:00 ${valu}\" "${GLOB}"

exit
exiftool -recurse -verbose -preserve -CreateDate"${sign}=00:00:00 ${valu}" "${GLOB}"
exiftool -recurse -verbose -preserve -DateTimeOriginal"${sign}=00:00:00 ${valu}" "${GLOB}"

exit 0
#exiftool -r -v -P -CreateDate-=0:0:0 1:02:00 ./*.*
#exiftool -r -v -P -DateTimeOriginal-=0:0:0 1:02:00 ./*.*
