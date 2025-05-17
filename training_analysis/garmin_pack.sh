#!/usr/bin/env bash
## created on 2024-02-20

#### Repack fit and gpx files from garmin for goldencheetah input
## This is simple and dirty

cd ~/Downloads || exit

## extract
atool -xfe $(ls | grep "^[0-9]*\.zip$" | tr '\n' ' ')
## compress
compress_files_best.sh --ask-human no --ovewrite yes --compress yes --algorithm gzip --show-table no ./*.fit
compress_files_best.sh --ask-human no --ovewrite yes --compress yes --algorithm gzip --show-table no ./*.gpx
## clean
trash $(ls | grep "^[0-9]*\.zip$" | tr '\n' ' ')
trash ./*.fit
trash ./*.gpx
## call GoldenCheetah
setsid devour.sh $HOME/PROGRAMS/GoldenCheetah_v3.7_x64Qt6.AppImage &

exit 0 
