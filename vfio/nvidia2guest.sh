. ./config.conf

set -x
nvidia2guest() {
  # rmmod
  sudo rmmod nvidia_drm nvidia_modeset nvidia_uvm nvidia &&\
  echo "✔ NVIDIA drivers removed" || { echo "❌ NVIDIA drivers remove" && exit 1; }

  # -i: --ignore-install
  sudo modprobe -i vfio_pci vfio_pci_core vfio_iommu_type1 &&\
  echo "✔ VFIO drivers added" || { echo "❌ VFIO drivers not added" && exit 1; }

  for k in $GPU_KEY; do
    [[ -n ${PCI_GPU[$k]} ]] && sudo virsh nodedev-detach "pci_0000_${PCI_GPU[$k]}" &&\
    [[ -n ${PCI_AUD[$k]} ]] && sudo virsh nodedev-detach "pci_0000_${PCI_AUD[$k]}"
  done &&\
  echo "✔ GPU detached" ||\
  { echo "❌ GPU detach failed" && exit 1; }

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

if [ -z "$1" ]; then
  export -f nvidia2guest
elif [ "$1" == "launch" ]; then
  nvidia2guest
else
  about
  echo "Invalid command: $1"
  exit 1
fi
