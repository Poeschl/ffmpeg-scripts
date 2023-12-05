#!/usr/bin/env bash
#
# This script uses ffmpeg to convert audio file (.flac prefered) to a video with a static background image and a waveform at the lower half.
#
# It can be executed on native linux or WSL with an already installed ffmpeg.
#
set -e

AUDIO_IN="$1"
STATIC_IMAGE="$2"

if [ -z "$AUDIO_IN" ]; then
  echo 'No input audio detected'
  echo 'Arguments like this are expected: ./audio2imageAndWave.sh audio.mp3 image.png'
  exit 1
fi

if [ -z "$STATIC_IMAGE" ]; then
  echo 'No static image detected'
  echo 'Arguments like this are expected: ./audio2imageAndWave.sh audio.mp3 image.png'
  exit 1
fi

if grep -qi microsoft /proc/version; then
  echo "Detected WSL environment. Expecting ffmpeg.exe on PATH."
  FFMPEG='ffmpeg.exe'
else
  FFMPEG='ffmpeg'
fi

echo "Check encoders..."
AVAILABLE_ENCODERS=$(${FFMPEG} -hide_banner -encoders)
if echo "$AVAILABLE_ENCODERS" | grep -E "cuvid|nvenc|cuda"; then
  echo "Detected hardware supported encoders. Will use h264_nvenc encoder."
  ENCODER='h264_nvenc'
else
  echo "No hardware supported encoder available in ffmpeg. Will use the libx264 encoder."
  ENCODER='libx264'
fi

# Double the white line to become thicke.

$FFMPEG \
    -i "$AUDIO_IN" \
    -loop 1 -i "$STATIC_IMAGE" \
    -filter_complex "[0:a]agate=threshold=0.05,showwaves=mode=p2p:s=1280x200:colors=black|white:scale=sqrt:r=20[wave_one]; \
      [0:a]agate=threshold=0.05,showwaves=mode=p2p:s=1280x200:colors=black|white:scale=sqrt:r=20[wave_two]; \
      [wave_one][wave_two]overlay=format=auto:y=-1[combined_waves]; \
      [1:v]scale=1280x720[scaled]; \
      [scaled][combined_waves]overlay=format=auto:y=main_h-overlay_h[output]" \
    -map "[output]" -map 0:a \
    -shortest \
    -c:v "${ENCODER}" -preset fast -pix_fmt yuv420p -b:v 2M  -c:a aac -b:a 320k -r 25 \
    "${AUDIO_IN}.mp4"

