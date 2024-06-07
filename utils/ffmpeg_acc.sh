#!/bin/bash
OUTPUT=output.mp4

V_SIZE=320x180
FPS=25
# CRF: h264; Q_V: h264_nvenc
CRF=30
Q_V=70

[ -n "$Q_V" ] && ARG_Q="-q:v $Q_V" && ARG_CV_I="-hwaccel cuda -c:v h264_cuvid" && ARG_CV_O="-c:v h264_nvenc"
[ -n "$CRF" ] && ARG_Q="-crf $CRF" && ARG_CV_I="-c:v h264" && ARG_CV_O="-c:v h264"

CMD="ffmpeg -threads 0 $ARG_CV_I 
-i $1 
-preset fast $ARG_CV_O $ARG_Q -r $FPS -s $V_SIZE 
$OUTPUT"

echo $CMD

if [[ $1 == *'.'* ]]; then
  $CMD
elif [[ $1 == 'preset' ]]; then
  ffmpeg -hide_banner -h encoder=h264_nvenc
fi