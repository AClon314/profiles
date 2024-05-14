. ./config.conf

nvidia2host() {
  for k in $GPU_KEY; do
    [[ -n ${PCI_GPU[$k]} ]] && sudo virsh nodedev-reattach "pci_0000_${PCI_GPU[$k]}" &&\
    [[ -n ${PCI_AUD[$k]} ]] && sudo virsh nodedev-reattach "pci_0000_${PCI_AUD[$k]}"
  done &&\
  echo "✔ GPU reattached" ||\
  echo "GPU reattach failed"

  sudo modprobe -r vfio_pci vfio_pci_core vfio_iommu_type1 &&\
  echo "✔ VFIO drivers removed" &&\

  sudo modprobe -i nvidia_modeset nvidia_uvm nvidia &&\
  echo "✔ NVIDIA drivers added" &&\

  ./vfio list
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
else
  about
  echo "Invalid command: $1"
  exit 1
fi
