#!/bin/bash
## created on 2020-02-15

#### Rename images and put in subfolder based on exif original date

FOLDER="$1"
: ${FOLDER:="./"}

exiftool -v -P \
	-r '-FileName<DateTimeOriginal'        \
	-d %%d/%Y%m%d/%Y%m%d_%H%M%S%%-02c.%%e  \
	"$FOLDER"

# exiftool -v -P -r '-FileName<CreateDate' -d %Y%m%d_%H%M%S%%-02c.%%e "$FOLDER"


exit 0 
