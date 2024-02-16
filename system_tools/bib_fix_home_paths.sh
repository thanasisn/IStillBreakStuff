#!/usr/bin/env bash

#### Add missing '/' to bib files pahts
## This should work only for full path files


BIBFILE="$1"

echo "$BIBFILE"
echo "Add presiding '/' to home path"

sed -i 's/file[ ]\+=[ ]\+{:home/file = {:\/home/g' "$BIBFILE"

