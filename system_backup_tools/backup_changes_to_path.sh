#!/bin/bash
## created on 2014-03-02

#### Fast copy of changed files after a certain date to a location
## This is to have a backup when there isn't a proper backup working
## Was mainly used to backup to an external drive
## Have to have an idea of the last backup date
## Uses the simplest tools for portability (rsync, find, touch)
## Some file types and folders are excluded

echo ""
echo "usage example"
echo './short_backup_usb.sh "2018-01-15 09:00" /media/athan/8054-5BF2/fff'
echo ""

## date to backup after
datelim="$1"
## destination of the backup
destina="$2"

## prepare location and timestamp
mkdir -p "$destina"                || exit
touch --date "$datelim" "/tmp/foo" || exit


if [ -d "$destina" ]; then
    echo "$destina exist!!"
else
    echo
    echo "target not found"
    echo "exit...."
    echo
    exit 1
fi

bold=$(tput bold)
normal=$(tput sgr0)

FROM="$HOME"

## find files and copy
find "$FROM"                            \
    -type f                             \
    -newer "/tmp/foo"                   \
    -not -path '*/\.*'                  \
    -not -path '*.*~'                   \
    -not -path '*.aux'                  \
    -not -path '*.deb'                  \
    -not -path '*.iso'                  \
    -not -path '*.lof'                  \
    -not -path '*.log'                  \
    -not -path '*.lot'                  \
    -not -path '*.synctex.gz'           \
    -not -path '*.toc'                  \
    -not -path '*/Downloads/*'          \
    -not -path '*/UVindex_Production/*' \
    -not -path '*/ZHOST/*'              \
    -not -path '*/gdalwmscache/*'       \
    -printf %P\\0 | rsync -arvh --stats --files-from=- --from0 "$FROM" "${destina}/"


## make sure the drive is synced especially if is a flash usb drive
sync

## report
echo
echo "Files changed after  ${bold}$datelim${normal}  saved on ${bold}$destina/${normal}"
echo


exit 0
