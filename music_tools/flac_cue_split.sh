#!/bin/bash
## created on 2013-12-05

#### Split and add metadata to flac files from cue list
## untested

folder=$1

if [ -d "$folder" ]; then
	echo "run on $folder"
else
	echo "bad directory"
	exit
fi


#find "$folder" -type f -iname "*.cue"
find "$folder" -type f -iname "*.flac" | while read file;do
	#echo "${file%%.flac}"
	if [ -e "${file%%.flac}.cue" ];then
		echo ""
		echo "pair"
		echo "${file}"
		echo "${file%%.flac}.cue"
		mkdir "$(dirname "${file}")/output"
		cuebreakpoints "${file%%.flac}.cue" | shnsplit -d "$(dirname "${file}")/output" -o flac  "${file}"
		cp "${file%%.flac}.cue" "$(dirname "${file}")/output"
		cd "$(dirname "${file}")/output"
		cuetag *.cue split-*.flac && \
		lltag --yes  --no-tagging --rename '%n - %t' $(ls split-*.flac)
		rm "${file%%.flac}.cue"
	fi

done

# cuebreakpoints file.cue | shnsplit -o flac  file.flac
# cuetag.sh file.cue split-*.flac



exit 0 
