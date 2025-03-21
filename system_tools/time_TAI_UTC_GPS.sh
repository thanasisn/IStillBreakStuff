#!/usr/bin/env bash
## created on 2017-09-11

#### Display different time coordinates

while true; do

  tt="
  $(date   +"  week: %w,  DOY: %j,  %A  %B")
    local:    $(date +"%F %T")
    UTC  :    $(TZ='UTC' date +"%F %T")
    GPS  :    $(TZ='UTC' date --date='TZ="../leaps/UTC" now -9 seconds' +"%F %T")
    LORAN:    $(TZ='UTC' date --date='TZ="../leaps/UTC" now' +"%F %T")
    TAI  :    $(date -u -d @$(TZ='right/UTC' date --date="$(TZ="posix/UTC" date -d "now + 10 seconds")" +%s) +"%F %T")
    epoch:    $(date +%s)
  "
  echo "$tt"

  sleep 0.2
  clear
done

