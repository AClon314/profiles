. ./config.conf

function allGPU2host {
set -x

sleep 10

modprobe -r vfio_pci
modprobe -r vfio
modprobe -r vfio_iommu_type1
modprobe -r vfio_virqfd

virsh nodedev-reattach pci_0000_AB_CD_E

echo 1 > /etc/class/vtconsole/vtcon0/bind
echo 1 > /etc/class/vtconsole/vtcon1/bind

echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind

modprobe nvidia
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia_drm
modprobe drm_kms_helper
modprobe i2c_nvidia_gpu
modprobe drm

sleep 10

systemctl start your-display-manager

#!/bin/bash
# set -x

# echo "Beginning of teardown!"

# sleep 10

# # Restart Display Manager
# input="/tmp/vfio-store-display-manager"
# while read displayManager; do
#   if command -v systemctl; then
#     systemctl start "$displayManager.service"
#   else
#     if command -v sv; then
#       sv start $displayManager
#     fi
#   fi
# done < "$input"

# # Rebind VT consoles (adapted from https://www.kernel.org/doc/Documentation/fb/fbcon.txt)
# input="/tmp/vfio-bound-consoles"
# while read consoleNumber; do
#   if test -x /sys/class/vtconsole/vtcon${consoleNumber}; then
#       if [ `cat /sys/class/vtconsole/vtcon${consoleNumber}/name | grep -c "frame buffer"` \
#            = 1 ]; then
#     echo "Rebinding console ${consoleNumber}"
# 	  echo 1 > /sys/class/vtconsole/vtcon${consoleNumber}/bind
#       fi
#   fi
# done < "$input"

# # Rebind framebuffer for nvidia
# if test -e "/tmp/vfio-is-nvidia" ; then
#   echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind
# fi

# echo "End of teardown!"
}
function about {
  echo "目的：释放所有直通虚拟机的GPU，交还给实体机，启动桌面"
  echo "⚠️ 不要手动运行此脚本，这应该由qemu自动运行" | grep qemu --color=always
  echo
  echo "For: release all GPU from virtual machine, return to host, start display manager"
  echo "⚠️ Don't manually run this script, this should be auto-run by qemu" | grep qemu --color=always
  echo "☢️ NOT FINISHED THIS SCRIPT FUNCTION YET!🚫 DON'T RUN ME!"
}

if [ -z "$1" ]; then
  export -f allGPU2host
elif [ "$1" == "launch" ]; then
  about
else
  about
  echo "Invalid command: $1"
  exit 1
fi

