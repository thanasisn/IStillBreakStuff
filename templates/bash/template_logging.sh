
#### A standardized logging method for bash
## Used as in in many production scripts

## vv logging block of code
SECONDS=0
info() { echo "$(date +%F_%T) ${SECONDS}s :: $* ::" >&1; }
mkdir -p "$(dirname "$0")/LOGs/"
LOG_FILE="$(dirname "$0")/LOGs/$(basename "$0")_$(date +%F_%T).log"
ERR_FILE="$(dirname "$0")/LOGs/$(basename "$0")_$(date +%F_%T).err"
touch "$LOG_FILE" "$ERR_FILE"
# chgrp -R lap_ops "$(dirname "$0")/LOGs/"
exec  > >(tee -i "${LOG_FILE}")
exec 2> >(tee -i "${ERR_FILE}" >&2)
trap 'echo $( date +%F_%T ) ${SECONDS}s :: $0 interrupted ::  >&2;' INT TERM
info "START :: $0 :: $* ::"
## ^^ logging block of code


