#!/bin/bash
## created on 2018-12-22

#### Get meteogram and data from meteoblue and covert them

LOCATION_FILE="/dev/shm/CONKY/last_location.dat"
METEOGRAM_IMG="/dev/shm/WHEATHER/meteoblue.png"
MULTIMODE_IMG="/dev/shm/WHEATHER/meteoblue_multimodel.png"
METEOGRAM_DAT="/dev/shm/WHEATHER/meteoblue.json"
source "$HOME/.shell_variables"

set +e

## refresh if older than
OLDNESS=$((3*3600))

## Get location from file
if [[ ! -f  "$LOCATION_FILE" ]]; then
    echo "NOT EXISTING Location file : $LOCATION_FILE"
    exit 2
fi

location="$(tail -n1 "$LOCATION_FILE")"

vec=( $(echo "$location" | tr "," " ") )

DATE="${vec[*]:0:2}"
LATI="${vec[2]}"
LONG="${vec[3]}"
ELEV="${vec[4]}"
CITY="${vec[5]}"
ACCU="${vec[6]}"
TYPE="${vec[7]}"

echo "$DATE  $LATI  $LONG  $ELEV  $CITY  $ACCU  $TYPE"

## fail if coordinates are unset
: "${LATI:?}"
: "${LONG:?}"
: "${METEOBLUE_API:?}"

# https://my.meteoblue.com/packages/basic-1h_basic-day_clouds-1h?apikey=R6m9gVqJDQbMtcfu&lat=39.0061&lon=21.9953&asl=796&format=json&history_days=2

## meteogram url call
urlm="http://my.meteoblue.com/visimage/meteogram_web?apikey=${METEOBLUE_API}&lat=${LATI}&lon=${LONG}"
## data url call
# urld="http://my.meteoblue.com/packages/basic-day?apikey=${METEOBLUE_API}&lat=${LATI}&lon=${LONG}"
## multi model
# urlmm="http://my.meteoblue.com/visimage/meteogram_multiSimple?apikey=${METEOBLUE_API}&lat=${LATI}&lon=${LONG}"

## new api
urld="https://my.meteoblue.com/packages/basic-1h_basic-day_clouds-1h?apikey=${METEOBLUE_API}&lat=${LATI}&lon=${LONG}&format=json&history_days=2"

echo "$urlm"
echo "$urld"

## add elevation to url
re='^[0-9]+$'
if ! [[ $ELEV =~ $re ]] ; then
    echo "error: $ELEV Elevation not a number"
else
    urlm+="&asl=${ELEV}"
    urld+="&asl=${ELEV}"
    urlmm+="&asl=${ELEV}"
fi


## add name to location
# urlm+="&city=${CITY:-Here}"
# urld+="&city=${CITY:-Here}"



### RETRIEVE IMAGE ####

## Get image if not exist, get it end exit
if [[ ! -f "$METEOGRAM_IMG" ]]; then
    echo "Image not exist, try to get it ...."
    echo "getting from $urlm"
    curl -s -o "$METEOGRAM_IMG" "$urlm"

    convert "$METEOGRAM_IMG"            \
            -crop  675x440+30+30        \
            -fuzz 10%                   \
            -transparent '#F8F8F8' "${METEOGRAM_IMG%.*}.trans.png"

else
    echo "Existing image : $METEOGRAM_IMG"
fi


## Check if image is old and get it again
AGE=$(($(date +%s)-$(date -r "$METEOGRAM_IMG" +%s)))
if [[ $AGE -gt $OLDNESS ]]; then
    echo "Image too old ($((AGE/60)) min), try to get it ...."
    echo "getting from $urlm"
    curl -s -o "$METEOGRAM_IMG" "$urlm"

    convert "$METEOGRAM_IMG"            \
            -crop  675x440+30+30        \
            -fuzz 10%                   \
            -transparent '#F8F8F8' "${METEOGRAM_IMG%.*}.trans.png"

else
    echo "Image age      : $((AGE/60)) min"
fi






# ## Get image if not exist, get it end exit
# if [[ ! -f "$MULTIMODE_IMG" ]]; then
#     echo "Image not exist, try to get it ...."
#     echo "getting from $urlmm"
#     curl -s -o "$MULTIMODE_IMG" "$urlmm"
#
#     convert "$MULTIMODE_IMG"            \
#             -crop  675x440+30+30        \
#             -fuzz 10%                   \
#             -transparent '#F8F8F8' "${MULTIMODE_IMG%.*}.trans.png"
#
# else
#     echo "Existing image : $MULTIMODE_IMG"
# fi
#
#
# ## Check if image is old and get it again
# AGE=$(($(date +%s)-$(date -r "$MULTIMODE_IMG" +%s)))
# if [[ $AGE -gt $OLDNESS ]]; then
#     echo "Image too old ($((AGE/60)) min), try to get it ...."
#     echo "getting from $urlmm"
#     curl -s -o "$MULTIMODE_IMG" "$urlmm"
#
#     convert "$MULTIMODE_IMG"            \
#             -crop  675x440+30+30        \
#             -fuzz 10%                   \
#             -transparent '#F8F8F8' "${MULTIMODE_IMG%.*}.trans.png"
#
# else
#     echo "Image age      : $((AGE/60)) min"
# fi






### RETRIEVE DATA ####

## Get json if not exist, get it end exit
if [[ ! -f "$METEOGRAM_DAT" ]]; then
    echo "json not exist, try to get it ...."
    echo "getting from $urld"
    curl -s -o "$METEOGRAM_DAT" "$urld"
else
    echo "Existing json  : $METEOGRAM_DAT"
fi

## Check if json is old and get it again
AGE=$(($(date +%s)-$(date -r "$METEOGRAM_DAT" +%s)))
if [[ $AGE -gt $OLDNESS ]]; then
    echo "json too old ($((AGE/60)) min), try to get it ...."
    echo "getting from $urld"
    curl -s -o "$METEOGRAM_DAT" "$urld"
else
    echo "json age       : $((AGE/60)) min"
fi



### CHECK FILE SIZES ####

size=$(wc -c <"$METEOGRAM_DAT")
limit=500
if [ $size -ge $limit ]; then
    echo "$METEOGRAM_DAT is $size over $limit bytes"
else
    echo "$METEOGRAM_DAT is $size under $limit bytes"
    rm -v "$METEOGRAM_DAT"
fi

size=$(wc -c <"$METEOGRAM_IMG")
limit=5000
if [ $size -ge $limit ]; then
    echo "$METEOGRAM_IMG is $size over $limit bytes"
else
    echo "$METEOGRAM_IMG is $size under $limit bytes"
    rm -v "$METEOGRAM_IMG"
fi

## parse data
$HOME/CODE/conky/scripts/parse_Meteoblue.R

# An example API-URL with your API Key for Thessaloniki for basic-day is:
# http://my.meteoblue.com/packages/basic-day?apikey=84&lat=40.6&lon=22.0&asl=8&tz=Europe%2FAthens&city=Thessaloniki
#
# An example API-URL with your API Key for Thessaloniki for Meteogram 5-day is:
# http://my.meteoblue.com/visimage/meteogram_web?apikey=84&lat=40.6&lon=22.0&asl=8&tz=Europe%2FAthens&city=Thessaloniki
#
# The number of requests can be viewed  on the link:
# https://www.meteoblue.com/en/weather/api/show/apikey/84

#convert anno_outline.png -transparent '#ffffff' anno_outline2.png
#       convert -background transparent -fill '#87DDF0' \
#         -font  Liberation-Mono-Bold  -pointsize 15 label:"  " \

#    convert "${temp}boind_stat_${i}.png" -fuzz 5% -transparent white -fuzz 5% -transparent '#EEEEE0' "${temp}boind_stat_${i}22.png"
#     mogrify -crop 987x296+85+20 "${temp}boind_stat_${i}22.png"

# convert "${temp}bugs2.png" -crop 1029x349+150+46 -fuzz 20% -transparent "#FDFDFD" "${temp}DESKTOP/bugs2t.png"

exit 0
