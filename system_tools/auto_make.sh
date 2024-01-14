#!/bin/bash
## created on 2022-12-18

#### Just a cron job to run all Makefiles 
## Use it mainly for document production

# allow only one instance
exec 9>"/dev/shm/$(basename $0).lock"
if ! flock -n 9  ; then
    echo "another instance is running";
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


# if [[ "$(hostname)" = "tyler" ]]; then
#     echo "$(basename "$0") is suspended in tyler!!"
#     exit
# fi

## list folders containing a makefile
folders=(
    "$HOME/BBand_LAP/JOURNAL"
    "$HOME/PANDOC/Notes/01_PROJECTS"
    "$HOME/PANDOC/Notes/01_PROJECTS/Aerosols"
    "$HOME/PANDOC/Notes/02_AREA"
    "$HOME/PANDOC/Notes/03_RESOURCES"
    "$HOME/PANDOC/Notes/04_ARCHIVE"
    "$HOME/PANDOC/Notes/08_JOURNAL"
    "$HOME/PANDOC/Notes/09_JOURNAL_WORK"
    "$HOME/PANDOC/Notes/11_TRAINING"
    "$HOME/PANDOC/Notes/11_TRAINING/Running"
    "$HOME/PANDOC/Notes/12_WRITINGS"
    "$HOME/PANDOC/Notes/Clippings"
    "$HOME/PANDOC/Notes/templates"
)

for af in "${folders[@]}"; do
    info "$af"
    if [ -d "$af" ]; then
        info "Doing: $af"
    else
        info "$af don't exist SKIP!!"
        continue
    fi
    cd "$af" || continue
    ## keep some logging on each make
    exec  > >(tee -i ".automake.log")
    exec 2> >(tee -i ".automake.err" >&2)
    ## run make with default
    nice -n 19 ionice -c2 -n7 make -f *[Mm]akefile -C "$af"
    echo "================================="
done



## end coding
exit 0 
