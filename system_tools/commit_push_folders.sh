#!/bin/bash
## created on 2013-05-07

#### Auto commit and push all git repos within a folder


exec 9>"/dev/shm/$(basename $0).lock"
if ! flock -n 9  ; then
    echo "another instance of $0 is running";
    exit 1
fi


set +e

## use full paths
folders=(
    "$HOME/MANUSCRIPTS"
)


## go through main folder
for i in "${folders[@]}"; do
    echo
    echo "####  $i  ####"
    echo
    [ ! -d "$i" ] && echo "Not a folder: $i" && continue
    ## go through sub folders
    cd "$i" || return
    ls -d -- */ | while read line; do
        echo
        echo " ~ ~ $line ~ ~"
        echo
        cd "$line" || return
        ## in the git folder here
        pwd
        ## add files we care about
        find . -type f \(    -iname '*.R'   \
                          -o -iname '*.Rmd' \
                          -o -iname '*.qmd' \
                          -o -iname '*.bas' \
                          -o -iname '*.bib' \
                          -o -iname '*.c'   \
                          -o -iname '*.conf'\
                          -o -iname '*.cpp' \
                          -o -iname '*.cs'  \
                          -o -iname '*.css' \
                          -o -iname '*.dot' \
                          -o -iname '*.ex'  \
                          -o -iname '*.f90' \
                          -o -iname '*.frm' \
                          -o -iname '*.gnu' \
                          -o -iname '*.gp'  \
                          -o -iname '*.h'   \
                          -o -iname '*.jl'  \
                          -o -iname '*.list'\
                          -o -iname '*.md'  \
                          -o -iname '*.par' \
                          -o -iname '*.pbs' \
                          -o -iname '*.py'  \
                          -o -iname '*.qgs' \
                          -o -iname '*.sh'  \
                          -o -iname '*.tex' \
                          -o -iname '*.txt' \) -print0 |\
                      xargs -t -0 git add -f
        ## commit and push
        git commit -uno -a -m "Commit $(date +'%F %R')"
        git push -f
        cd "$i"
    done
done



