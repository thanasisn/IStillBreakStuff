#!/usr/bin/env bash
## created on 2023-02-05

#### Organize 'pass' entries with a uniform manner "./url/login"
## Reads "url:" and "login:" entries and move to new location
## Ignores entries with missing fields
## Ignores identical locations
## Move entries interactively
## Overwrite protection is provided by 'pass mv' question

## pass folder location
prefix="$HOME/.password-store"

while read line <&3; do
    echo " --- "
    entry="$(echo "$line" | sed 's@'"$prefix/"'@@')"
    entry="${entry%.gpg}" 
    # echo "$entry"
    cont="$(pass "$entry")"
    ## get base url
    burl="$(echo "$cont" | grep "^url:" | sed -e 's|^[^/]*//||' -e 's|^www\.||' -e 's|/.*$||')"
    ## get login
    blog="$(echo "$cont" | grep "^login:" | sed 's|login:[ ]\+||')"
    newentry="${burl}/${blog}"

    [ -z "$burl" ] && echo "empty url $entry" && continue
    [ -z "$blog" ] && echo "empty log $entry" && continue
    [ "$newentry" == "$entry" ] && echo "SKIP SAME" && continue 

    echo "OLD:  $entry"
    echo "NEW:  ${burl}/${blog}"

    echo ""
    read -p "$entry ==> $newentry ? " conf
    if   [[ $conf == "y" ]]; then
        echo "move to new location"
        pass mv "$entry" "$newentry" 
    fi

done 3< <(find "$prefix" -iname "*.gpg" | sort ) 


exit 0 
