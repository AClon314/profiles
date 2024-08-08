#!/bin/bash
virsh start w11
looking-glass-client -f /dev/kvmfr0 -m KEY_NUMLOCK egl:vsync win:size=1919x1080 win:position=center -d input:grabKeyboardOnFocus
#-d borderless
# -T Maximize
# -F fullscreen
