#!/bin/bash

#### Short images in folders according to brightness
## The limits are fine adjusted for my specific use case scenario.

folder="$1"
: ${folder:="./"}

echo $folder
if [[ -d "$folder" ]]; then
    echo ""
else
    echo "NOT VALID FOLDER!"
    exit
fi

folder0="${folder}/step0"
folder1="${folder}/step1"
folder2="${folder}/step2"
folder3="${folder}/step3"
folder4="${folder}/step4"


mkdir -p "$folder0"
mkdir -p "$folder1"
mkdir -p "$folder2"
mkdir -p "$folder3"
mkdir -p "$folder4"


step0="0.15" 
step1="0.375" 
step2="0.50" 
step3="4.00" 

c0=0
c1=0
c2=0
c3=0
c4=0

echo "|    0 |    1 |    2 |    3 |    4 |  TOT  |"
echo "|------+------+------+------+------+-------|"

find "$folder" -maxdepth 1 -type f  | while read line ; do
    #echo $line
    brigth=$(convert  "$line"  -colorspace hsb  -resize 1x1  txt:- |\
                grep -o ",[.0-9]*%)$" |\
                grep -o "[.0-9]*")
    if   (( $(echo "$brigth < $step0" |bc -l) )); then
#       echo "0 $brigth"
        c0=$((c0+1))
        mv "$line" "$folder0"
    elif (( $(echo "$brigth < $step1" |bc -l) )); then
#       echo "1 $brigth"
        c1=$((c1+1))
        mv "$line" "$folder1"
    elif (( $(echo "$brigth < $step2" |bc -l) )); then
#       echo "2 $brigth"
		c2=$((c2+1))
 		mv "$line" "$folder2"
	elif (( $(echo "$brigth < $step3" |bc -l) )); then
# 		echo "3 $brigth"
		c3=$((c3+1))
 		mv "$line" "$folder3"
	else
# 		echo "4 $brigth"
		c4=$((c4+1))
 		mv "$line" "$folder4"
	fi
	
	printf "| %4d | %4d | %4d | %4d | %4d | %5d | \r" $c0 $c1 $c2 $c3 $c4 $((c0+c1+c2+c3+c4))
done

echo 
echo "finished"


exit 0
