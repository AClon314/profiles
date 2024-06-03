#!/bin/bash

while true; do
  if [ "$(xdotool getwindowfocus getwindowname)" == "Geometry Dash" ]; then
    xdotool key Up
  fi
  sleep 0.1
done