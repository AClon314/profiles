#!/bin/bash
PCI_GPU="01_00_0"
# libkmod: ERROR ../libkmod/libkmod-config.c:712 kmod_config_parse: /etc/modprobe.d/kvmfr.conf line 4: ignoring bad line starting with 'kvmfr'

function title {
  echo -e -n "\033]0;$*\007"
}
function yn {
  yn_text="y/n"
  case $1 in
    [Yy]) yn_text="Y/n"; default1=$1; shift 1;;
    [Nn]) yn_text="y/N"; default1=$1; shift 1;;
  esac

  while true; do
    read -p "$* [$yn_text]: " key
      case $key in
        [Yy]) return 0 ;;
        [Nn]) echo "Aborted" ; return 1 ;;
        "") if [ -n "$default1" ]; then 
            [[ "$default1" =~ [Yy] ]] && return 0 || return 1;
          fi ;;
    esac
  done
}
function Yn {
  yn Y $*
}
function yN {
  yn N $*
}

function lspci_grep {
  lspci -nnk |\
  grep "$1" --color=always &&\

  lspci -nnk |\
  grep "$1" -A 3 |\
  grep "Kernel driver in use" --color=always
}
function get_pci {
  # choose $0 of first line, with replaced ':'&'.' to '_'
  lspci_grep $* | awk 'NR==1 {print $1}' | tr ':.' '_'
}

function what_gpu {
  glxinfo | grep "vendor" --color=always # vendor=厂商
}
function len {
  lenght=0
  declare -n arr=$1 # 间接引用
  for key in "${!arr[@]}"; do
    if [[ -n "${arr[$key]}" ]]; then
      echo -e "$key\t${arr[$key]}" | grep $key --color=always > /dev/stderr
      let lenght++
    fi
  done
  echo $lenght
}
function which_gpu {
  echo "PCI_GPU=$PCI_GPU"

  declare -A GPU   #dedicated
  declare -A gpu_i #integrated
  GPU[nvidia]=$(get_pci "NVIDIA")
  if lspci_grep "Radeon" | grep Mobile > /dev/null; then
    gpu_i[amd]=$(get_pci "Radeon")
  else
    GPU[amd]=$(get_pci "Radeon")
  fi
  gpu_i[intel]=$(get_pci "Intel.*Integrated Graphics")
  
  has_GPU=$(len GPU)
  has_gpu=$(len gpu_i)
  let all_gpu=has_GPU+has_gpu
  
  if [ $all_gpu -eq 0 ]; then
    echo "No supported GPU found! check with lspci" | grep lspci
  elif [ $all_gpu -eq 1 ]; then
    # TODO: support single GPU && AMD dedicate gpu
    echo Not support Single GPU yet! but you can follow this tutorial:
    echo 🌐 https://github.com/ledisthebest/LEDs-single-gpu-passthrough/blob/main/README.md
  else
    NEW_PCI_GPU=${GPU[nvidia]}
    if [ $NEW_PCI_GPU != $PCI_GPU ]; then
      yN "change PCI_GPU=$PCI_GPU to $NEW_PCI_GPU?" && sed -i "s/PCI_GPU=\".*/PCI_GPU=\"$NEW_PCI_GPU\"/" $0
    fi
    echo "Current only support nvidia gpu for virtual machine."
  fi
}
function how_gpu {
  lspci_grep "NVIDIA"
  lspci_grep "Radeon" | grep Mobile -C 9
  lspci_grep "Intel.*Integrated Graphics"
  echo
  what_gpu
}
function enable_nvidia {
  __NV_PRIME_RENDER_OFFLOAD=1
  __GLX_VENDOR_LIBRARY_NAME=nvidia
  sudo virsh nodedev-reattach pci_0000_$PCI_GPU &&\
  echo "GPU reattached (now host ready)" &&\
  sudo rmmod vfio_pci vfio_pci_core vfio_iommu_type1 &&\
  echo "VFIO drivers removed" &&\
  sudo modprobe -i nvidia_modeset nvidia_uvm nvidia &&\
  echo "NVIDIA drivers added" &&\
  echo "COMPLETED! (confirm success with what)" | grep what
}
function disable_nvidia {
  unset __NV_PRIME_RENDER_OFFLOAD
  unset __GLX_VENDOR_LIBRARY_NAME
  sudo rmmod nvidia_modeset nvidia_uvm nvidia &&\
  echo "NVIDIA drivers removed" &&\
  sudo modprobe -i vfio_pci vfio_pci_core vfio_iommu_type1 &&\
  echo "VFIO drivers added" &&\
  sudo virsh nodedev-detach pci_0000_$PCI_GPU &&\
  echo "GPU detached (now vfio ready)" &&\
  echo "COMPLETED! (confirm success with hows-my-gpu and active-gpu)"
}
function launch_looking_glass {
  looking-glass-client -s -m 97
}
function what_dm {
  systemctl status display-manager | grep "Display Manager" -A 2
}
function help {
  echo -e "Usage:\t$0 how|enable|disable|launch|help"
}

if [ -z "$1" ]; then
  how_gpu
  echo
  help
elif [ "$1" == "what" ]; then
  what_gpu
elif [ "$1" == "config" ]; then
  which_gpu
elif [ "$1" == "enable" ]; then
  enable_nvidia
elif [ "$1" == "disable" ]; then
  disable_nvidia
elif [ "$1" == "launch" ]; then
  launch_looking_glass
elif [[ "$1" == *"h"* ]]; then
  help
elif [[ "$1" == *"l"* ]]; then
  how_gpu
else
  echo "Invalid command: $1"
  exit 1
fi
