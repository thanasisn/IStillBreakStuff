#!/bin/bash
## created on 2021-04-02

#### Download youtube playlists as mp3

PLAYLISTS="$HOME/CODE/music_tools/playlists.list"
REPO="$HOME/CODE/music_tools/downloaded.list"
FOLDER="/home/folder/Music/youtube_playlists/"

cat "$PLAYLISTS" | sed '/^$/d' | sed '/^[ \t]*#/d'  | while read line; do
    # echo $line

    IDC="$(echo "$line" | cut -d';' -f1 | sed 's/^[ \t]*//;s/[ \t]*$//')"
    name="$(echo "$line" | cut -d';' -f2 | sed 's/^[ \t]*//;s/[ \t]*$//')"
    rest="$(echo "$line" | cut -d';' -f3- | sed 's/^[ \t]*//;s/[ \t]*$//')"

    target="$FOLDER/$name"

    mkdir -p "$target"
    cd "$target"

    echo "$IDC $name $rest"

    youtube-dl --download-archive "$REPO" --audio-format mp3 -xiwc "$IDC"

done



exit 0
