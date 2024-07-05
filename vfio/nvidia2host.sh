#!/bin/bash
. ./config.conf
DM=lightdm
SELF0=$(basename $0) 
FULL0="$(readlink -f "$0")"

# dont use virsh in hooks script, which cause qemu hang !!!

# Re-login to use NVIDIA for host
nvidia2host() {
  lsmod | grep nvidia > /dev/null && echo "❌ NVIDIA drivers are loaded" && return 0

  local VM=$(tty > /dev/null && virsh list --name)
  [[ -n $VM ]] && echo "❌ VM $VM is running, please close it first" && return 1

  set -x #debug

  modprobe -r vfio_pci vfio_pci_core vfio_iommu_type1 vfio &&\
  echo "✔ VFIO drivers removed"

  for k in $GPU_KEY; do
    echo "virsh nodedev-reattach pci_0000_${PCI_GPU[$k]}, ${PCI_AUD[$k]}"
    [[ -n ${PCI_GPU[$k]} ]] && virsh nodedev-reattach "pci_0000_${PCI_GPU[$k]}"
    [[ -n ${PCI_AUD[$k]} ]] && virsh nodedev-reattach "pci_0000_${PCI_AUD[$k]}"
  done &&\
  echo "✔ GPU reattached" ||\
  echo "❌ GPU reattach failed"

  modprobe -i nvidia nvidia_modeset nvidia_uvm nvidia_drm &&\
  sudo modprobe -i snd_hda_intel &&\
  echo "✔ NVIDIA drivers added"

  # ./vfio list
}
install() {
  sudo bash -c "cat << EOF > /etc/systemd/system/$SELF0.service
[Unit]
Description=$SELF0

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
  nvidia2host
  [ $(sudo lsof -w /dev/nvidia* | grep -c 'Xorg') -eq 0 ] && systemctl restart $DM
}

about() {
  echo "目的：在虚拟机关闭后，无缝释放nvidia显卡，交还给主机"
  echo "⚠️ 不要手动运行此脚本，这应该由qemu自动运行" | grep qemu --color=always
  echo
  echo "For: After vm is closed, seamlessly release nvidia gpu from guest to host"
  echo "⚠️ Don't manually run this script, this should be auto-run by qemu" | grep qemu --color=always
}

if [ -z "$1" ]; then
  export -f nvidia2host
elif [ "$1" == "launch" ]; then
  nvidia2host
elif [ "$1" == "start" ]; then
  if zenity --question --title="GPU to host-归还实体机: restart $DM" --text="Will restart Xorg to release the GPU. Before 'yes', please save all open files, otherwise they will be lost.
将重启Xorg以归还GPU，请先保存所有打开的文件，否则会丢失
是，将重启Xorg桌面。 Yes, restart Xorg desktop.
否，不重启桌面，保留直通状态。 No, keep GPU passthrough, don't restart"; then
    start
  else
    exit 0
  fi
elif [ "$1" == "START" ]; then
  start
elif [ "$1" == "install" ]; then
  install
  # sudo systemctl enable $SELF0
elif [ "$1" == "uninstall" ]; then
  uninstall
else
  about
  echo "Invalid command: $1"
  exit 1
fi
