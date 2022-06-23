#!/bin/bash

#### Add missing '/' to bib files pahts

BIBFILE="$1"

echo "$BIBFILE"
echo "Add presiding '/' to home path"

sed -i 's/file = {:home/file = {:\/home/g' "$BIBFILE"

