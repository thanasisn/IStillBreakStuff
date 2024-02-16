#!/usr/bin/env bash
## created on 2023-01-31

#### Open a browser bookmark with dmenu

# There is a general python solution
# https://github.com/browser-history/browser-history
# pip install browser-history

IGNORE="$HOME/BASH/PARAMS/ignore_sites.list"
BROWSER="brave"
BRWSHIS="$HOME/.local/bin/browser-history"

command -v "$BRWSHIS" >/dev/null 2>&1 || { echo >&2 "browser-history NOT INSTALLED. Aborting."; exit 1; }

## send bookmarks to dmenu
ANS=$(
$BRWSHIS -t bookmarks  \
         -b "$BROWSER" \
         -f csv                         |\
        sed "1d"                        |\
        sort -t"," -r -k1,2             |\
        sort -t"," -u -k2,2             |\
        grep -v -x -i -f "$IGNORE"      |\
        sort -V -r                      |\
        cut -d',' -f2-                  |\
        dmenu -i -l 15 -p "BM"
)

## hope for the best
url="$(echo "$ANS" | cut -d',' -f1)"
echo "$url"
xdg-open "$url"

## get only domain for setting exclutions
# | awk -F/ '{print $3}'

exit 0 
