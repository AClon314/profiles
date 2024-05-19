#!/bin/bash
. ./config.conf
DM=lightdm
SELF0=$(basename $0) 
FULL0="$(readlink -f "$0")"

# Re-login to use NVIDIA for host
nvidia2host() {
  local VM=$(virsh list --name)
  [[ -n $VM ]] && echo "❌ VM $VM is running, please close it first" && return 1
  set -x #debug

  for k in $GPU_KEY; do
    [[ -n ${PCI_GPU[$k]} ]] && sudo virsh nodedev-reattach "pci_0000_${PCI_GPU[$k]}"
    # [[ -n ${PCI_AUD[$k]} ]] && sudo virsh nodedev-reattach "pci_0000_${PCI_AUD[$k]}"
  done &&\
  echo "✔ GPU reattached" ||\
  echo "❌ GPU reattach failed"

  sudo modprobe -r vfio_pci vfio_pci_core vfio_iommu_type1 vfio &&\
  echo "✔ VFIO drivers removed"

  sudo modprobe -i nvidia nvidia_modeset nvidia_uvm nvidia_drm &&\
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
  nvidia2host &&\
  if zenity --question --title="sudo systemctl restart $DM" --text="Will restart Xorg to release the GPU. Before 'yes', please save all open files, otherwise they will be lost.
将重启Xorg以归还GPU，请先保存所有打开的文件，否则会丢失
是，将重启Xorg
否，将忽略"; then
    sudo systemctl start $SELF0
  else
    exit 0
  fi
elif [ "$1" == "START" ]; then
  nvidia2host
  lsmod | grep nvidia && sudo systemctl restart $DM
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
