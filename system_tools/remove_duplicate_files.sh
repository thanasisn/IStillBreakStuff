#!/bin/bash
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### find duplicate files with fdupes and remove them by matching patter
## operates in the same folder and asks for pattern to grep files to delete
## deletes empty folders on every execution

foll=$1
echo $foll > /dev/shm/afolder

dupl_pass() {
## search given folder for duplicate files
## add remove based on pattern

folder="$1"
patern1="$2"
delfiles=0
n=0

fdupes -r "$folder"  | while read line; do         # operate on dups files
    # operates on every block of text
    if [[ -z $line ]]; then                        # if empty line, increment array and move on to the next line.
        (( n++ ))

        kk=0
        keep=0
        for i in $(seq ${#array[@]}); do
            #echo $i
            if $(echo "${array[$i]}" | grep -q "$patern1") ; then
                (( kk++ ))                         # count  matches
                keep=$i                            # saves last index
            fi
        done

    if [[ $keep -ne 0 ]]; then                     # delete last pattern matched file
        echo "remove $(echo "${array[$keep]}" )"
        trash-put "$(echo "${array[$keep]}" )" && (( delfiles++ ))
        # rm "$(echo "${array[$keep]}" )" && (( delfiles++ ))
    fi

    i=0
    unset $array                                   # initialize new array for block
    echo "block $n"

    else
        (( i++ ))
        array[i]="$line"                           # store line to array block
    fi

   echo "$delfiles" > /dev/shm/acounter            # save var for # of deleted files
done
echo "$(cat "/dev/shm/acounter") files DELETED"
}




## main logic

echo "1" > "/dev/shm/acounter"                     # initialize while loop
while [[ $(cat "/dev/shm/acounter") -ne 0 ]] ; do  # run if there are still dups

    foll=${foll:-"empty"}
    foll=$(cat /dev/shm/afolder)                    # get folder var

    if [[ -d $foll ]]; then
        echo "valid dir $foll"
        find $foll -type d -empty -exec rmdir {} \; &> /dev/null  # remove empty dirs
        fdupes -r "$foll"                            # show dups
        candit=$(fdupes -r "$foll" | wc -l)
        echo "$candit dup canditates"
        [[ $candit -eq 0 ]] && exit 0                # exit if no dups
        echo $candit > /dev/shm/acounter             # while loop variable
    else
        echo "$foll not a valid directory"           # give dir if not set
        read -p "Give directory to search: " foll
    fi

    read -p "Insert pattern to delete (will grep it): " patttt
    dupl_pass "$foll" "$patttt"                     # run and delete
    echo "run in  $foll  for   $patttt"
done

exit 0
