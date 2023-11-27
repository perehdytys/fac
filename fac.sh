#!/bin/sh

if [ -z "$3" ]; then
    case $3 in
        flac | mp3 | ogg | opus) false ;;
        *) true ;;
    esac

    cat << EOF
usage: fac [PATH_TO_FILES] [CONVERT_FROM_FORMAT] [CONVERT_TO_FORMAT] [VBR_QUALITY] --> optional numerical value

example: fac . flac ogg 8

available [CONVERT_TO_FORMAT] formats: flac, mp3, ogg, opus.

if no [VBR_QUALITY] provided, default value for (mp3 = v2; ogg = q7; opus = 192k) will be used
EOF
    exit
fi

[ "$2" = "$3" ] && echo "FFmpeg cannot edit existing files in-place" && exit

tempfile=$(mktemp -t fac.XXXXX)
find "$1" -name "*.$2" > "$tempfile"

[ -s "$tempfile" ] || { printf '\n%s\n' "no $2 files found"; exit; }

printf "Check the files before conversion [y/n]: "
read -r check
[ "$check" = 'y' ] && { less -N "$tempfile"; echo; }

printf "Convert the files [y/n]: "
read -r convert
[ "$convert" != 'y' ] && exit

trap exit SIGINT

mkdir -p ~/converted_audio || exit

case $3 in
    flac)
        codec="flac"
        extension="flac"
        options=""
        ;;
    mp3)
        codec="libmp3lame"
        extension="mp3"
        options="-q ${4:-2}"
        ;;
    ogg)
        codec="libvorbis"
        extension="ogg"
        options="-q ${4:-7}"
        ;;
    opus)
        codec="libopus"
        extension="opus"
        options="-b:a ${4:-192}k -vbr 1"
        ;;
esac

while IFS= read -r f; do
    ffmpeg -hide_banner -i "$f" -vn -y -acodec "$codec" ${options} "${f%.$2}.$extension"
done < "$tempfile"

printf '\n%s\n' "The conversion is complete"
