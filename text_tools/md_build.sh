#!/bin/bash

#### Build md files to multiple output formats

FILESIN="$@"
FIRST="$1"
NAME="${FIRST%.*}"

dauthor="Thanasis N"

echo "Files in:"
for ff in $FILESIN ; do
    if [[ ! -f $ff ]]; then
        echo "Missing file $ff"
    fi
    echo "          $ff"
done

# EXPFILES="$HOME/BASH/md_export_linked_files.sh"
# GRAPHVIZ="$HOME/BASH/TEMPLATES/graphviz3.py"
LATEXTMP="$HOME/CODE/templates/documents/md_template.tex"
DOCXTMP="$HOME/CODE/templates/documents/md_reference.docx"
HTMLCCS="$HOME/CODE/templates/documents/md_style_chmduquesne.css"
DATE="$(date +"%F")"
OUTNAME="${NAME}_$DATE"

## get some data from yml header
header="$(sed -n '/---/,/---/p' $FIRST)"

TITLE="$(echo "$header" | sed -n 's@[ ]*title:[ ]*@@p')"
TITLE="${TITLE:-$(basename "$NAME")}"

AUTHOR="$(echo "$header" | sed -n 's@[ ]*author:[ ]*@@p')"
AUTHOR="${AUTHOR:-$dauthor}"

echo
echo "$TITLE"


## create pdf with xetex ------------------------
read -p "PDF  y/n? " -n1
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   Building  PDF  "

    pandoc                                  \
        --highlight-style kate              \
        --from            markdown          \
        --to              latex             \
        --template        "$LATEXTMP"       \
        --pdf-engine      xelatex           \
        --metadata        date="`date +%F`" \
        --metadata        title="$TITLE"    \
        --metadata        author="$AUTHOR"  \
        --pdf-engine-opt -shell-escape      \
        --out            "$OUTNAME.pdf"     \
        $FILESIN

#        --listings                          \
#        --filter          "$GRAPHVIZ"       \

fi



## create odt -----------------------------------
read -p "ODT  y/n? " -n1
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   Building  ODT  "

    pandoc                               \
        --standalone                     \
        --from         markdown          \
        --to           odt               \
        --metadata     date="`date +%F`" \
        --metadata     title="$TITLE"    \
        --metadata     author="$AUTHOR"  \
        --out          "$OUTNAME.odt"    \
        $FILESIN
fi

#        --filter       "$GRAPHVIZ"       \



## create odt -----------------------------------
read -p "DOCX y/n? " -n1
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   Building  DOCX  "

    pandoc                                \
        --standalone                      \
        --from          markdown          \
        --to            docx              \
        --reference-doc "$DOCXTMP"        \
        --metadata      date="`date +%F`" \
        --metadata      title="$TITLE"    \
        --metadata      author="$AUTHOR"  \
        --out           "$OUTNAME.docx"   \
        $FILESIN
fi

#        --filter        "$GRAPHVIZ"       \



## create html ----------------------------------
read -p "HTML y/n? " -n1
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   Building  HTML  "

    pandoc                                     \
        --standalone                           \
        --self-contained                       \
        --mathml                               \
        --include-in-header  "$HTMLCCS"        \
        --metadata           date="`date +%F`" \
        --metadata           title="$TITLE"    \
        --metadata           author="$AUTHOR"  \
        --from               markdown          \
        --to                 html              \
        --out                "$OUTNAME.html"   \
        $FILESIN

#        --filter             "$GRAPHVIZ"

    read -p "WKHTMLPDF y/n? " -n1
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "   Building  PDF  "

        wkhtmltopdf                         \
            --margin-bottom      25         \
            --margin-left        20         \
            --margin-right       20         \
            --margin-top         20         \
            --title              "$TITLE"   \
            --minimum-font-size  20         \
            "$OUTNAME.html"                 \
            "${OUTNAME}_col.pdf"
    fi
fi

## clean intermediate files ---------------------
rm -rf "./graphviz-images/"
rm -rf "./_minted-input/"
