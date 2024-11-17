#!/usr/bin/env bash
## created on 2024-11-17

#### Count typographic statistics for a text file

##  For use in latex document creation
##  Manually create a text file as input with representative text

FILE="$1"

characters="$(wc --chars "$FILE"                                     | cut -d' ' -f1)"
words="$(     wc --words "$FILE"                                     | cut -d' ' -f1)"
lines="$(     wc --lines "$FILE"                                     | cut -d' ' -f1)"
maxline="$(   wc --max-line-length "$FILE"                           | cut -d' ' -f1)"
letters="$(   sed 's/[[:punct:] ]//g' "$FILE" | wc --chars           | cut -d' ' -f1)" ## remove punctuation and spaces
maxlett="$(   sed 's/[[:punct:] ]//g' "$FILE" | wc --max-line-length | cut -d' ' -f1)" ## remove punctuation and spaces

## display totals and means
echo "Target is 66 characters"
echo ""
echo "$FILE"
printf "%-18s %6s  %s\n"    " "                 "Total"        "Per line"
printf "%-18s %6s\n"        "Lines:"            "$lines"
printf "%-18s %6s  %6.2f\n" "Words:"            "$words"       "$((10**3 * words/lines))e-3"
printf "%-18s %6s  %6.2f\n" "Characters:"       "$characters"  "$((10**3 * characters/lines))e-3"
printf "%-18s %6s  %6.2f\n" "Letters:"          "$letters"     "$((10**3 * letters/lines))e-3"
printf "%-18s %6s\n"        "Max line char:"    "$maxline"
printf "%-18s %6s\n"        "Max line letters:" "$maxlett"
echo ""

## TODO add median

## create histograms
echo  "Histogram of letters"
sed 's/[[:punct:] ]//g' "$FILE" |\
  awk '{print length}'          |\
  awk '{h[$1]++}END{for(i in h){print h[i],i | "sort -rn | head -20"}}' |\
  awk '!max{max=$1;}{r="";i=s=60*$1/max;while(i-->0)r=r"#";printf "%6s %5d %s %s",$2,$1,r,"\n";}'

echo
echo  "Histogram of characters"
awk '{print length}' "$FILE"  |\
  awk '{h[$1]++}END{for(i in h){print h[i],i | "sort -rn | head -20"}}' |\
  awk '!max{max=$1;}{r="";i=s=60*$1/max;while(i-->0)r=r"#";printf "%6s %5d %s %s",$2,$1,r,"\n";}'

exit 0
