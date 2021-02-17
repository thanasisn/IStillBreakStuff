#!/bin/bash
## created on 2016-09-24

#### Get the length of filename in characters and in bytes
## Useful to find files exceeding file system limitations

folder="$1"
: ${folder:="./"}

if [  -d "$folder" ];then

    find "$folder" -type f -iname "*.*" | while read line;do
        filename="$(basename "${line}")"
        characters=$(echo -n "$filename" | wc -m)
        bytes=$(echo -n "$filename" | wc -c)
        echo "$characters   $bytes   $line"
    done

#     echo "**** unique ****"
#     find "$folder" -type f -iname "*.*" | grep -o -E "\.[^\.]+$" | awk '{print tolower($0)}' | sort -u

fi


# if [ -f "$folder" ]; then
#     echo "**** FILE: $folder ****"
#
#     echo "**** counted ****"
#     cat "$folder" | grep -o -E "\.[^\.]+$" | grep -v "/"  | awk '{print tolower($0)}' | sort | uniq -c | sort -n
#
#     echo "**** unique ****"
#     cat "$folder" | grep -o -E "\.[^\.]+$" | grep -v "/"  | awk '{print tolower($0)}' | sort -u
# fi

# find "$folder" -type f | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort | uniq -c | sort -n

# find "$folder" -type f -iname "*.*" | grep -o -E "\.[^\.]+$" | awk '{print tolower($0)}' | sort -u


exit 0
