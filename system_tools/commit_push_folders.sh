#!/usr/bin/env bash
## created on 2013-05-07
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Auto commit and push all git repos within a folder

exec 9>"/dev/shm/$(basename $0).lock"
if ! flock -n 9  ; then
    echo "another instance of $0 is running";
    exit 1
fi

info() { echo "$(date +%F_%T) ${SECONDS}s :: $* ::" >&1; }
LOG_FILE="/dev/shm/$(basename "$0")_$(date +%F).log"
ERR_FILE="/dev/shm/$(basename "$0")_$(date +%F).err"
touch "$LOG_FILE" "$ERR_FILE"
exec  > >(tee -i "${LOG_FILE}")
exec 2> >(tee -i "${ERR_FILE}" >&2)
trap 'echo $( date +%F_%T ) ${SECONDS}s :: $0 interrupted ::  >&2;' INT TERM
info "START :: $0 :: $* ::"

set +e

## use full paths
folders=(
)


## go through main folder
for i in "${folders[@]}"; do
    echo
    info " $i "
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
        find . -type f \(    -iname '*.R'        \
                          -o -iname '*.bas'      \
                          -o -iname '*.bib'      \
                          -o -iname '*.c'        \
                          -o -iname '*.conf'     \
                          -o -iname '*.cpp'      \
                          -o -iname '*.cs'       \
                          -o -iname '*.css'      \
                          -o -iname '*.dia'      \
                          -o -iname '*.dot'      \
                          -o -iname '*.ex'       \
                          -o -iname '*.f90'      \
                          -o -iname '*.frm'      \
                          -o -iname '*.gnu'      \
                          -o -iname '*.gp'       \
                          -o -iname '*.h'        \
                          -o -iname '*.jl'       \
                          -o -iname '*.list'     \
                          -o -iname '*.makefile' \
                          -o -iname '*.md'       \
                          -o -iname '*.par'      \
                          -o -iname '*.pbs'      \
                          -o -iname '*.py'       \
                          -o -iname '*.qgs'      \
                          -o -iname '*.qmd'      \
                          -o -iname '*.r'        \
                          -o -iname '*.rmd'      \
                          -o -iname '*.sh'       \
                          -o -iname '*.tex'      \
                          -o -iname '*.txt'      \) -print0 |\
                      xargs -t -0 git add
        ## commit and push
        git commit -uno -a -m "Commit $(date +'%F %R')"
        git push -f
        git push --tag
        cd "$i"
    done
done



