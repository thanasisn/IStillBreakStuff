#!/bin/bash
## created on 2022-12-19
## https://github.com/thanasisn <lapauththanasis@gmail.com>

#### Create a quick note and get in the Notes dir. 
## Run on terminal or as a keybind

## go to this folder at the end
NOTESDIR="$HOME/PANDOC/Notes"
cd "$NOTESDIR" || exit 

## file name for the note
newfile="${NOTESDIR}/Quick_Note_$(date +'%F_%H%M')"

## use a script
new_note.sh "$newfile"

## leave the shell in the current dir
$SHELL

exit
