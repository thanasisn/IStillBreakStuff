#!/bin/bash
## created on 2020-02-08

#### Export all frames of a video and or rotate frames


vfile="$1"
fps="${2:-30}"
rot="${3:-0}"

echo "Usage: $0 <video file> [fps (2)] [frame rotation degrees (0)]"

outdir="${vfile}_frames"
mkdir -p "$outdir"


## Export all frames
ffmpeg -i "$vfile" -r "$fps" "${outdir}/Frame_%06d.png"


## Rotate frames
if [[ $rot -ne 0 ]]; then
    echo "Rotate $rot"
    mogrify -rotate "$rot" "${outdir}/Frame*.png"
fi

exit 0
