#!/usr/bin/env bash
#
# This script uses ffmpeg to convert a meeting recording (with video) to an audio-only .mp3 file.
# Besides it uses some filters to improve the audio quality.
#
# It can be executed on native linux or WSL with an already installed ffmpeg.
# It uses the beguiling-drafter rnnoise model for de-noicing.
# https://github.com/GregorR/rnnoise-models/blob/master/beguiling-drafter-2018-08-30/bd.rnnn
#
set -e

INPUT_FILES=( "$@" )

if [ -z "$INPUT_FILES" ]; then
  echo 'No input files are detected.'
  echo 'Arguments like this are expected: ./meeting2podcast-audio.sh pathseekerOmgLol.webm teams.mp4'
  exit 1
fi

if grep -qi microsoft /proc/version; then
  echo "Detected WSL environment. Expecting ffmpeg.exe on PATH."
  FFMPEG='ffmpeg.exe'
else
  FFMPEG='ffmpeg'
fi

echo "Check files"
for file in "${INPUT_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "$file: exists"
  else
    echo "Could not find '$file'"
    exit 1
  fi
done

echo "Check for de-noice model"
if [ ! -f "bd.rnnn" ]; then
  wget https://raw.githubusercontent.com/GregorR/rnnoise-models/master/beguiling-drafter-2018-08-30/bd.rnnn
fi

set -x
for file in "${INPUT_FILES[@]}"; do
  echo "Process $file"
  $FFMPEG -i "$file" \
    -vn \
    -af "arnndn=mix=1:model=bd.rnnn" \
    -acodec libmp3lame \
    -b:a 320k \
    "$file.mp3"

done
