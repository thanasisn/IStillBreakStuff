#!/bin/bash

#### Create a dot graph of tinc netowork

mkdir="/dev/shm/CONKY"
infile="/dev/shm/tinc.dot"
outfile="/dev/shm/CONKY/tincb.dot"
imagefile="/dev/shm/CONKY/tincb.png"

if [[ -e $infile ]]; then
    echo "file exist"
    mkdir -p "$mkdir"
else
    echo "not existing file"
    exit
fi

cp "$infile" "$outfile"


## Edit labels
toreplase=( 'label = "crane"'
            'label = "blue"'
            'label = "joder"'
            'label = "kostas"'
            'label = "sagan"'
            'label = "tyler"'
            'label = "yperos"'
            )

replase=( 'label = "crane\\n12.1",    fillcolor="#0E0E0E"'
          'label = "blue\\n12.2",     fillcolor="#1D1D1D"'
          'label = "Y\\n14.97",       fillcolor="#545454"'
          'label = "kostas\\n12.4",   fillcolor="#1D1D1D"'
          'label = "sagan\\n12.5",    fillcolor="#1D1D1D"'
          'label = "tyler\\n12.6",    fillcolor="#0E0E0E"'
          'label = "yperos\\n12.101", fillcolor="#1D1D1D"'
          )

# echo "replace with pretty names"
for rr in "${!toreplase[@]}"; do
#     echo "${toreplase[rr]} -> ${replase[rr]}"
    sed -i 's^'"${toreplase[rr]}"'^'"${replase[rr]}"'^g' $outfile
done


## Change some graph options
options='{\n\tconcentrate=true;\n\trankdir=LR;\n\tnode [shape=box, fontcolor="#AFAFAF", fontsize=14, color="#6060605f" style=filled fillcolor="#6060605f"]\n\tgraph [ bgcolor="#ffffff00"]\n\tedge [color="#6B6B6B", penwidth=1]'
sed -i 's^{^'"$options"'^g' $outfile


## Create graph the image
# echo "create graph"
# cat $outfile

unflatten -c 4 "$outfile" | dot -Tpng -o "$imagefile"

exit 0
