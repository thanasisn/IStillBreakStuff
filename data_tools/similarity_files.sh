#!/bin/bash
## created on 2019-03-05

#### Use `sherloc` and `sim_text` to create similarity list of files

## very useful for find similar pdf or scripts of code
## just use some defaults for each program
## for pdf is better to do a textualise.sh first
## ideas taken from https://github.com/adsieg/text_similarity
## the output files have all the extensions in the name

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
## executable
SHERLOCK="$SCRIPT_DIR/sherlock/sherlock"


info () { echo "$(date +"%F %T") :: $@" ; }

display_help () {
    echo
    echo "Usage: $0 <path> <glob1> [glob2] [glob3] ... " >&2
    echo
    echo "   path       path for hidden list files output"
    echo "   glob       a shell glob pattern "
    echo
    echo " examples: "
    echo " $0 ./ ./*.{sh,py} ./**/*.sh "
    echo " $0 ./LIBRARY ./LIBRARY/Atmospheric_Environmental_Physics/**/.*/*.txtl "
    echo " $0 ./ ./**/* "
    echo
    echo " Note duplicates of filepaths are not excluded"
    echo
    exit 1
}

if [ "$1" == "-h" ]; then
  display_help
  exit 0
fi

if [ "$#" -lt 2 ]; then
    echo "At least two arguments must be given"
fi


## get input
directory="$1"
shift 1

echo
if [[ -d "$directory" ]];then
    info "START MATCHING"
else
    echo "First argument must be a directory"
    exit 2
fi


## parse extensions
# a="$*"    b="${*#.}"
# (( ${#a} - ${#b} - $# )) && echo "some extension(s) is(are) missing a leading dot." >&2
# fileExtensions="$(IFS=\|; echo "${*#.}")"
#
# comptype="$(echo $@ | sed 's/ \+//g' | sed 's/\./_/g')"


## pre output files
outsherloc="${directory}/.sherloc.sim_list"
outsimtext="${directory}/.simtext.sim_list"
outsimtext2="${directory}/.simtext2.sim_list"


# echo "$outsherloc"
# echo "$outsimtext"


##---------------------------------------##
##  run sherlock and get output to file  ##
##---------------------------------------##
info "Run sherlock"
$SHERLOCK "$@"                |\
    sed 's/\.txtl"/"/g'       |\
    sed 's/\.textualise\///g' |\
    sort -u                   |\
    sort -k1n -k2 > "${outsherloc}"

info "Process output"
## just get extensions to use as filename
comptype="$(cat "${outsherloc}" |\
                egrep -i -E -o "\.{1}\w*\"" |\
                sort -u |\
                sed 's/".*//g' |\
                sed 's/\./_/g' |\
                tr -d '\n')"

mv "${outsherloc}" "${directory}/.sherloc${comptype}.sim_list"
info "${directory}/.sherloc${comptype}.sim_list"


##---------------------------------------##
##  run sim_text and get output to file  ##
##---------------------------------------##
info "Run sim_text"
sim_text -e -s -p "$@"              |\
    grep "consists for [0-9]* % of" |\
    sed '/^[[:space:]]*$/d'         |\
    sed 's/\.txtl / /g'             |\
    sed 's/\.textualise\///g'  > "${outsimtext}"

info "Process output"

# cat  "${outsimtext}" | grep -o "consists for [0-9]* % of" | grep -o "[0-9]*"
# cat  "${outsimtext}" | sed 's/ consists for [0-9]\+ % of .*//g' | sed 's/\(.*\)/"\1"/g'
# cat  "${outsimtext}" | sed 's/.* consists for [0-9]\+ % of //g' | sed 's/ material$//g' | sed 's/\(.*\)/"\1"/g'

paste -d ' ' <(cat  "${outsimtext}" | grep -o "consists for [0-9]* % of"       | grep -o "[0-9]*")      \
             <(cat  "${outsimtext}" | sed 's/ consists for [0-9]\+ % of .*//g' | sed 's/\(.*\)/"\1"/g') \
             <(cat  "${outsimtext}" | sed 's/.* consists for [0-9]\+ % of //g' | sed 's/ material$//g'  | sed 's/\(.*\)/"\1"/g') |\
             sort -u        |\
             sort -k1n -k2 > "${outsimtext}.tmp"

## just get extensions to use as filename
comptype="$(cat "${outsimtext}.tmp"         |\
                egrep -i -E -o "\.{1}\w*\"" |\
                sort -u                     |\
                sed 's/".*//g'              |\
                sed 's/\./_/g'              |\
                tr -d '\n'                  )"

mv "${outsimtext}.tmp" "${directory}/.simtext${comptype}.sim_list"
info "${directory}/.simtext${comptype}.sim_list"
rm "${outsimtext}"


## other methods should go here


exit 0
