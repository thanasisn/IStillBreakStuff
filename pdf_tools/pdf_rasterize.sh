#!/bin/bash
## created on 2017-09-28

#### Get a pdf file and create a rasterized version of it
## output one file with some metadata and one without


## get options
while getopts d:p:q: option
do
        case "${option}"
        in
            d) DENSITY=${OPTARG};;
            p) PATHpdf=${OPTARG};;
            q) quality=${OPTARG};;
        esac
done
if [ $OPTIND -eq 1 ]; then
    echo "No options were given"
    echo "usage:"
    echo ""
    echo "$(basename $0) -d <raster density> -q <jpeg quality> -p <path to file> "
    echo ""
    exit
fi


## check input resolution sanity
if [[ ${DENSITY} -gt "29" && ${DENSITY} -lt "601" ]]; then
    echo "${DENSITY} pixel density"
else
    echo "${DENSITY} is ridiculous density"
    echo "exit.."; exit 1
fi

if [[ ${quality} -gt "1" && ${quality} -lt "101" ]]; then
    echo "${quality} jpg quality"
else
    echo "${quality} is ridiculous density"
    echo "exit.." ; exit 2
fi

## check target path sanity
if [[ -f ${PATHpdf} ]]; then
    echo "Input file: ${PATHpdf}"
else
    echo "nothing is there:  ${PATHpdf}"
    echo "exit.."; exit 1
fi


## temp folder
mkdir -p "/dev/shm/temppdf"


echo "${PATHpdf%.*}_D${DENSITY}Q${quality}.pdf"
echo "${PATHpdf%.*}_D${DENSITY}Q${quality}BM.pdf"

## create images in temp folder
gs -sDEVICE=jpeg                       \
   -o "/dev/shm/temppdf/Bar_%04d_.jpg" \
   -dJPEGQ="${quality}"                \
   -r"${DENSITY}x${DENSITY}"           \
   -sPAPERSIZE=a4                      \
   "${PATHpdf}"


## create new pdf without metadata
img2pdf -o "${PATHpdf%.*}_D${DENSITY}Q${quality}.pdf" $(ls "/dev/shm/temppdf/"*.jpg)

## capture file metadata contents etc.
pdftk "${PATHpdf}" dump_data_utf8 output "/dev/shm/temppdf/Ddump"
## create new pdf with metadata
pdftk "${PATHpdf%.*}_D${DENSITY}Q${quality}.pdf" \
      update_info_utf8 "/dev/shm/temppdf/Ddump"  \
      output "${PATHpdf%.*}_D${DENSITY}Q${quality}BM.pdf"


## check output
if [[ -f "${PATHpdf%.*}_D${DENSITY}Q${quality}BM.pdf" ]]; then
    echo "Created: ${PATHpdf%.*}_D${DENSITY}Q${quality}BM.pdf"
else
    echo "Something is wrong, missing:  ${PATHpdf%.*}_D${DENSITY}Q${quality}_BM.pdf"
fi

## check output
if [[ -f "${PATHpdf%.*}_D${DENSITY}Q${quality}.pdf" ]]; then
    echo "Created: ${PATHpdf%.*}_D${DENSITY}Q${quality}.pdf"
else
    echo "Something is wrong, missing:  ${PATHpdf%.*}_D${DENSITY}Q${quality}.pdf"
fi

## cleanup temp files
rm -r "/dev/shm/temppdf"


exit 0
