#!/bin/bash
## created on 2019-03-04

#### Extract text from pdf, doc, djv, and text files, for analysis
## The text is intentional simplified
## First why try a specific method for each file and last a general method


## input arguments
FOLDER="$1"
PAGES="$2"

## sub folder name
EXFOLDER=".textualise"
## remove output
MINSIZE=400


if [[ "$PAGES" -gt 1 ]] && [[ "$PAGES" -lt 10000 ]]; then
    echo "Got a number $PAGES"
    FORCE=true
else
    ## set default
    PAGES=${PAGES:=50}
    FORCE=false
    echo "Using default $PAGES"
fi



if [ "$1" == "-h" ] || [ "$#" -lt 1 ]; then
  echo
  echo "Usage: $0 <folder> [page lim]"
  echo
  echo "    Will scan for pdf ... files recursively and "
  echo "    export a text file of the contents of each file"
  echo "    to a hidden sub folder in the same dir as the input file."
  echo "    NOTE: resulting files have lower case original extension + .txtl to simplify globing"
  echo
  echo "    folder:   The path in which will work"
  echo
  echo "    page lim: The maximum number of pages to export (default=100). In most cases we don't need to analyze all the pages (books) or the file is small (code)"
  echo
  exit 0
fi

##
## may use  ebook-convert  from calibre
## it can convert multiple formats to multiple formats
##

## check if folder
if [[ ! -d "$FOLDER" ]]; then
    echo "$FOLDER Not a Folder, exit!"
    exit
fi

echo
echo "Working on:  $FOLDER"
echo


## iterate all sub folders
find "$FOLDER" -type f   -iname "*.pdf"      \
                  | sed 's#/[^/]*$##'        \
                  | sort -u                  \
                  | while read afolder; do

    ## export folder
    destfolder="${afolder}/$EXFOLDER"
    ## create output Folder
    mkdir -p "$destfolder"
    ## exclude from backups
    touch "$destfolder/.excludeBacula"
    echo "$afolder"

    ##-----------------------------------##
    ##  iterate pdfs in each sub folder  ##
    ##-----------------------------------##
    find "$afolder" -maxdepth 1 -type f -iname "*.pdf" \
                         | sort -u         \
                         | while read afile; do
        ## get filename and extension
        filename="$(basename "${afile}")"
        extension="${filename##*.}"
        filename="${filename%.*}"
        ## convert extension to lower
        extension="$(echo "$extension" | tr '[:upper:]' '[:lower:]')"
        ## output full path
        target="${destfolder}/$filename.$extension.txtl"

        if [[ $FORCE == true ]] || [[ ! -f "${target}" ]]; then
            printf ":: $(basename "$afile")    < < < < < < < < < < < < < < \r"
            ## export text
            pdftotext -l "$PAGES" "$afile" "$target"
            ## symplify output
            sed -i 's/\t/ /g ; s/[[:punct:]]\+/ /g ; s/[0-9]/ /g' "$target"
            sed -i -E 's/\b\w{,3}\b//g ; s/  */ /g ; s/^[ \t]*// ; s/[ \t]*$// ; /^[[:space:]]*$/d'  "$target"
            ## check output
            actualsize=$(wc -c <"$target")
            if [[ $actualsize -lt $MINSIZE ]]; then
                echo "Remove too small $target"
                rm "$target"
            fi
        else
            printf "The file exists. Skip!             \r"
        fi
    done
    echo " PDFs  Done               "

    ##------------------------------------##
    ##  iterate djvus in each sub folder  ##
    ##------------------------------------##
    find "$afolder" -maxdepth 1 -type f -iname "*.djvu" \
                                     -o -iname "*.djv"  |\
        sort -u  | while read afile; do
        ## get filename and extension
        filename="$(basename "${afile}")"
        extension="${filename##*.}"
        filename="${filename%.*}"
        ## convert extension to lower
        extension="$(echo "$extension" | tr '[:upper:]' '[:lower:]')"
        ## output full path
        target="${destfolder}/$filename.$extension.txtl"

#         echo $target
#         echo $afile

        if [[ $FORCE == true ]] || [[ ! -f "${target}" ]]; then
            printf ":: $(basename "$afile")    < < < < < < < < < < < < < < \r"
            ## export text
            djvutxt --page=1-"$PAGES" "$afile" "$target"
            sed -i 's/\t/ /g ; s/[[:punct:]]\+/ /g ; s/[0-9]/ /g' "$target"
            sed -i -E 's/\b\w{,3}\b//g ; s/  */ /g ; s/^[ \t]*// ; s/[ \t]*$// ; /^[[:space:]]*$/d'  "$target"
            ## check output
            actualsize=$(wc -c <"$target")
            if [[ $actualsize -lt $MINSIZE ]]; then
                echo "Remove too small $target"
                rm "$target"
            fi
        else
            printf "The file exists. Skip!             \r"
        fi
    done
    echo " DJVUs Done               "



    ##-----------------------------------##
    ##  iterate chms in each sub folder  ##
    ##-----------------------------------##
    find "$afolder" -maxdepth 1 -type f -iname "*.chm" |\
        sort -u  | while read afile; do
        ## get filename and extension
        filename="$(basename "${afile}")"
        extension="${filename##*.}"
        filename="${filename%.*}"
        ## convert extension to lower
        extension="$(echo "$extension" | tr '[:upper:]' '[:lower:]')"
        ## output full path
        target="${destfolder}/$filename.$extension.txt"


        ## always export whole file no PAGES options
        if [[ ! -f "${target}l" ]]; then
            printf ":: $(basename "$afile")    < < < < < < < < < < < < < < \r"
            ## export text
            ebook-convert "$afile" "$target" --max-line-length=100
            mv "$target" "${target}l"
            sed -i 's/\t/ /g ; s/[[:punct:]]\+/ /g ; s/[0-9]/ /g' "${target}l"
            sed -i -E 's/\b\w{,3}\b//g ; s/  */ /g ; s/^[ \t]*// ; s/[ \t]*$// ; /^[[:space:]]*$/d'  "${target}l"
            ## check output
            actualsize=$(wc -c <"${target}l")
            if [[ $actualsize -lt $MINSIZE ]]; then
                echo "Remove too small ${target}l"
                rm "${target}l"
            fi
        else
            printf "The file exists. Skip!             \r"
        fi
    done
    echo " CHMs Done               "


    ## iterate other file types ...

    find "$afolder" -maxdepth 1 -type f   \
                        ! -iname "*.chm"  \
                        ! -iname "*.pdf"  \
                        ! -iname "*.gif"  \
                        ! -iname "*.jpg"  \
                        ! -iname "*.jpg"  \
                        ! -iname "*.png"  \
                        ! -iname "*.djvu" |\
        sort -u  | while read afile; do

        ## check if not text and skip
        type="$(file -i $afile  | cut -d' ' -f2 | cut -d'/' -f1)"

        if [ $type != "text" ]; then
            echo "Skip non text :: $afile"
            continue
        fi

        ## get filename and extension
        filename="$(basename "${afile}")"
        extension="${filename##*.}"
        filename="${filename%.*}"
        ## convert extension to lower
        extension="$(echo "$extension" | tr '[:upper:]' '[:lower:]')"
        ## output full path
        target="${destfolder}/$filename.$extension.txt"

        ## always export whole file no PAGES options
        if [[ ! -f "${target}l" ]]; then
            printf ":: $(basename "$afile")    < < < < < < < < < < < < < < \r"
            ## export text
            cp "$afile"  "$target"

            ## dont work well some encoding problem
#             detex -l "$afile" > "$target"
            mv "$target" "${target}l"
            sed -i 's/\t/ /g ; s/[[:punct:]]\+/ /g ; s/[0-9]/ /g' "${target}l"
            sed -i -E 's/\b\w{,3}\b//g ; s/  */ /g ; s/^[ \t]*// ; s/[ \t]*$// ; /^[[:space:]]*$/d'  "${target}l"
            ## check output
            actualsize=$(wc -c <"${target}l")
            if [[ $actualsize -lt $MINSIZE ]]; then
                echo "Remove too small ${target}l"
                rm "${target}l"
            fi
        else
            printf "The file exists. Skip!             \r"
        fi
    done
done



## clean non correlated text files
echo
echo " Clean non corresponding txtl"
echo
find "$FOLDER" -type d -iname "$EXFOLDER" | while read afolder; do

    backfolder="$(dirname "${afolder}")"
#     echo $backfolder

    ## get images in each folder
    find "${afolder}" -type f -iname "*.txtl" | while read aimage; do
#         echo $aimage

        ## remove double extension
        ainame="${aimage%.*}"
        ainame="${ainame%.*}"
#         echo "find $ainame"

        ## this finds both original and textual file
        if [[ $(find "${backfolder}" -name "$(basename "$ainame").*" | wc -l) -lt 2 ]]; then
            echo "Remove extra file $aimage"
            trash-put "$aimage"
        fi

    done
done


echo " -- DONE -- "
echo 'To clean run :    find -iname ".textualise" -exec rm -r {} \; '

exit 0
