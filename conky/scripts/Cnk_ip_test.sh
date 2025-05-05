#!/usr/bin/env bash

#### Ping my hosts and print for conky

## Host list to check, keep all columns filled with something
##  Name   tinc          tailscale        Static IP
hosts=(
  "crane   10.12.12.1    crane.lobster-atlas.ts.net  X.X          "
  "blue    10.12.12.2    100.119.161.83              X.X          "
  "kostas  10.12.12.4    X.X                         X.X          "
  "sagan   10.12.12.5    100.101.191.106             155.207.9.214"
  "tyler   10.12.12.6    100.119.4.3                 X.X          "
  "victor  10.12.12.7    X.X                         X.X          "
  "a34     10.12.12.9    100.120.166.39              X.X          "
  "nixVM   10.12.12.88   100.67.181.21               X.X          "
  "door    10.12.12.10   X.X                         X.X          "
  "yperos  10.12.12.101  100.102.113.56              155.207.10.70"
  "Y       10.12.14.97   X.X                         X.X          "
  "mumra   X.X           100.108.41.27               X.X          "
)


## Check all hosts ips
(for hh in "${hosts[@]}"; do
  # get row
  list=($hh)
  name=${list[0]}
  printf "%s %6s " "$(date +'%s')" "$name"

  for pp in "${list[@]:1}";do
    ip="$(echo $pp | cut -d":" -f1)"
    ping -c1 "$ip"  &>/dev/null
    fping=$?
    printf "%3s " "$fping"
  done
  printf "\n"
done ) |\
## Parse results for conky
while read aa; do 
  host="$(  echo "$aa" | sed 's/[ ]\+/ /g' | cut -d' ' -f2)"
  status="$(echo "$aa" | sed 's/[ ]\+/ /g' | cut -d' ' -f3-)"
  if [[ $status = *'0'* ]]; then
    printf "\${color1}%-6s " "$host"
  else
    printf "\${color3}%-6s " "$host"
  fi
  ## color results
  echo "$aa" | sed 's/[ ]\+/ /g' | cut -d' ' -f3- |\
    sed 's/2/\${color}-/g'  |\
    sed 's/1/\${color3}N/g' |\
    sed 's/0/\${color1}Y/g'
done | sort

exit 0
