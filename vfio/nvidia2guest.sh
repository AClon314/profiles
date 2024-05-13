. ./config.conf

nvidia2guest() {
  # rmmod
  sudo modprobe -r nvidia_modeset nvidia_uvm nvidia &&\
  echo "NVIDIA drivers removed" &&\

  # -i: --ignore-install
  sudo modprobe -i vfio_pci vfio_pci_core vfio_iommu_type1 &&\
  echo "VFIO drivers added" &&\

  sudo virsh nodedev-detach pci_0000_$PCI_GPU &&\
  echo "GPU detached (now vfio ready)" &&\

  echo "COMPLETED! confirm success with what" | grep what
  lspci_grep "NVIDIA"
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
