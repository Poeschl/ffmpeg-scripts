#!/usr/bin/env bash
#
# This script uses ffmpeg to sequentially combine audio files. A will played in order of inputs one after another.
# The output is a file called `combined.flac`
#
# It can be executed on native linux or WSL with an already installed ffmpeg.
#
set -e

INPUT_FILES=( "$@" )
OUTPUT_FILE="combined.flac"

if [ -z "$INPUT_FILES" ]; then
  echo 'No input files are detected.'
  echo 'Arguments like this are expected: ./combineAudio2flac.sh audio1.flac audio2.mp3'
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

for file in "${INPUT_FILES[@]}"; do
   INPUTS="$INPUTS -i $file"
   INPUT_COUNT=$((INPUT_COUNT+1))
done

echo "Sequentially combine files: $INPUT_FILES"
set -x
$FFMPEG $INPUTS \
  -filter_complex "concat=n=${INPUT_COUNT}:v=0:a=1" \
  -vn \
  -acodec flac -b:a 800k \
  "$OUTPUT_FILE"
