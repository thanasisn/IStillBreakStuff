#!/bin/bash
## created on 2021-06-23

#### Scrap data from car.gr for processing


REPO="$HOME/LOGs/car_gr_repo"
mkdir -p "$REPO"


## assume no more than 20 pages of results
for pp in {1..20}; do
    echo "PAGE $pp"

    ## search term
    url="https://www.car.gr/classifieds/cars/?fs=1&condition=used&price-from=%3E4000&price-to=%3C15000&mileage-to=%3C175000&fuel_type=2&drive_type=4x4&euroclass=6&euroclass=7&euroclass=9&pg=$pp"

    ## get search results
    downlist="$(lynx -read_timeout=30        \
                     -connect_timeout=30     \
                     -dump -width 1000000    \
                     "$url"                 |\
                     grep "cars/view"       |\
                     grep -o "http.*"       |\
                     sort -u                 )"

    res="$(echo "$downlist" | wc -l)"
    if [[ "$res" -le 1 ]]; then
        echo "No results"
        continue
    fi

    ## get all search results
    echo "$downlist" | while read line; do
        echo "Reading $line"

        targetfile="$(basename $line)"
        newfile="${REPO}/${targetfile}_$(date +%F)"

        ## skip existing
        if [[ -e "$newfile" ]]; then
            echo "SKIP $newfile exist "
            continue
        fi

        ## get post
        POST="$(lynx -read_timeout=30        \
             -connect_timeout=30     \
             -dump -width 1000000    \
             -nolist                 \
             "$line")"

        ## store data for later
        (
        echo ""
        echo "CAPTURE DATE::$(date +%F_%T)"
        echo ""
        echo "$POST" |\
            sed '/Παρόμοιες αναζητήσεις/,$d'
        ) > "$newfile"

        ## be nice
        sleep 10s
    done
done

## end coding
exit 0
