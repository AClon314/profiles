#!/bin/bash
function yon {
  while true; do
    read -p "$* [y/n]: " yn
      case $yn in
        [Yy]*) return 0 ;;
        [Nn]*) echo "Aborted" ; return 1 ;;
    esac
  done
}
function title {
  echo -e -n "\033]0;$*\007"
}
sudo apt update
sudo apt upgrade -y

sudo apt install -y git
python -m pip install --upgrade pip
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

title 💬15days autoclean trash:///
gsettings set org.cinnamon.desktop.privacy remove-old-temp-files true
gsettings set org.cinnamon.desktop.privacy remove-old-trash-files true
gsettings set org.cinnamon.desktop.privacy old-files-age 15

title 💬fsearch fzf copyq
sudo apt install -y fzf copyq
if ! grep -q "\C-f" ~/.bashrc; then
  echo bind '"\C-f": "$(fzf)\e\C-e"' >> ~/.bashrc
fi
sudo add-apt-repository ppa:christian-boxdoerfer/fsearch-daily
sudo apt update
sudo apt install -y fsearch

title 💬fcitx5-rime
yon "y: rime-ice, n: keep default" &&
sudo apt remove fcitx5-chinese-addons &&
sudo apt install -y fcitx5 fcitx5-rime
# mkdir -p /tmp/mint_init_temp
# cd /tmp/mint_init_temp &&
mkdir -p ~/.local/share/fcitx5/themes
cd ~/.local/share/fcitx5/themes && git clone https://github.com/sxqsfun/fcitx5-sogou-themes ./themes
yon "rime-ice?" && rm -rf ./rime/* && git clone https://github.com/iDvel/rime-ice.git ./rime/ ; sed -i 's/page_size: 5/page_size: 9/g' ./rime/default.yaml


title 💬auto-cpufreq
git clone https://github.com/AdnanHodzic/auto-cpufreq.git ~/auto-cpufreq
cd ~/auto-cpufreq && sudo ./auto-cpufreq-installer
cd ..

title 💬cinnamon fix
sudo apt install -y numlockx

title 💬virt-manager
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
sudo systemctl enable libvirtd
sudo adduser `id -un` libvirt
sudo virsh list --all

title 💬remove-pre-installed
sudo apt remove thunderbird

# beautify
curl -sS https://starship.rs/install.sh | sh
#eval "$(starship init zsh)"
if ! grep -q "starship" ~/.bashrc; then
  echo eval \"\$(starship init bash)\" >> ~/.bashrc
fi

# SYSTEM
title 💬lenovo-legion-driver
# sudo dnf copr enable -y mrduarte/LenovoLegionLinux
# sudo dnf install -y dkms-LenovoLegionLinux python-LenovoLegionLinux

title 💬swapfile
yon "turn off swapfile? [y/n]" &&
sudo swapoff -a &&
sudo sed -i 's/\/swapfile/#\/swapfile/g' /etc/fstab
sudo rm /swapfile

title 💬grub tweak
if ! grep -q "amd_iommu" /etc/default/grub; then
  sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="amd_iommu=on iommu=pt"/g' /etc/default/grub  
  yon "detailed text mode while booting?" && sudo sed -i 's/splash//g' /etc/default/grub
fi
yon "update grub?" && sudo grub2-mkconfig -o /boot/grub2/grub.cfg