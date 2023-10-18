#!/bin/bash

#### Creates a ssh tunnel and open a new vnc connection to known hosts
## works for entries configured in .ssh/config
## have to setup vnc server first on the remote to set passwd

host="$1"

## get resolution to use
resolution="$(xdpyinfo | awk '/dimensions/{print $2}' | head -n 1)"
width="$(echo $resolution | cut -d'x' -f1)"
height="$(echo $resolution | cut -d'x' -f2)"

echo "Screan Resolution"
echo $width $height


xgap="20"
ygap="50"
LPORT="5900"
width=$((width - xgap))
height=$((height - ygap))
depth="16"
if [ -z "$host" ]
then
      echo "Give a host/ip"
      exit 1
fi

echo "Remote host resolution"
echo "${width}x${height}"

## always restart xvnc
ssh "$host" "pkill  Xtightvnc; pkill Xtigervnc; vncserver  -geometry ${width}x${height} -depth $depth -localhost"

## find availble port on local host 
_check="placeholder"
while [[ ! -z "${_check}" ]]; do
    ((LPORT++))
    _check=$(ss -tulpn | grep ":${LPORT}")
done

echo "Connecting:  localhost:$LPORT -> $host:5901 "

## create ssh tunel
control="/tmp/ssh_tunnel_$LPORT"
ssh -S "$control" -L "$LPORT:localhost:5901" -f -N "$host"

## make sure tunnel dies on script end
trap "ssh -S $control -O exit $host" 0 1 2 3 6 8 14 15

## start vnc viewer session
vncviewer -passwd "$HOME/.vnc/passwd" "localhost:$LPORT"
# krdc "vnc://localhost:$LPORT"

## kill vnc server after use
ssh $host 'pkill  Xtightvnc; pkill Xtigervnc'

## clean up on abnormal exit
trap "ssh $host 'pkill  Xtightvnc; pkill Xtigervnc'" 0 1 2 3 6 8 14 15

exit


## ping all lan
# for ip in $(seq 1 254); do ping -c 1 192.168.1.$ip>/dev/null; [ $? -eq 0 ] && echo "192.168.1.$ip UP" || : ; done


