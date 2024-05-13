function nvidia2host {
  __NV_PRIME_RENDER_OFFLOAD=1
  __GLX_VENDOR_LIBRARY_NAME=nvidia
  sudo virsh nodedev-reattach pci_0000_$PCI_GPU &&\
  echo "GPU reattached (now host ready)" &&\

  sudo modprobe -r vfio_pci vfio_pci_core vfio_iommu_type1 &&\
  echo "VFIO drivers removed" &&\

  sudo modprobe -i nvidia_modeset nvidia_uvm nvidia &&\
  echo "NVIDIA drivers added" &&\

  echo "COMPLETED."
  lspci_grep "NVIDIA"
}

function about {
  echo "目的：在虚拟机关闭后，无缝释放nvidia显卡，交还给主机"
  echo "⚠️ 不要手动运行此脚本，这应该由qemu自动运行" | grep qemu --color=always
  echo
  echo "For: After vm is closed, seamlessly release nvidia gpu from guest to host"
  echo "⚠️ Don't manually run this script, this should be auto-run by qemu" | grep qemu --color=always
  echo "☢️ NOT FINISHED THIS SCRIPT FUNCTION YET!🚫 DON'T RUN ME!"
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

