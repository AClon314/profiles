. ./config.conf

function allGPU2guest {
set -x

systemctl stop your-display-manager

echo 0 > /etc/class/vtconsole/vtcon0/bind
echo 0 > /etc/class/vtconsole/vtcon1/bind

echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

sleep 15

modprobe -r nvidia_drm
modprobe -r nvidia_uvm
modprobe -r nvidia_modeset
modprobe -r drm_kms_helper
modprobe -r nvidia
modprobe -r i2c_nvidia_gpu
modprobe -r drm

virsh nodedev-detach pci_0000_$PCI_GPU

modprobe vfio_pci
modprobe vfio
modprobe vfio_iommu_type1
modprobe vfio_virqfd

#!/bin/bash
# Helpful to read output when debugging
# set -x

# long_delay=10
# medium_delay=5
# short_delay=1
# echo "Beginning of startup!"

# function stop_display_manager_if_running {
#     # Stop dm using systemd
#     if command -v systemctl; then
#         if systemctl is-active --quiet "$1.service" ; then
#             echo $1 >> /tmp/vfio-store-display-manager
#             systemctl stop "$1.service"
#         fi

#         while systemctl is-active --quiet "$1.service" ; do
#             sleep "${medium_delay}"
#         done

#         return
#     fi

#     # Stop dm using runit
#     if command -v sv; then
#         if sv status $1 ; then
#             echo $1 >> /tmp/vfio-store-display-manager
#             sv stop $1
#         fi
#     fi
# }


# # Stop currently running display manager
# if test -e "/tmp/vfio-store-display-manager" ; then
#     rm -f /tmp/vfio-store-display-manager
# fi

# stop_display_manager_if_running sddm
# stop_display_manager_if_running gdm
# stop_display_manager_if_running lightdm
# stop_display_manager_if_running lxdm
# stop_display_manager_if_running xdm
# stop_display_manager_if_running mdm
# stop_display_manager_if_running display-manager

# sleep "${medium_delay}"

# # Unbind VTconsoles if currently bound (adapted from https://www.kernel.org/doc/Documentation/fb/fbcon.txt)
# if test -e "/tmp/vfio-bound-consoles" ; then
#     rm -f /tmp/vfio-bound-consoles
# fi
# for (( i = 0; i < 16; i++))
# do
#   if test -x /sys/class/vtconsole/vtcon${i}; then
#       if [ `cat /sys/class/vtconsole/vtcon${i}/name | grep -c "frame buffer"` \
#            = 1 ]; then
# 	       echo 0 > /sys/class/vtconsole/vtcon${i}/bind
#            echo "Unbinding console ${i}"
#            echo $i >> /tmp/vfio-bound-consoles
#       fi
#   fi
# done

# # Unbind EFI-Framebuffer
# if test -e "/tmp/vfio-is-nvidia" ; then
#     rm -f /tmp/vfio-is-nvidia
# fi

# if lsmod | grep "nvidia" &> /dev/null ; then
#     echo "true" >> /tmp/vfio-is-nvidia
#     echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind
# fi

# echo "End of startup!"
}


function about {
  echo "目的：使所有GPU直通虚拟机，会退出桌面环境，导致无界面"
  echo "⚠️ 不要手动运行此脚本，这应该由qemu自动运行" | grep qemu --color=always
  echo
  echo "For: make all GPU ready for guest virtual machine. Will kill host's display manager"
  echo "⚠️ Don't manually run this script, this should be auto-run by qemu" | grep qemu --color=always
  echo "☢️ NOT FINISHED THIS SCRIPT FUNCTION YET!🚫 DON'T RUN ME!"
}

if [ -z "$1" ]; then
  export -f allGPU2guest
elif [ "$1" == "launch" ]; then
  about
  # allGPU2guest
else
  about
  echo "Invalid command: $1"
  exit 1
fi

