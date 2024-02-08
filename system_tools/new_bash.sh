#!/bin/bash
## https://github.com/thanasisn <natsisphysicist@gmail.com>


#### Create a new executable bash script

## catch input and make valid name
newscript="$1"
scriptname="${newscript%.sh}.sh"

if [[ -f "$scriptname" ]] ; then
   echo "file exist choose new name"
   exit 0
else
   echo "Will make:   $scriptname"

   ## bash template
   (printf "#!/usr/bin/env bash\n"
   printf "## created on $(date +%F)\n\n"
   printf "#### enter description here\n\n"
   printf 'echo "i am $0 who the hell are you"\n'
   printf 'TIC=$(date +"%%s")\n'
   printf "## start coding\n\n\n\n\n"
   printf "sleep 1\n\n\n\n\n"
   printf "## end coding\n"
   printf 'TAC=$(date +"%%s"); dura="$( echo "scale=6; ($TAC-$TIC)/60" | bc)"\n'
   printf 'printf "%%s %%-10s %%-10s %%-50s %%f\\n" "$(date +"%%F %%H:%%M:%%S")" "$HOSTNAME" "$USER" "$(basename $0)" "$dura"\n'
   printf "exit 0 \n") > "$scriptname"

   ## make executable
   chmod +x "$scriptname"
fi

exit 0
