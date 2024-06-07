#!/bin/bash
INPUT=$(basename "$1")
IN_DIR=$(dirname "$1")

function find_name_args() {
  declare -a SUB_SUFFIX=("srt" "ass" "ssa")
  RESULT=""
  for suffix in "${SUB_SUFFIX[@]}"; do
    if [ -z "$RESULT" ]; then
      RESULT="-name \"${INPUT%.*}.$suffix\""
    else
      RESULT="$RESULT -o -name \"${INPUT%.*}.$suffix\""
    fi
  done
  echo $RESULT
}
# 查找同名字幕文件
SUBTITLE=$(eval find "$IN_DIR" -maxdepth 1 -type f $(find_name_args) -not -name "$INPUT" | head -n 1)
[ -n "$SUBTITLE" ] && ARG_SUB="-vf subtitles=$SUBTITLE"

# OUT_DIR="$IN_DIR/" # comment this line to output to the script directory
OUTPUT=${2:-"${OUT_DIR}${INPUT%.*},.mp4"}
fps=20

v_scale=5 # default: 1
# v_size=320x180

# crf: h264; q_v: h264_nvenc
crf=26
q_v=70

[[ -n "$v_scale" && "$v_scale" -gt 0 ]] && ARG_v_size="-vf scale=iw/$v_scale:ih/$v_scale"
[ -n "$v_size" ] && ARG_v_size="-s $v_size"

[ -n "$q_v" ] && ARG_Q="-q:v $q_v" && ARG_CV_I="-hwaccel cuda -c:v h264_cuvid" && ARG_CV_O="-c:v h264_nvenc"
[ -n "$crf" ] && ARG_Q="-crf $crf" && ARG_CV_I="-c:v h264" && ARG_CV_O="-c:v h264"

CMD="ffmpeg -threads 0 $ARG_CV_I 
-i $1 
-preset fast $ARG_CV_O $ARG_Q -r $fps $ARG_v_size
$OUTPUT"

echo $CMD

if [[ $1 == *'.'* ]]; then
  $CMD
elif [[ $1 == 'preset' ]]; then
  ffmpeg -hide_banner -h encoder=h264_nvenc
fi