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





echo "some more listings"




echo
PS3="Choose replacement character for script: "

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



## check for more panctuation

chars=( "%" "$" "#" "?" "<" ">" ":" "*" "|" '"' "'" "!" )
for ch in "${chars[@]}"; do
    echo "---------------------"
    echo "ddd $ch ddd"



    find "$FOLDER" \
         -depth    \
         -not \( -path "*/.git*"       -prune \) \
         -not \( -path "*/inst/art/*"  -prune \) \
         -not \( -path "*/inst/as/*"   -prune \) \
         -not \( -path "*/inst/.art*"  -prune \) \
         -regextype grep -regex ".*[$ch]\+.*"




done




## find some really bad characters    % $#,?<> \:*| "
## this will create multiples or replacements
#find  -depth  -execdir rename -n  's/[%\$#,?<>\\:*|\"]/_/g' "{}" \;

echo " --------Panctuation"
find "$FOLDER" \
                -depth    \
                -not \( -path "*/.git*"       -prune \) \
                -not \( -path "*/inst/art/*"  -prune \) \
                -not \( -path "*/inst/as/*"   -prune \) \
                -not \( -path "*/inst/.art*"  -prune \) \
                -regextype grep -regex ".*[%$\#?<>:*|\"'!]\+.*"

echo " ----- wierd chars"
find "$FOLDER" \
                -depth    \
                -not \( -path "*/.git*"       -prune \) \
                -not \( -path "*/inst/art/*"  -prune \) \
                -not \( -path "*/inst/as/*"   -prune \) \
                -not \( -path "*/inst/.art*"  -prune \) \
                -regextype grep ! -regex "[άέήίόύώΆΈΉΊΌΎΏ0-9a-zA-Zα-ωΑ-Ω./ '&-’—_\!]\+"
# ’`



exit 0
