#!/bin/bash
## created on 2021-06-23

#### Scrap data from car.gr for processing in greek


REPO="$HOME/LOGs/car_gr_repo"
mkdir -p "$REPO"


## assume no more than 20 pages of results
for pp in {1..30}; do
    echo "PAGE $pp"

    ## search term
    url="https://www.car.gr/classifieds/cars/?lang=el&fs=1&condition=used&offer_type=sale&price-from=%3E4000&price-to=%3C18000&mileage-to=%3C220000&drive_type=4x4&engine_size-to=2000&euroclass=5&euroclass=6&euroclass=7&euroclass=8&euroclass=9&pg=$pp"

    ## Diesel: &fuel_type=2

    echo
    echo "$url"
    echo

    #                  -display_charset=utf-8  \
    #                  -assume_charset=utf-8   \

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

    sleep 5s

    ## get all search results
    echo "$downlist" | while read line; do


        targetfile="$(basename $line)"
        newfile="${REPO}/${targetfile}_$(date +%F).txt"

        ## skip existing
        if [[ -e "$newfile" ]]; then
            echo "SKIP $newfile exist "
            continue
        fi

        echo "GET  $line $targetfile"

        ## get post
        POST="$(lynx -read_timeout=30        \
                     -connect_timeout=30     \
                     -dump -width 1000000    \
                     -nolist                 \
                     "$line")"

       # echo "$POST"

        ## store data for later
        (
        echo "CAPTURE DATE::$(date +%F_%T)"
        echo "$POST" |\
            sed '1,/  Σύνδεση Δωρεάν Καταχώρηση/d'        |\
            sed '/Παρόμοιες αναζητήσεις/,$d'              |\
            sed '/^$/d'                                   |\
            sed '/(BUTTON)/d'                             |\
            sed '/\[svg+xml.*/d'                          |\
            sed 's/[_]\+/_/g'                             |\
            sed '/[ ]\+[A-Za-z0-9]\+=]/d'                 |\
            sed '/Μη στέλνετε προκαταβολή αν δεν έχετε/d' |\
            sed '/-thumb-[0-9]\+/d'                       |\
            sed 's/[^*,-\\/\\:_. [:alnum:]]//g'
        ) | iconv -c -f utf-8 -t utf-8 > "$newfile"

        ## be nice
        sleep 10s
    done
done

echo "Run file parsing"
"$HOME/CODE/data_tools/parse_car_gr.R"

## end coding
exit 0
