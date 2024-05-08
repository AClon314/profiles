#!/bin/bash
if [$1 = '']; then
    lsblk |grep nvme
    echo Ctrl+C to cancel and leave!
    read -p "nvme_n1p3:" d
else
    d=$1
fi
#echo /dev/nvme${d}n1p2
#https://docs.fedoraproject.org/en-US/quick-docs/grub2-bootloader/#_lvm_steps

set -x
sudo mkdir -p /mnt/root &&
sudo mount /dev/mapper/live-rw /mnt/root &&
sudo mount /dev/nvme${d}n1p2 /mnt/root/boot &&

sudo mount -o bind /dev /mnt/root/dev &&
sudo mount -o bind /proc /mnt/root/proc &&
sudo mount -o bind /sys /mnt/root/sys &&
sudo mount -o bind /run /mnt/root/run &&

sudo mount -o bind /sys/firmware/efi/efivars /mnt/root/sys/firmware/efi/efivars &&
sudo mount /dev/nvme${d}n1p1 /mnt/root/boot/efi &&

sudo chroot /mnt/root/ sudo sed -e 's|^metalink=|#metalink=|g' \
    -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.tuna.tsinghua.edu.cn/fedora|g' \
    -i.bak \
    /etc/yum.repos.d/fedora.repo \
    /etc/yum.repos.d/fedora-modular.repo \
    /etc/yum.repos.d/fedora-updates.repo \
    /etc/yum.repos.d/fedora-updates-modular.repo ; 
sudo dnf reinstall -y shim-* grub2-efi-* grub2-common ; 
sudo sync && exit
