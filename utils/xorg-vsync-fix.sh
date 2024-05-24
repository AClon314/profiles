#!/bin/bash
CONF=nvidia-vsync-fix.conf
cd /etc/X11/xorg.conf.d

init() {
  sudo bash -c "cat << EOF > /etc/X11/xorg.conf.d/$CONF.bak
Section "ServerLayout"
    Identifier     "Layout0"
    Screen      0  "Screen0"
    Screen      1  "Screen1"
EndSection

Section "Device"
    Identifier     "iGPU"
    Driver         "modesetting"
    VendorName     "AMD Corporation"
    BusID          "PCI:6:0:0"
EndSection

Section "Device"
    Identifier     "dGPU"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    BusID          "PCI:1:0:0"
EndSection

Section "Screen"
    Identifier     "Screen0"
    Device         "iGPU"
EndSection

Section "Screen"
    Identifier     "Screen1"
    Device         "dGPU"
    Option "UseNvKmsCompositionPipeline" "false"
EndSection
EOF"
}

if [ -z "$1" ]; then
  ls | grep $CONF.bak &&\
  { sudo mv $CONF.bak $CONF &&\
    if zenity --question --title="已启用，需重启桌面" --text="$(ls | grep $CONF)
已启用，确定以重启桌面，请保存所有工作"; then
      systemctl restart lightdm
    fi; } ||\
  { sudo mv $CONF $CONF.bak &&\
    if zenity --question --title="已禁用，需重启桌面" --text="$(ls | grep $CONF)
已禁用，确定以重启桌面，请保存所有工作"; then
      systemctl restart lightdm
    fi; }
elif [[ "$1" == "i" ]]; then
  init
else
  echo "Usage: $0 [i]"
  echo "  i: init"
fi