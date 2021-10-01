#!/bin/bash
## created on 2015-11-22
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### Compress something with multiple algorithms and compression levels
## This is a method for testing the optimal options to use

testf="$1"

[[ ! -e "$testf" ]] && echo "Nothing there!" && exit 0

tar -cf - "$testf" | xz -c - > "${testf}_d.tar.xz"
for i in {1..9};do
    tar -cf - "$testf" | xz -$i -c - > "${testf}_$i.tar.xz"
done

# tar -cf - "$testf" | pxz -c - > "${testf}_d.tar.pxz"
# for i in {1..9};do
#     tar -cf - "$testf" | pxz -$i -c - > "${testf}_$i.tar.pxz"
# done

tar -cf - "$testf" | gzip -c - > "${testf}_d.tar.gz"
for i in {1..9};do
    tar -cf - "$testf" | gzip -$i -c - > "${testf}_$i.tar.gz"
done

tar -cf - "$testf" | bzip2 -c - > "${testf}_d.tar.bz2"
for i in {1..9};do
    tar -cf - "$testf" | bzip2 -$i -c - > "${testf}_$i.tar.bz2"
done

# tar -cf - "$testf" | 7z a -si  "${testf}_d.7z"
# for i in {1..9};do
#   tar -cf - "$testf" | 7z a -mx=$i -si "${testf}_$i.7z"
# done

ls -S -l "$testf"*.*

exit 0
