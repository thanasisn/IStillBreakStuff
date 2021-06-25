#!/bin/bash
## created on 2021-06-23

#### Scrap data from car.gr for processing


REPO="$HOME/LOGs/car_en_remp"
mkdir -p "$REPO"


## assume no more than 20 pages of results
for pp in {1..30}; do
    echo "PAGE $pp"

    ## search term
    url="https://www.car.gr/classifieds/cars/?lang=en&fs=1&condition=used&offer_type=sale&price-from=%3E4000&price-to=%3C17000&mileage-to=%3C200000&drive_type=4x4&engine_size-to=2000&euroclass=5&euroclass=6&euroclass=7&euroclass=9&pg=$pp"

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

    ## get all search results
    echo "$downlist" | while read line; do

        line="${line}?lang=en"

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
            sed '1,/  Login Free Classified/d'             |\
            sed '/Similar searches/,$d'                    |\
            sed '/^$/d'                                    |\
            sed '/(BUTTON)/d'                              |\
            sed '/\[svg+xml.*/d'                           |\
            sed 's/[_]\+/_/g'                              |\
            sed '/[ ]\+[A-Za-z0-9]\+=]/d'                  |\
            sed '/Do not send a downpayment if you have/d' |\
            sed '/-thumb-[0-9]\+/d'
        ) | iconv -c -f utf-8 -t utf-8  > "$newfile"

        ## be nice
        sleep 10s
    done
done

# echo "Run file parsing"
# "$HOME/CODE/data_tools/parse_car_gr.R"

## end coding
exit 0
