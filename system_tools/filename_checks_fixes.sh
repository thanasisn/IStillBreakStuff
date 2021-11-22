#!/bin/bash
## created on 2017-09-26

#### Make file and folder names consistent and nice
## uses 'rename', will not overwrite


FOLDER="$@"
echo "$FOLDER"

## rename
# -d, --filename, --nopath, --nofullpath
#     Do not rename directory: only rename filename component of path.
# -n, --nono
#     No action: print names of files to be renamed, but don't rename.

## SAFE, do nothing
DO=" -n "
## will try to apply
DO=" -v "


remove_char () {
    ## search for this char
    char="$1"
    ## in this folder
    FOLDER="$2"

    [[ -z "$char"   ]] && echo "Empty search char!! EXIT"      && exit
    [[ -z "$FOLDER" ]] && echo "Empty folder variable!! EXIT"  && exit

    echo
    echo "#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#"
    echo "    REMOVE >>\"$char\"<< in filenames    "
    echo "#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#"
    ## find files
    getlist="$(find "$FOLDER" \
                    -depth    \
                    -not \( -path "*/.git*"       -prune \) \
                    -not \( -path "*/inst/art/*"  -prune \) \
                    -not \( -path "*/inst/as/*"   -prune \) \
                    -not \( -path "*/inst/.art*"  -prune \) \
                    -not \( -path "*/.Docu.enc/*" -prune \) \
                    -name "*$char*" )"
    ## print list and count
    echo "$getlist" | sed '/^\s*$/d'
    echo "----"
    filesnum=$(echo "$getlist" | sed '/^\s*$/d' | wc -l)
    echo "Files found:  $filesnum"

    ## rename files
    if [[ $filesnum -gt 0 ]]; then
        read -p "REMOVE multiple >>\"$char\"<< with >>\"$rep\"<<  in filenames ? " -r REPLY
        if [[ $REPLY =~ ^[Yy]$ ]] ; then
            echo "$getlist" | tr '\n' '\0' | xargs -0 -n1 rename $DO "s/[$char]+//g"
        fi
    fi
}

replace_with () {
    ## search for this char
    char="$1"
    ## replace it with this
    rep="$2"
    ## in this folder
    FOLDER="$3"

    [[ -z "$char"   ]] && echo "Empty search char!! EXIT"      && exit
    [[ -z "$rep"    ]] && echo "Empty replacement char!! EXIT" && exit
    [[ -z "$FOLDER" ]] && echo "Empty folder variable!! EXIT"  && exit

    echo
    echo "#########################################"
    echo "    Replace >>\"$char\"<< with >>\"$rep\"<<  in names    "
    echo "#########################################"
    ## find files
    getlist="$(find "$FOLDER" \
                    -depth    \
                    -not \( -path "*/.git*"       -prune \) \
                    -not \( -path "*/inst/art/*"  -prune \) \
                    -not \( -path "*/inst/as/*"   -prune \) \
                    -not \( -path "*/inst/.art*"  -prune \) \
                    -name "*$char*" )"
    ## print list and count
    echo "$getlist" | sed '/^\s*$/d'
    echo "----"
    filesnum=$(echo "$getlist" | sed '/^\s*$/d' | wc -l)
    echo "Files found:  $filesnum"

    ## rename files
    if [[ $filesnum -gt 0 ]]; then
        read -p "REPLACE multiple >>\"$char\"<< with >>\"$rep\"<<  in filenames ? " -r REPLY
        if [[ $REPLY =~ ^[Yy]$ ]] ; then
            echo "$getlist" | tr '\n' '\0' | xargs -0 -n1 rename $DO "s/[$char]+/$rep/g"
        fi
    fi
}


simplify_multiple () {
    rep="$1"
    FOLDER="$2"

    [[ -z "$rep"    ]] && echo "Empty replacement char!! EXIT" && exit
    [[ -z "$FOLDER" ]] && echo "Empty folder variable !! EXIT" && exit

    echo
    echo "#########################################"
    echo "    Simplify multiple >>\"$rep\"<< in files    "
    echo "#########################################"
    ## find files
    getlist="$(find "$FOLDER" \
                    -depth    \
                    -not \( -path "*/.git*"       -prune \) \
                    -not \( -path "*/inst/art/*"  -prune \) \
                    -not \( -path "*/inst/as/*"   -prune \) \
                    -not \( -path "*/inst/.art*"  -prune \) \
                    -name "*$rep*" | grep "$rep$rep" )"
    ## print list and count
    echo "$getlist" | sed '/^\s*$/d'
    echo "----"
    filesnum=$(echo "$getlist" | sed '/^\s*$/d' | wc -l)
    echo "Files found:  $filesnum"

    ## rename files
    if [[ $filesnum -gt 0 ]]; then
        read -p "Simpify multiple >>\"$rep\"<< in filenames ? " -r REPLY
        if [[ $REPLY =~ ^[Yy]$ ]] ; then
            echo "$getlist" | tr '\n' '\0' | xargs -0 -n1 rename $DO "s/[$rep]+/$rep/g"
        fi
    fi
}


## Simplify some usually recurrent characters ##

simplify_multiple " "  "$FOLDER"
simplify_multiple "_"  "$FOLDER"
simplify_multiple "\." "$FOLDER"
simplify_multiple "\-" "$FOLDER"




echo
echo "#############################################"
echo "    Find preceding spaces and underscores    "
echo "#############################################"

## TODO allow only filenames start with [a-z][A-Z][α-ω][Α-Ω][0-9]

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
echo "    Find subsiding spaces and underscores    "
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




echo
PS3="Choose replacement character : "

select opt in  space underscore dash EXIT ; do
  case $opt in
    space)       rep=" "; break    ;;
    underscore)  rep="_"; break    ;;
    dash)        rep="-"; break    ;;
    EXIT)        exit              ;;
    *)           echo "Invalid option $REPLY"   ;;
  esac
done

echo "Replacement char  >>$rep<< "



## check for more panctuation problems

## TODO doesn't work for $
## not all tested

chars=( "%" "\$" "#" "\?" "<" ">" ":" "\*" "|" '"' "'" "!" "-" "~" "^" "—" "_" " " '\' "\`" )

## remove or replace offending characters
for ch in "${chars[@]}"; do

    remove_char  "$ch"        "$FOLDER"

    ## no point to replace with the same
    [ "$ch" = "$rep" ] && continue

    replace_with "$ch" "$rep" "$FOLDER"

done


## allow only some good characters in file names
echo "----- Detect possible weird chars"

find "$FOLDER" \
    -depth    \
    -not \( -path "*/.git*"       -prune \) \
    -not \( -path "*/inst/art/*"  -prune \) \
    -not \( -path "*/inst/as/*"   -prune \) \
    -not \( -path "*/inst/.art*"  -prune \) \
    -regextype grep ! -regex "[άέήίόύώΆΈΉΊΌΎΏ0-9a-zA-Zα-ωΑ-Ω./ '&-’_\!]\+"




exit 0
