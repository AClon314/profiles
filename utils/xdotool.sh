#!/bin/bash

while true; do
  if [ "$(xdotool getwindowfocus getwindowname)" == "Geometry Dash" ]; then
    # xdotool key Up
    xdotool key W
    sleep 1
  else
    xdotool key Right
    sleep 12
  fi
  sleep 0.1
done