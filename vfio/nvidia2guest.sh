#!/bin/bash
DM=lightdm # because systemctl run at /root, not /home
. ./config.conf
SELF0=$(basename $0) 
FULL0="$(readlink -f "$0")"

nvidia2guest() {
  set -x #debug

  # rmmod
  local rmmod_log=$(rmmod nvidia_drm nvidia_uvm nvidia_modeset nvidia snd_hda_intel)
  if [[ $? -eq 0 ]]; then
    echo "✔ NVIDIA drivers removed"
  else
    [[ $rmmod_log != *"is not currently loaded"* ]] && echo "❌ NVIDIA drivers remove" && return 1;
  fi

  # -i: --ignore-install
  modprobe -i vfio_pci vfio vfio_pci_core vfio_iommu_type1 &&\
  echo "✔ VFIO drivers added" || { echo "❌ VFIO drivers not added" && return 1; }

  for k in $GPU_KEY; do
    [[ -n ${PCI_GPU[$k]} ]] && virsh nodedev-detach "pci_0000_${PCI_GPU[$k]}" &&\
    [[ -n ${PCI_AUD[$k]} ]] && virsh nodedev-detach "pci_0000_${PCI_AUD[$k]}"
  done &&\
  echo "✔ GPU detached" ||\
  { echo "❌ GPU detach failed" && return 1; }

  echo "✔ COMPLETED! confirm success with list" | grep list
  ./vfio list
}
about() {
  echo "目的：无缝释放实体机的nvidia显卡，直通给虚拟机"
  echo "⚠️ 不要手动运行此脚本，这应该由qemu自动运行" | grep qemu --color=always
  echo
  echo "For: Seamlessly release nvidia gpu from host to guest"
  echo "⚠️ Don't manually run this script, this should be auto-run by qemu" | grep qemu --color=always
}
install() {
  sudo bash -c "cat << EOF > /etc/systemd/system/$SELF0.service
[Unit]
Description=$SELF0 & restart $DM

[Service]
ExecStart=$FULL0 START
Type=oneshot
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/home/$USER/.Xauthority"
EOF"
}
uninstall() {
  sudo systemctl stop $SELF0
  sudo systemctl disable $SELF0
  sudo rm /etc/systemd/system/$SELF0.service
}
start() {
  lsmod | grep nvidia > /dev/null && systemctl stop $DM
  nvidia2guest
  lsmod | grep nvidia > /dev/null || systemctl start $DM
}

if [ -z "$1" ]; then
  export -f nvidia2guest
elif [ "$1" == "launch" ]; then
  nvidia2guest
elif [ "$1" == "start" ]; then
  if ! (lsmod | grep nvidia > /dev/null) || zenity --question --title="GPU to VM-直通虚拟机: restart $DM" --text="Will restart Xorg to release the GPU. Before 'yes', please save all open files, otherwise they will be lost.
将重启Xorg以释放GPU，请先保存所有打开的文件，否则会丢失
是，将重启Xorg桌面。 Yes, restart Xorg desktop.
否，不重启，无GPU直通的普通启动。 No, skip restart, normal vm startup"; then
    systemctl start $SELF0
  else
    exit 1
  fi
elif [ "$1" == "START" ]; then
  start
elif [ "$1" == "install" ]; then
  install
elif [ "$1" == "uninstall" ]; then
  uninstall
else
  about
  echo "Invalid command: $1"
  exit 1
fi
