#!/bin/bash
. ./config.conf

BASE0=$(basename $0) 
FULL0="$(readlink -f "$0")"
DIR0=$(dirname $FULL0)

lspci_grep() {
  lspci -nnk |\
  grep "$1" --color=always &&\

  lspci -nnk |\
  grep "$1" -A 3 |\
  grep "Kernel driver in use" --color=always
}
get_pci() {
  nr=${2:-1}
  # choose $0 of first line, with replaced ':'&'.' to '_'
  lspci_grep $1 | awk -v nr="$nr" 'NR==nr {print $1}' | tr ':.' '_'
}
get_v_d () {
  nr=${2:-1}
  lspci_grep $1 | awk -v nr="$nr" 'NR==nr {match($0, /\[[0-9a-f]{4}:[0-9a-f]{4}\]/); print substr($0, RSTART+1, LLENGTH+9)}'
}
len() {
  lenght=0
  declare -n arr=$1 # 间接引用
  for key in "${!arr[@]}"; do
    if [[ -n "${arr[$key]}" ]]; then
      # echo -e "$key\t${arr[$key]}" | grep $key --color=always > /dev/stderr
      let lenght++
    fi
  done
  echo $lenght
}
what_dm() {
  systemctl status display-manager | grep "Display Manager" -A 2
}
what_gpu() {
  __NV_PRIME_RENDER_OFFLOAD=1
  __GLX_VENDOR_LIBRARY_NAME=nvidia
  glxinfo | grep "vendor" --color=always # vendor=厂商
}
dialog_choice() {
  echo $GPU_KEY

  local options=()
  for key in "${!PCI_GPU[@]}"; do
    [[ "${GPU_KEY[*]}" =~ $key ]] && default="on" || default="off"
    [[ -n ${PCI_GPU[$key]} ]] && options+=("$key" "${PCI_GPU[$key]}" $default)
  done

  cmd=(dialog --keep-tite --separate-output --checklist "$1" 0 0 0)
  CHOICES=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
  CHOICES=$(echo "$CHOICES" | tr '\n' ' ' | sed 's/.$//')
}
select_gpu() {
  has_GPU=$(len PCI_GPU)
  
  if [ $has_GPU -eq 0 ]; then
    echo "No supported GPU found! run lspci" | grep lspci
  elif [ $has_GPU -eq 1 ]; then
    # TODO: support single GPU && all gpu separated
    echo Not support Single GPU yet! but you can follow this tutorial:
    echo 🌐 https://github.com/ledisthebest/LEDs-single-gpu-passthrough/blob/main/README.md
  else
    which dialog > /dev/null || (
      . /etc/os-release
      echo "❌ $PRETTY_NAME not support dialog, edit ./config.conf manually!" && exit 1)
    dialog_choice "Select GPU to passthrough"
    if [[ -n $CHOICES ]]; then
      sed -i "s/GPU_KEY=\(.*\)/GPU_KEY=\($CHOICES\)/g" ./config.conf
    fi
  fi
  . ./config.conf
}
how_gpu() {
  lspci_grep "NVIDIA"
  lspci_grep "Radeon" | grep Mobile -C 9
  lspci_grep "Intel.*Integrated Graphics"
}
config_gpu() {
  config PCI_GPU[nvidia] $(get_pci "NVIDIA")
  config PCI_AUD[nvidia] $(get_pci "NVIDIA" 2)
  config V_D_GPU[nvidia] $(get_v_d "NVIDIA")
  config V_D_AUD[nvidia] $(get_v_d "NVIDIA" 2)

  if lspci_grep "Radeon" | grep Mobile > /dev/null; then
    i="_i"
  fi
  config PCI_GPU[amd$i] $(get_pci "Radeon")
  config V_D_GPU[amd$i] $(get_v_d "Radeon")
  config V_D_AUD[amd$i] $(get_v_d "Radeon")

  config PCI_GPU[intel] $(get_pci "Intel.*Integrated Graphics"| awk '{print $1}')
  config V_D_GPU[intel] $(get_v_d "Intel.*Integrated Graphics")
  config V_D_AUD[intel] $(get_v_d "Intel.*Integrated Graphics")
  . ./config.conf
}

launch_looking_glass() {
  looking-glass-client -s -m 97
}
install() {
  sudo mkdir -p /etc/libvirt/hooks &&\
  sudo chmod +x ./* &&\
  sudo ln -s $DIR0/* /etc/libvirt/hooks/ &&\
  echo "🎉 Don't remove/rename files in $DIR0, otherwise re-install"
}
uninstall() {
  ls | xargs -I % sudo rm /etc/libvirt/hooks/% ||\
  sudo find /etc/libvirt/hooks/ -type l -exec test ! -e {} \; -delete # remove broken symlink
}
helpme() {
  echo -e "Usage:\t$0 list|setup|install|uninstall|looking|what|helpme|about"
  echo "PCI Passthrough: https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF"
}
about() {
  echo -e "\tCredits"
  echo "Seamless Solution on dual-GPU laptop by"
  echo "🐧BlandManStudios: https://www.youtube.com/watch?v=LtgEUfpRbZA"
  echo
  echo "Single GPU without logoff by"
  echo "🐧ledisthebest: https://github.com/ledisthebest/LEDs-single-gpu-passthrough/blob/main/README.md"
}

if [ -z "$1" ]; then
  how_gpu
  echo
  what_gpu
  echo
  helpme
elif [ "$1" == "setup" ]; then
  if sudo dmesg | grep -e DMAR -e IOMMU > /dev/null; then
    echo "✔ iommu"
  else
    grep "iommu" /etc/default/grub >/dev/null &&\
    echo "✔ Skip add iommu in grub" ||\
    (
      sudo sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 iommu=pt amd_iommu=on intel_iommu=on"/' /etc/default/grub &&\
      sudo update-grub && echo || sudo grub-mkconfig -o /boot/grub/grub.cfg
      echo "⚠️ Reboot to enable iommu"
    )
  fi
  sudo grep Y /sys/module/nvidia_drm/parameters/modeset >/dev/null && echo "✔ nvidia_drm on" || echo "⚠️ nvidia_drm off"

  lsmod | grep nouveau > /dev/null && echo "⚠️ nouveau running" || echo "✔ nouveau off"
  lsmod | grep virtio > /dev/null && echo "✔ virtio running" || echo "⚠️ virtio not running"

  bash $(find . -name 'lookingGlass_*' | head -n 1)
  echo
  config_gpu
  select_gpu

  vd=""
  for key in ${GPU_KEY[@]}; do
    vd+=${V_D_GPU[$key]} && vd+=","
    [[ -n ${V_D_AUD[$key]} ]] && vd+=${V_D_AUD[$key]} && vd+=","
  done
  # 去掉vd最后一个字符
  vd=${vd%?}
  sudo grep "ids=$vd" /etc/modprobe.d/vfio.conf > /dev/null && echo "✔ vfio-pci" ||\
  (
    echo "options vfio-pci ids=$vd" | sudo tee /etc/modprobe.d/vfio.conf &&\
# echo "options vfio-pci disable_idle_d3=1
# options vfio-pci disable_vga=1"  | sudo tee /etc/modprobe.d/vfio.conf &&\
    echo "⚠️ Reboot to enable vfio-pci"
  )

  uninstall
  install
elif [ "$1" == "install" ]; then
  uninstall
  install
elif [ "$1" == "uninstall" ]; then
  Yn "uninstall?" && uninstall
elif [ "$1" == "looking" ]; then
  launch_looking_glass
elif [ "$1" == "what" ]; then
  what_gpu
elif [[ "$1" == "about" ]]; then
  about
elif [[ "$1" == *"h"* ]]; then
  helpme
elif [[ "$1" == *"l"* ]]; then
  how_gpu
  echo
  what_gpu
else
  echo "Invalid command: $1"
  exit 1
fi
