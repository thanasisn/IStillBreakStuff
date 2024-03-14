#!/usr/bin/env bash
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Create a new executable bash script in vim

## get input and make valid name
newscript="${1:-test_script}"
scriptname="${newscript%.sh}.sh"
goto="8"

# check file exist and create new name 
if [[ -f "$scriptname" ]] ; then
  echo "File existsi, choosisng a new name..."
  scriptname="${newscript%.sh}_$(date +'%F_%T').sh"
fi

echo "File: $scriptname"

## bash template
(printf "#!/usr/bin/env bash\n"
printf "## created on %s\n\n" "$(date +%F)"
printf "#### ..enter description here..\n\n"
printf "## start coding\n"
printf 'TIC=$(date +"%%s")\n\n\n'
printf "sleep 1\n\n\n\n\n"
printf "##  END  ##\n"
printf 'TAC=$(date +"%%s"); dura="$( echo "scale=6; ($TAC-$TIC)/60" | bc)"\n'
printf 'printf "%%s %%-10s %%-10s %%-50s %%f\\n" "$(date +"%%F %%H:%%M:%%S")" "$HOSTNAME" "$USER" "$(basename $0)" "$dura"\n'
printf "exit 0 \n") > "$scriptname"

## make executable
chmod +x "$scriptname"

## open for edit
vim -c "$goto" "$scriptname"

exit 0
