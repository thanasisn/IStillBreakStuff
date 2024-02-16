#!/usr/bin/env bash
## https://github.com/thanasisn <natsisphysicist@gmail.com>


#### Remove metadata from any file using exiftool

## Try to remove metadata from any given file...
## Not fool proof of course. Test the results

for af in "$@"; do

    [[ ! -f "$af" ]] && echo "NOT A FILE: $af" && continue

    echo "REMOVE METADATA FROM:  $af"

    ## show tags from the original PDF
    # exiftool -all:all "$af"

    ## This will empty tags (XMP + metadata) from any file
    exiftool -overwrite_original -all:all= "$af"

    ## Not sure why I use that
    qpdf --linearize "$af" "${af}.tmp" && mv "${af}.tmp" "$af"

    ## Show remaining metadata to be sure
    exiftool -all:all "$af"

    done

exit 0
