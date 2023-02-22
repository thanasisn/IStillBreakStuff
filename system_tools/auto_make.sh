#!/bin/bash
## created on 2022-12-18

#### Just a cron job to run all Makefiles 


info() { echo "$(date +%F_%T) ${SECONDS}s :: $* ::" >&1; }
LOG_FILE="/dev/shm/$(basename "$0")_$(date +%F).log"
ERR_FILE="/dev/shm/$(basename "$0")_$(date +%F).err"
touch "$LOG_FILE" "$ERR_FILE"
exec  > >(tee -i "${LOG_FILE}")
exec 2> >(tee -i "${ERR_FILE}" >&2)
trap 'echo $( date +%F_%T ) ${SECONDS}s :: $0 interrupted ::  >&2;' INT TERM
info "START :: $0 :: $* ::"


if [[ "$(hostname)" = "tyler" ]]; then
    echo "$(basename "$0") is suspended for now!!"
    exit
fi


folders=(
    "$HOME/CS_id"
    "$HOME/MANUSCRIPTS/2022_sdr_trends"
    "$HOME/MISC/Redmi7_internal/documents"
    "$HOME/PANDOC/Journal"
    "$HOME/PANDOC/Notes"
    "$HOME/PANDOC/Notes_Aerosols"
    "$HOME/PANDOC/Thesis"
)

for af in "${folders[@]}"; do
    info "$af"
    if [ -d "$af" ]; then
        : 
        # echo "$af exist"
    else
        info "$af don't exist SKIP!!"
        continue
    fi  
    cd "$af"
    ## run make with default
    make -f *[Mm]akefile -C "$af"
    echo "================================="
done        



## end coding
exit 0 
