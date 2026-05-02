#!/usr/bin/env bash
## created on 2020-11-08
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Gather S.M.A.R.T. info form all system drives

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

set +x
set +e

## Variables
auser="athan"
LOGDIR="/home/$auser/LOGs/SYSTEM_LOGS/SMART"
mkdir -p "$LOGDIR"

cleanup() {
    ## make all files accessible after running as root
    chown "$auser" "$LOGDIR"
    chmod a+rw     "$LOGDIR"*
    chown "$auser" "$LOGDIR"*
}

trap cleanup 0 1 2 3 6

## Loop all NVMe
for ad in /dev/nvme[0-9]; do
  if [[ ! -e $ad ]]; then continue ; fi
  echo ""
  echo "Doing: $ad"
  ## get info we need
  data="$(sudo smartctl -a "$ad")"
  ## prepare info data
  model="$(      echo "$data" | grep -i "model number:"    | sed 's/[ ]\+/ /g' | cut -d":" -f2- | sed 's/^[ ]*//g' | sed 's/[ ]\+/-/g')"
  serial="$(     echo "$data" | grep -i "serial number:"   | sed 's/[ ]\+//g'  | cut -d":" -f2- | sed 's/^[ ]*//g' | sed 's/[ ]\+/-/g')"
  hourson="$(    echo "$data" | grep -i "Power On Hours"   | sed 's/[ ]\+/ /g' | grep -o "[0-9]\+[ ]*$")"
  minhoron="$(   echo "$data" | grep -i "Power_On_Minutes" | sed 's/[ ]\+/ /g' | cut -d" " -f11 | sed 's/h.*//g')"
  percent_used="$(echo "$data" | grep -i "Percentage Used"  | grep -oE '[0-9]+' | head -1)"
  reported_unc=$(echo "$DATA" | grep "Reported_Uncorrect" | awk '{print $10}')
  avg_pe=$(echo "$DATA" | grep "Average_PE_Cycles_TLC" | awk '{print $10}')
  media_wear=$(echo "$DATA" | grep "Media_Wearout_Indicator" | awk '{print $4}')
  ## output file
  outfile="${LOGDIR}/${model}_${serial}.smart"
  ## generate report
  (
    echo ""
    date +"====  %F %R  ===="
    echo ""
    echo "Mounted on: $(hostname)"
    echo "Device:     $ad"
    echo ""
    echo "Hours on:  $hourson"
    echo "Days on:   $((hourson/24))"
    echo "On:        $((hourson/24/365)) years  $((hourson/24 - 365*(hourson/24/365))) days"
    echo "Minutes on: $minhoron"
    if [[ -n "$percent_used" ]]; then
      echo "Estimated Life Remaining: $((100 - percent_used))%" | tee -a "$outfile"
    fi
    if [[ -n "$media_wear" ]]; then
      # Media_Wearout_Indicator - lower value = more wear
      # Value 100 = new, 0 = worn out (varies by vendor)
      LIFE_REMAINING=$media_wear
      echo "Life Remaining (Media Wear): $LIFE_REMAINING%"
    elif [[ -n "$avg_pe" ]]; then
      # Assume TLC NAND rated for 500 cycles
      LIFE_REMAINING=$(( (500 - avg_pe) * 100 / 500 ))
      [[ $LIFE_REMAINING -lt 0 ]] && LIFE_REMAINING=0
      echo "Life Remaining (PE Cycles):   $LIFE_REMAINING% (based on 500 cycle rating)"
    fi
    echo ""
    echo "** smartctl -H  (Health Status) **"
    sudo smartctl -H "$ad"
    echo ""
    echo "** smartctl -a  (All Info) **"
    sudo smartctl -a "$ad"
    echo ""
    echo "** smartctl -x **"
    sudo smartctl -x "$ad"
    echo ""
  ) | tee "$outfile"
  chmod a+rw  "$outfile"
  echo "$outfile"
done

## Loop all HDD
for ad in /dev/sd[a-z] /dev/sd[a-z][a-z]; do
  if [[ ! -e $ad ]]; then continue ; fi
  echo ""
  echo "Doing: $ad"
  ## get info we need
  data="$(sudo smartctl -a "$ad")"
  ## prepare info data
  model="$(       echo "$data" | grep -i "device model:"    | sed 's/[ ]\+/ /g' | cut -d":" -f2- | sed 's/^[ ]*//g' | sed 's/[ ]\+/-/g')"
  serial="$(      echo "$data" | grep -i "serial number:"   | sed 's/[ ]\+//g'  | cut -d":" -f2- | sed 's/^[ ]*//g' | sed 's/[ ]\+/-/g')"
  hourson="$(     echo "$data" | grep -i "Power_On_Hours"   | sed 's/[ ]\+/ /g' | grep -o "[0-9]\+[ ]*$")"
  minhoron="$(    echo "$data" | grep -i "Power_On_Minutes" | sed 's/[ ]\+/ /g' | cut -d" " -f11 | sed 's/h.*//g')"
  percent_used="$(echo "$data" | grep -i "Percentage Used"  | grep -oE '[0-9]+' | head -1)"
  reported_unc=$(echo "$DATA" | grep "Reported_Uncorrect" | awk '{print $10}')
  avg_pe=$(echo "$DATA" | grep "Average_PE_Cycles_TLC" | awk '{print $10}')
  media_wear=$(echo "$DATA" | grep "Media_Wearout_Indicator" | awk '{print $4}')
  ## output file
  outfile="${LOGDIR}/${model}_${serial}.smart"
  ## generate report
  (
    echo ""
    date +"====  %F %R  ===="
    echo ""
    echo "Mounted on: $(hostname)"
    echo "Device:     $ad"
    echo ""
    echo "Hours on:  $hourson"
    echo "Days on:   $((hourson/24))"
    echo "On:        $((hourson/24/365)) years  $((hourson/24 - 365*(hourson/24/365))) days"
    echo "Minutes on: $minhoron"
    if [[ -n "$percent_used" ]]; then
      echo "Estimated Life Remaining: $((100 - percent_used))%" | tee -a "$outfile"
    fi
    if [[ -n "$media_wear" ]]; then
      # Media_Wearout_Indicator - lower value = more wear
      # Value 100 = new, 0 = worn out (varies by vendor)
      LIFE_REMAINING=$media_wear
      echo "Life Remaining (Media Wear): $LIFE_REMAINING%"
    elif [[ -n "$avg_pe" ]]; then
      # Assume TLC NAND rated for 500 cycles
      LIFE_REMAINING=$(( (500 - avg_pe) * 100 / 500 ))
      [[ $LIFE_REMAINING -lt 0 ]] && LIFE_REMAINING=0
      echo "Life Remaining (PE Cycles):   $LIFE_REMAINING% (based on 500 cycle rating)"
    fi
    echo ""
    echo "** smartctl -H  (Health Status)**"
    sudo smartctl -H "$ad"
    echo ""
    echo "** smartctl -a  (All Info) **"
    sudo smartctl -a "$ad"
    echo ""
    echo "** smartctl -x **"
    sudo smartctl -x "$ad"
    echo ""
  ) | tee "$outfile"
  chmod a+rw  "$outfile"
  echo "$outfile"
done

exit 0
