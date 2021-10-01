#!/bin/bash
## created on 2017-07-15
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### List files without extensions

folder="$1"
: ${folder:="./"}

if [  ! -d "$folder" ];then
    echo
    echo "$folder  is not a folder"
    echo "exit"
    exit 0
fi


## gather files with no extension
results=$(find "$folder" -type f                                 \
                       -not  \(    -path "*/.git/*"              \
                                -o -path "*/.ENC/*"              \
                                -o -path "*/.PlayOnLinux/*"      \
                                -o -path "*/.Rproj.user/*"       \
                                -o -path "*/.arduino/*"          \
                                -o -path "*/.atom/*"             \
                                -o -path "*/.cache/*"            \
                                -o -path "*/.config/*"           \
                                -o -path "*/.dbus/*"             \
                                -o -path "*/.dropbox-dist/*"     \
                                -o -path "*/.gnome2/*"           \
                                -o -path "*/.googleearth/*"      \
                                -o -path "*/.icedove/*"          \
                                -o -path "*/.kde/*"              \
                                -o -path "*/.local/*"            \
                                -o -path "*/.mozilla/*"          \
                                -o -path "*/.oh-my-zsh/*"        \
                                -o -path "*/.opam/*"             \
                                -o -path "*/.rstudio-desktop/*"  \
                                -o -path "*/.temp!/*"            \
                                -o -path "*/.unison/*"           \
                                -o -path "*/.vim (copy)/*"       \
                                -o -path "*/.vim/*"              \
                                -o -path "*/DAMND/*"             \
                                -o -path "*/DESCRIPTION"         \
                                -o -path "*/Dell/*"              \
                                -o -path "*/Downloads/*"         \
                                -o -path "*/LICEN[CS]E"          \
                                -o -path "*/Libradtran/*"        \
                                -o -path "*/MOBILedit/*"         \
                                -o -path "*/NAMESPACE"           \
                                -o -path "*/PROGRAMS/*"          \
                                -o -path "*/R-Portable/*"        \
                                -o -path "*/R/*"                 \
                                -o -path "*/README"              \
                                -o -path "*/randomseed"          \
                                -o -path "*/RStudioPortable/*"   \
                                -o -path "*/Volatile/*"          \
                                -o -path "*/ZHOST/*"             \
                                -o -path "*/cache/*"             \
                                -o -path "*/model_original/*"    \
                                -o -path "*/opam/*"              \
                                -o -path "*/sketchbook/*"        \
                                -o -path "*/tinclibrary/*"       \
                                -o -path "*[Mm]akefile"          \
                                -o -path "*_cache/beamer*"       \
                                -o -path "*_cache/docx*"         \
                                -o -path "*_cache/html*"         \
                                -o -path "*_cache/latex*"        \
                                \) -prune  ! -name "*.*"  -print )


## arrays for the categories
declare -A filecnt
declare -A filelist


if [[ $(echo "$results" | wc -l) -lt 2 ]]; then
    echo
    echo "No offending files found. Exiting."
    echo "WARNING: Some filtering is applied. Not all files are shown."
    echo "         See script $0 for details."
    exit 0
fi


echo ""
cnt=0
while read line; do

    ## find type
    type="$(file -ibhp "$line" | cut -d";" -f1)"

    ## store type info
    filecnt["$type"]=$((${filecnt["$type"]}+1))
    filelist["$type"]="${filelist["$type"]}#0#${line}"

    ## display process
    printf "Checked files: %7s            \r" "$((cnt++))"

done < <(echo "$results")
echo ""
echo ""

# echo "${filecnt[@]}"
# echo "${filelist[@]}"

for key in "${!filelist[@]}"; do
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo
    echo "   ***  $key  ***   "
#     echo
    echo "${filelist["$key"]}" | sed 's/#0#/\n/g'

    echo
done

echo ""
echo "--------  File type count summary  -------- "
for key in "${!filecnt[@]}"; do
#     echo "${filecnt["$key"]} $key"
    printf "%6s  %s\n" "${filecnt["$key"]}" "$key"
done | sort -n
echo "------------------------------------------- "


# cnt=(1)
# echo "$results" | while read line; do
#     ## find text files
#     if file -b "$line" | grep -q "text"; then
#         ## check first line
#         if head -n 1 "$line" | grep -q "#!"; then
#             cnt[0]=$((cnt[0]+1))
#             printf "%3s  %-80s  %s \n" "${cnt[0]}" "$line" "$(head -n 1 "$line")"
# #             echo $((cnt++)) "$line" $(head -n 1 "$line")
# #             echo
#
#         fi
#     fi
# done

echo ""
echo "Found ${cnt[0]} files with no extension."
echo ""
echo "WARNING: Some filtering is applied. Not all files are shown."
echo "         See script $0 for details."


exit 0
