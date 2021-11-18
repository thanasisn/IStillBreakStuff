#!/bin/bash
## created on 2017-09-26

#### Make filenames consistent and nice


FOLDER="$@"
echo "$FOLDER"


echo
echo "#########################################"
echo "    Simplify multiple spaces in files    "
echo "#########################################"

## find files
getlist="$( find "$FOLDER" -type f -not \( -path "*/.git*"  -prune \) \
             -name "* *" | grep "  " )"

## print list and count
echo "----"
echo "$getlist" | sed '/^\s*$/d'
echo "----"
filesnum=$(echo "$getlist" | sed '/^\s*$/d' | wc -l)
echo "Files found:  $filesnum"

## rename files
if [[ $filesnum -gt 0 ]]; then
    read -p "Simpify multiple spaces in filenames ? " -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        echo "remove spaces"
        echo "$getlist" | tr '\n' '\0' | xargs -0 -n1 rename -v "s/[ ]+/ /g"
    fi
fi



echo
echo "##############################################"
echo "    Simplify multiple underscores in files    "
echo "##############################################"

## find files
getlist="$( find "$FOLDER" -type f -not \( -path "*/.git*"  -prune \) \
             -name "*_*" | grep "__" )"

## print list and count
echo "----"
echo "$getlist" | sed '/^\s*$/d'
echo "----"
filesnum=$(echo "$getlist" | sed '/^\s*$/d' | wc -l)
echo "Files found:  $filesnum"

## rename files
if [[ $filesnum -gt 0 ]]; then
    read -p "Simpify multiple underscores in filenames ? " -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        echo "remove spaces"
        echo "$getlist" | tr '\n' '\0' | xargs -0 -n1 rename -v "s/[_]+/_/g"
    fi
fi








exit


echo
echo "########################################"
echo "    Find preceding spaces            "
echo "########################################"
echo

find "$folder" -not \( -path "*/DAMND"          -prune \) \
               -name "* *" | grep "/ "


echo
echo "########################################"
echo "    Find subciding spaces            "
echo "########################################"
echo

find "$folder" -not \( -path "*/DAMND"          -prune \) \
               -name "* *" | grep " /"
find "$folder" -not \( -path "*/DAMND"          -prune \) \
               -name "* *" | grep " $"
find "$folder" -not \( -path "*/DAMND"          -prune \) \
               -name "* *" | grep " \."




exit 0
