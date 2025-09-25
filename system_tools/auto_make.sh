#!/usr/bin/env bash
## created on 2022-12-18

#### Just a cron job to run Makefiles in certain folder
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
  "$HOME/CODE/R_MISC/utilities"
  "$HOME/DATA_ARC/10_TODO/JOURNAL"
  "$HOME/NOTES"
  "$HOME/NOTES/02_AREA"
  "$HOME/NOTES/03_RESOURCES"
  "$HOME/NOTES/04_ARCHIVE"
  "$HOME/NOTES/08_JOURNAL"
  "$HOME/NOTES/09_JOURNAL_WORK"
  "$HOME/NOTES/11_TRAINING"
  "$HOME/NOTES/11_TRAINING/Running"
  "$HOME/NOTES/12_WRITINGS"
  "$HOME/NOTES/Clippings"
  "$HOME/NOTES/P07_DUST"
  "$HOME/NOTES/zauto"
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
    (
        ## run make with default rule
        nice -n 19 ionice -c2 -n7 make -f ./*[Mm]akefile -C "$af"
    ) > >(tee .automake.log) 2> >(tee .automake.err >&2)
    echo "================================="
done


exit 0
