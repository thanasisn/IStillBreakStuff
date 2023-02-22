#!/bin/bash
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Spit borg backup logs to list of ignored and archived files and display them
## Input file is *.files from "borg_backup.sh" or "borg_backup_test.sh" scripts
## It filters out some common files from output for better humman consumption

## output
archived="/dev/shm/borg.Archived"
skipped="/dev/shm/borg.Ignored"

## input file
INFILE="$1"


echo
read -p "Apply some filtering on the results ? " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] ; then
    filter_out=true
    echo "Will apply some filtering !!"
else
    filter_out=false
    echo "Will not apply any filtering"
fi


if [[ -f "$INFILE" ]]; then
   echo "File exist"
else
   echo "File do not exist"
   echo "give a borg *.files file"
   exit
fi



## split files to lists
grep "^A " "$INFILE"  > "$archived"
grep "^U " "$INFILE" >> "$archived"
grep "^x " "$INFILE"  > "$skipped"
## sort lists
sort -t' ' -k2 -o "$archived" "$archived"
sort -o "$skipped" "$skipped"


if [ "$filter_out" = true ]; then
    ## this files should be contained in the backup
    ## so we don't won’t to look them at the report

    ## remove known good files
    sed -i                                         \
        -e '/.*-[0-9]\{2\}\.snc$/d'                \
        -e '/.*-[0-9]\{2\}\.stp$/d'                \
        -e '/.*-[0-9]\{2\}\.therm$/d'              \
        -e '/.*[0-9]\{7\}\.pdd$/d'                 \
        -e '/.*\.9\.tar\.xz$/d'                    \
        -e '/.*\.9\.xz$/d'                         \
        -e '/.*\.Rmd$/d'                           \
        -e '/.*\.Rproj$/d'                         \
        -e '/.*\.[Bb][Ii][Bb]$/d'                  \
        -e '/.*\.[Bb][Mm][Pp]$/d'                  \
        -e '/.*\.[Cc]$/d'                          \
        -e '/.*\.[Cc][Bb][RrZz]$/d'                \
        -e '/.*\.[Cc][Ff][Gg]$/d'                  \
        -e '/.*\.[Cc][Hh][Mm]$/d'                  \
        -e '/.*\.[Cc][Pp][Pp]$/d'                  \
        -e '/.*\.[Cc][Ss][Vv]$/d'                  \
        -e '/.*\.[Dd][Aa][Tt]$/d'                  \
        -e '/.*\.[Dd][Jj][Vv][Uu]$/d'              \
        -e '/.*\.[Dd][Oo][Cc]$/d'                  \
        -e '/.*\.[Dd][Oo][Cc][Xx]$/d'              \
        -e '/.*\.[Dd][Oo][Tt]$/d'                  \
        -e '/.*\.[Gg][Ii][Ff]$/d'                  \
        -e '/.*\.[Gg][Pp][Xx]$/d'                  \
        -e '/.*\.[Gg][Zz]$/d'                      \
        -e '/.*\.[Hh][Tt][Mm]$/d'                  \
        -e '/.*\.[Hh][Tt][Mm][Ll]$/d'              \
        -e '/.*\.[Jj][Pp][Ee][Gg]$/d'              \
        -e '/.*\.[Jj][Pp][Gg]$/d'                  \
        -e '/.*\.[Kk][Rr][Aa]$/d'                  \
        -e '/.*\.[Oo][Dd][Gg]$/d'                  \
        -e '/.*\.[Oo][Dd][Pp]$/d'                  \
        -e '/.*\.[Oo][Dd][Ss]$/d'                  \
        -e '/.*\.[Oo][Dd][Tt]$/d'                  \
        -e '/.*\.[Pp][Dd][Ff]$/d'                  \
        -e '/.*\.[Pp][Nn][Gg]$/d'                  \
        -e '/.*\.[Pp][Pp][Tt]$/d'                  \
        -e '/.*\.[Pp][Pp][Tt][Xx]$/d'              \
        -e '/.*\.[Rr]$/d'                          \
        -e '/.*\.[Rr][Aa][Rr]$/d'                  \
        -e '/.*\.[Rr][Dd][Ss]$/d'                  \
        -e '/.*\.[Ss][Hh][Pp]$/d'                  \
        -e '/.*\.[Ss][Vv][Gg]$/d'                  \
        -e '/.*\.[Tt][Ee][Xx]$/d'                  \
        -e '/.*\.[Tt][Ii][Ff]$/d'                  \
        -e '/.*\.[Tt][Xx][Tt]$/d'                  \
        -e '/.*\.[Xx][Ll][Ss]$/d'                  \
        -e '/.*\.[Xx][Ll][Ss][Xx]$/d'              \
        -e '/.*\.[Xx][Zz]$/d'                      \
        -e '/.*\.[Zz][Ii][Pp]$/d'                  \
        -e '/.*\.conf$/d'                          \
        -e '/.*\.csv\.xz$/d'                       \
        -e '/.*\.dat\.gz$/d'                       \
        -e '/.*\.gdb$/d'                           \
        -e '/.*\.ggb$/d'                           \
        -e '/.*\.hrm$/d'                           \
        -e '/.*\.json$/d'                          \
        -e '/.*\.kml$/d'                           \
        -e '/.*\.kmz$/d'                           \
        -e '/.*\.md$/d'                            \
        -e '/.*\.old$/d'                           \
        -e '/.*\.py$/d'                            \
        -e '/.*\.sh$/d'                            \
        -e '/.*\.tar\.xz$/d'                       \
        -e '/.*\.txt\.xz$/d'                       \
        -e '/.*\.vcf$/d'                           \
        -e '/.*\.xcf$/d'                           \
        -e '/.*\.yml$/d'                           \
        -e '/\.arduino\//d'                        \
        -e '/\.git\//d'                            \
        -e '/\.gitignore/d'                        \
        -e '/\.temp!/d'                            \
        -e '/\/DATA_RAW\//d'                       \
        -e '/\/Documents\/Hardcopies Archived\//d' \
        -e '/\/Documents\/History\//d'             \
        -e '/\/athan\/PROGRAMS\//d'                \
        -e '/\/athan\/UVindex_prod\//d'            \
        -e '/\/athan\/Workspaces\//d'              \
        -e '/\/athan\/Zpublic\//d'                 \
        -e '/\/athan\/\.ENC\//d'                   \
        -e '/\/WFA\/download maps\//d'             \
        -e '/\/athan\/sketchbook\//d'              \
        -e '/\/athan\/test\//d'                    \
        -e '/\/borrowed source/d'                  \
        -e '/\/camera barometer LOG\//d'           \
        -e '/source_CCD/d'                         \
        "$archived"
fi

## add some info on the reports
(   echo ""
    echo "From $INFILE"
    echo ""                )   >> "$archived"

(   echo ""
    echo "From $INFILE"
    echo ""                )   >> "$skipped"

## info at the end of script
if [ "$filter_out" = true ]; then
    echo
    echo "Note that Archived list is filtered for brevity"
fi

echo
echo "Archived list: $archived"
echo "Excluded list: $skipped"
echo

## open output files for inspection
setsid kate "$archived" &
setsid kate "$skipped"  &


exit 0
