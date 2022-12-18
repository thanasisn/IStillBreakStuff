#!/bin/bash
## created on 2022-12-18

#### Just a cron job to run all Makefiles 


info() { echo "$(date +%F_%T) ${SECONDS}s :: $* ::" >&1; }
LOG_FILE="/dev/shm/$(basename "$0")_$(date +%F_%T).log"
ERR_FILE="/dev/shm/$(basename "$0")_$(date +%F_%T).err"
touch "$LOG_FILE" "$ERR_FILE"
exec  > >(tee -i "${LOG_FILE}")
exec 2> >(tee -i "${ERR_FILE}" >&2)
trap 'echo $( date +%F_%T ) ${SECONDS}s :: $0 interrupted ::  >&2;' INT TERM
info "START :: $0 :: $* ::"



folders=(
    "$HOME/MISC/Notes/pandocnotes"
    "/dfds/dfsf/dfs/"
    "$HOME/MANUSCRIPTS/2022_sdr_trends"
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
    ## run make with default
    make -C "$af"
    echo "=========================="
done        



## end coding
exit 0 
