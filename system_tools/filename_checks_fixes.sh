#!/bin/bash
## created on 2017-09-26

#### Make file and folder names consistent and nice


FOLDER="$@"
echo "$FOLDER"

## rename
# -d, --filename, --nopath, --nofullpath
#     Do not rename directory: only rename filename component of path.
# -n, --nono
#     No action: print names of files to be renamed, but don't rename.

DO=" -n "
DO=" -v "



echo
echo "#########################################"
echo "    Simplify multiple spaces in files    "
echo "#########################################"

## find files
getlist="$(find "$FOLDER" \
                -depth    \
                -not \( -path "*/.git*"       -prune \) \
                -not \( -path "*/inst/art/*"  -prune \) \
                -not \( -path "*/inst/as/*"   -prune \) \
                -not \( -path "*/inst/.art*"  -prune \) \
                -name "* *" | grep "  " )"

## print list and count
echo "$getlist" | sed '/^\s*$/d'
echo "----"
filesnum=$(echo "$getlist" | sed '/^\s*$/d' | wc -l)
echo "Files found:  $filesnum"

## rename files
if [[ $filesnum -gt 0 ]]; then
    read -p "Simpify multiple spaces in filenames ? " -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        echo "$getlist" | tr '\n' '\0' | xargs -0 -n1 rename $DO "s/[ ]+/ /g"
    fi
fi



echo
echo "##############################################"
echo "    Simplify multiple underscores in files    "
echo "##############################################"

## find files
getlist="$(find "$FOLDER" \
                -depth    \
                -not \( -path "*/.git*"       -prune \) \
                -not \( -path "*/inst/art/*"  -prune \) \
                -not \( -path "*/inst/as/*"   -prune \) \
                -not \( -path "*/inst/.art*"  -prune \) \
                -name "*_*" | grep "__" )"

## print list and count
echo "$getlist" | sed '/^\s*$/d'
echo "----"
filesnum=$(echo "$getlist" | sed '/^\s*$/d' | wc -l)
echo "Files found:  $filesnum"

## rename files
if [[ $filesnum -gt 0 ]]; then
    read -p "Simpify multiple underscores in filenames ? " -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        echo "$getlist" | tr '\n' '\0' | xargs -0 -n1 rename $DO "s/[_]+/_/g"
    fi
fi



echo
echo "#############################################"
echo "    Find preceding spaces and underscores    "
echo "#############################################"

# find -depth -regextype grep -regex ".*/[ _]\+.*" -execdir rename -n "s/\/[ _]+/\//" "{}" \;
# find -depth -regextype grep -regex ".*[ _]\+\..*" -execdir rename -n "s/[ ]+\././g" "{}" \;

## find files
getlist="$(find "$FOLDER" \
                -depth    \
                -not \( -path "*/.git*"       -prune \) \
                -not \( -path "*/inst/art/*"  -prune \) \
                -not \( -path "*/inst/as/*"   -prune \) \
                -not \( -path "*/inst/.art*"  -prune \) \
                -regextype grep -regex ".*/[ _]\+.*" )"

## print list and count
echo "$getlist" | sed '/^\s*$/d'
echo "----"
filesnum=$(echo "$getlist" | sed '/^\s*$/d' | wc -l)
echo "Files found:  $filesnum"

## rename files
if [[ $filesnum -gt 0 ]]; then
    read -p "Remove preceding spaces and underscores ? " -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        echo "$getlist" | tr '\n' '\0' | xargs -0 -n1 rename $DO "s/\/[ _]+/\//"
    fi
fi



echo
echo "#############################################"
echo "    Find subciding spaces and underscores    "
echo "#############################################"

## find files
getlist="$(find "$FOLDER" \
                -depth    \
                -not \( -path "*/.git*"       -prune \) \
                -not \( -path "*/inst/art/*"  -prune \) \
                -not \( -path "*/inst/as/*"   -prune \) \
                -not \( -path "*/inst/.art*"  -prune \) \
                -regextype grep -regex ".*[ _]\+\..*")"

## print list and count
echo "$getlist" | sed '/^\s*$/d'
echo "----"
filesnum=$(echo "$getlist" | sed '/^\s*$/d' | wc -l)
echo "Files found:  $filesnum"

## rename files
if [[ $filesnum -gt 0 ]]; then
    read -p "Remove spaces and underscores before . ? " -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        echo "$getlist" | tr '\n' '\0' | xargs -0 -n1 rename $DO "s/[ _]+\././"
    fi
fi

## find files
getlist="$(find "$FOLDER" \
                -depth    \
                -not \( -path "*/.git*"       -prune \) \
                -not \( -path "*/inst/art/*"  -prune \) \
                -not \( -path "*/inst/as/*"   -prune \) \
                -not \( -path "*/inst/.art*"  -prune \) \
                -regextype grep -regex ".*[ _]\+$" )"

## print list and count
echo "$getlist" | sed '/^\s*$/d'
echo "----"
filesnum=$(echo "$getlist" | sed '/^\s*$/d' | wc -l)
echo "Files found:  $filesnum"

## rename files
if [[ $filesnum -gt 0 ]]; then
    read -p "Remove spaces and underscores from end ? " -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        echo "$getlist" | tr '\n' '\0' | xargs -0 -n1 rename $DO "s/[ _]+$//"
    fi
fi

## find files
getlist="$(find "$FOLDER" \
                -depth    \
                -not \( -path "*/.git*"       -prune \) \
                -not \( -path "*/inst/art/*"  -prune \) \
                -not \( -path "*/inst/as/*"   -prune \) \
                -not \( -path "*/inst/.art*"  -prune \) \
                -regextype grep -regex ".*[ _]\+/.*")"

## print list and count
echo "$getlist" | sed '/^\s*$/d'
echo "----"
filesnum=$(echo "$getlist" | sed '/^\s*$/d' | wc -l)
echo "Files found:  $filesnum"

## rename files
if [[ $filesnum -gt 0 ]]; then
    read -p "Remove spaces and underscores before / ? " -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        echo "$getlist" | tr '\n' '\0' | xargs -0 -n1 rename $DO "s/[ _]+\//\//"
    fi
fi





exit 0
