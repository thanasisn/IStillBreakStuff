#!/bin/bash

####  Music library image maintenance

##  Use picard muzic brains and clementine to tag and organize master.
##  Check transcoded files from master to image and fix diffs with this.
##  Re-encode missing files from master to image.

## Assume lower case for extensions
## Assume filenames with no extremely bad characters
## fix with a set of renaming commands
## Assume original files are flac, wma and mp3
## Assume imaged files are all mp3
## Assume same folder structure and filenames


## Original library locations
masterdir="/home/folder/Music"
masterfil="/home/folder/Music/file.list"
mastercle="/home/folder/Music/filecle.list"
mastermis="/home/folder/Music/fileclemis.list"

## Imaged library lacations
imagedir="/media/barel/Music_img"
imagefil="/media/barel/Music_img/file.list"
imagecle="/media/barel/Music_img/filecle.list"
imagemis="/media/barel/Music_img/fileclemis.list"
commoncl="/media/barel/Music_img/fileclecom.list"


## list imaged files
find "$imagedir"  -type f     -iname '*.mp3'     | sed 's@'"$imagedir"'@@g'   > "$imagefil"
## list master files
find "$masterdir" -type f \(  -iname '*.mp3'  \
                           -o -iname '*.flac' \
                           -o -iname '*.wma'  \) | sed 's@'"$masterdir"'@@g'  > "$masterfil"

## check if the two repos are in sync

## remove path start and known extensions
cat "$imagefil"  | sed "s@$imagedir@@" | sed "s/\.mp3$//" |                                        sort > "$imagecle"
cat "$masterfil" |                       sed "s/\.mp3$//" | sed "s/\.flac$//" | sed "s/\.wma$//" | sort > "$mastercle"

## get common files
comm -12 "$mastercle" "$imagecle" > "$commoncl"

echo "Master: $(cat $mastercle | wc -l)"
echo "Image : $(cat $imagecle  | wc -l)"
echo "Common: $(cat $commoncl  | wc -l)"
echo

## exist only in master
comm -3 "$mastercle" "$imagecle" > "$imagemis"
echo "Exist in master and missing from image     :: $imagemis"
echo "$(cat $imagemis | wc -l)"
du -sh "$masterdir"
echo

## exist only in master
comm -3 "$imagecle" "$commoncl" > "$mastermis"
echo "Exist in image and don't match with master :: $mastermis"
count="$(cat $mastermis | wc -l)"
echo "$count"
du -sh "$imagedir"
echo


## remove files in image no longer on original
if [[ count -gt 0 ]]; then
    # echo "Uncomment code to clean $count files"
    cat "$mastermis" | while read line ; do
        echo  "TO RM:  ${imagedir}${line}.mp3"
        rm -v "${imagedir}${line}.mp3"
    done
fi



## Check if files in image are older than master and remove from image
cat "$masterfil" | while read original; do
    duplicate="${imagedir}${original}"
    duplicate="$(echo "$duplicate" | sed "s/\.flac$/\.mp3/" | sed "s/\.wma$/\.mp3/")"

#     echo "OR: $original"
#     echo "cp: $duplicate"

    if [[ -e "$duplicate" ]]; then
#         echo "exist"
        if [[ "$duplicate" -ot "$original" ]]; then
            echo "Remove old duplicate $duplicate"
            ## remove old dups in order to reencode with newer version
            rm -v "$duplicate"
        fi
    fi
done

echo
echo "Convert playlist for image library"
$HOME/CODE/music_tools/convert_m3u_playlists.sh


exit 0
