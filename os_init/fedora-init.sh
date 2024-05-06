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

mkdir -p ~/fedora_init_temp ; cd ~/fedora_init_temp

# MIRROR IN CHINA
title $PWD💬tsinghua dnf mirror
sudo sed -e 's|^metalink=|#metalink=|g' \
    -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.tuna.tsinghua.edu.cn/fedora|g' \
    -i.bak \
    /etc/yum.repos.d/fedora.repo \
    /etc/yum.repos.d/fedora-modular.repo \
    /etc/yum.repos.d/fedora-updates.repo \
    /etc/yum.repos.d/fedora-updates-modular.repo
sudo dnf update -y
title $PWD💬tsinghua pip mirror
python -m ensurepip
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple some-package # TODO: wait
python -m pip install --upgrade pip
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# flatpak
sudo dnf install -y flatpak git
title 💬sjtu flathub mirror
flatpak remote-add --if-not-exists flathub_cn https://mirror.sjtu.edu.cn/flathub
yon "First time?" && wget https://mirror.sjtu.edu.cn/flathub/flathub.gpg && flatpak remote-modify --gpg-import=flathub.gpg flathub_cn
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo


# VPN
export http_proxy='http://127.0.0.1:7897'
export https_proxy='http://127.0.0.1:7897'


# DRIVER
title 💬rpm repo
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf config-manager -y --enable fedora-cisco-openh264

title 💬nvidia for Current GeForce/Quadro/Tesla, eg: RTX3050
sudo dnf update -y # '-y' to reboot if you are not on the latest kernel
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda # rhel/centos users can use kmod-nvidia instead, optional for cuda/nvdec/nvenc support
modinfo -F version nvidia # wait a few seconds to run this line, should be 550.xx etc.


title 💬IME: ibus to fcitx5
sudo dnf remove ibus # need your 'y'
sudo dnf install -y fcitx5

# USEFUL TOOLS
sudo dnf install -y radeontop powertop ## .*top tools

title 💬fsearch fzf copyq
sudo dnf copr enable -y cboxdoerfer/fsearch
sudo dnf install -y fzf copyq fsearch
if ! grep -q "\C-f" ~/.bashrc; then
  echo bind '"\C-f": "$(fzf)\e\C-e"' >> ~/.bashrc
fi

title 💬edge: https://www.linuxcapable.com/install-microsoft-edge-on-fedora-linux/
#sudo dnf upgrade --refresh
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager -y --add-repo https://packages.microsoft.com/yumrepos/edge
sudo dnf install -y microsoft-edge-beta
title 💬vscode
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
sudo dnf check-update
sudo dnf install -y code
# FLATPAK
flatpak install -y io.github.flattool.Warehouse com.github.tchx84.Flatseal # basic flat manager

title 💬fcitx5
flatpak install -y org.fcitx.Fcitx5 org.fcitx.Fcitx5.Addon.Rime # Chinese Input
title 💬choose fcitx5, then will logout, re-login and run script again.
im-chooser
mkdir -p ~/.var/app/org.fcitx.Fcitx5/data/fcitx5/themes
cd ~/.var/app/org.fcitx.Fcitx5/data/fcitx5 && git clone https://github.com/sxqsfun/fcitx5-sogou-themes ./themes
yon "rime-ice?" && rm -rf ./rime/* && git clone https://github.com/iDvel/rime-ice.git ./rime/ ; sed -i 's/page_size: 5/page_size: 9/g' ./rime/default.yaml


#flatpak install -y org.winehq.Wine io.github.fastrizwaan.WineZGUI 
flatpak install -y com.usebottles.bottles # windows

flatpak install -y com.obsproject.Studio org.videolan.VLC
flatpak install -y org.kde.filelight com.tencent.WeChat  org.blender.Blender # my utils
### steam & vscode & protonUp-Qt?
### https://flathub.org/apps/search?q=%s
title 💬virt
sudo dnf install -y @virtualization

title 💬appman
cd ~/fedora_init_temp
mkdir -p ~/.local/bin && 
if ! grep -q "export PATH=\$PATH:\$(xdg-user-dir USER)/.local/bin" ~/.bashrc; then
  echo 'export PATH=$PATH:$(xdg-user-dir USER)/.local/bin' >> ~/.bashrc &&
  wget https://raw.githubusercontent.com/ivan-hc/AM/main/APP-MANAGER -O appman &&
  chmod a+x ./appman &&
  mv ./appman ~/.local/bin/appman
else
  echo WARNING: if you aborted and appman not installed, run `nano .bashrc` an remove line: `export PATH=\$PATH:\$\(xdg-user-dir...`
fi
appman
appman -i linuxqq

title 💬auto-cpufreq
git clone https://github.com/AdnanHodzic/auto-cpufreq.git ~/auto-cpufreq
cd auto-cpufreq && sudo ./auto-cpufreq-installer
cd ..

title 💬cinnamon fix
sudo dnf install -y numlockx touchegg
sudo systemctl enable --now touchegg

title 💬kde partition manager
# sudo dnf remove gnome-disk-utility
# sudo dnf install -y gparted
#sudo dnf install -y kde-partitionmanager

title 💬edge copilot fix
#git clone https://github.com/jiarandiana0307/patch-edge-copilot.git patch-edge-copilot && cd patch-edge-copilot ; python patch_edge_copilot.py

# beautify
curl -sS https://starship.rs/install.sh | sh
#eval "$(starship init zsh)"
if ! grep -q "starship" ~/.bashrc; then
  echo eval \"\$(starship init bash)\" >> ~/.bashrc
fi

#dnf install -y zsh
#sudo lchsh $USER #/bin/zsh

title 💬sysrq
echo "1" | sudo tee /proc/sys/kernel/sysrq

title grub
# grubby --args="<NEW_PARAMETER1> <NEW_PARAMETER2 <NEW_PARAMETER_n>" --update-kernel=/boot/vmlinuz-5.11.14-300.fc34.x86_64

if ! grep -q "acpi_backlight" /etc/default/grub; then
  sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="acpi_backlight=native amd_iommu=on iommu=pt"/g' /etc/default/grub  
fi
yon "update grub?" && sudo grub2-mkconfig -o /boot/grub2/grub.cfg

title 💬create snapshot
