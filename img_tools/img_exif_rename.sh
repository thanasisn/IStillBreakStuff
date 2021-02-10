#!/bin/bash
## created on 2020-02-15

#### Rename images based on exif original date 

FOLDER="$1"
: ${FOLDER:="./"}

exiftool -v -P -r '-FileName<DateTimeOriginal' -d %Y%m%d_%H%M%S%%-02c.%%e "$FOLDER"

## This works and on videos I think
exiftool -v -P -r '-FileName<CreateDate'       -d %Y%m%d_%H%M%S%%-02c.%%e "$FOLDER"


exit 0 
