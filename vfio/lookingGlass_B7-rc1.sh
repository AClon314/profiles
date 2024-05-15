. ./config.conf

BASE0=$(basename $0) 
FULL0="$(readlink -f "$0")"
DIR0=$(dirname $FULL0)

# compile & install
which looking-glass-client > /dev/null && echo "✔ Installed looking-glass-client" ||\
if [[ -z "$1" ]]; then
  echo "❌ Exit: provide the path of looking-glass-client"
  echo "💡 Tips: run $0 skip to skip all error" | grep "$0 skip"
  [[ "$1" != "skip" ]] && exit 1
else
  pushd $1 &&\
  mkdir -p client/build &&\

  pushd client/build &&\
  cmake ../ &&\
  make install &&\
  echo "✔ Install looking-glass-client" &&\
  popd

  sudo apt-get install linux-headers-$(uname -r) dkms &&\
  pushd module/ &&\
  dkms install "." &&\
  echo "✔ Install dkms-kvmfr" || echo "❌ Error: install dkms-kvmfr"
fi

# IVSHMEM with kvmfr
DISPLAY_MEM_SIZE_BYTES=$(($DISPLAY_MEM_SIZE*1024*1024))
dkms status | grep kvmfr > /dev/null && echo "✔ Installed dkms-kvmfr" || echo "❌ Error: No dkms-kvmfr"
# sudo modprobe kvmfr static_size_mb=$DISPLAY_MEM_SIZE 
grep static_size_mb=$DISPLAY_MEM_SIZE /etc/modprobe.d/kvmfr.conf > /dev/null && echo "✔ modprobe kvmfr: ${DISPLAY_MEM_SIZE}M" || echo "❌ Error: modprobe kvmfr"
if [[ $(stat -c '%U:%G' /dev/kvmfr0) ]]; then
  echo "✔ chown: $(ls -l /dev/kvmfr0)"
else
  sudo chown $(whoami):kvm /dev/kvmfr0 &&\
  echo "🔧 Fixed chown /dev/kvmfr0" || echo "❌ Error: chown /dev/kvmfr0"
fi

# apparmor & cgroup
grep "/dev/kvmfr0 rw" /etc/apparmor.d/local/abstractions/libvirt-qemu >/dev/null && echo "✔ AppArmor looking glass" ||\
echo "# Looking Glass
/dev/kvmfr0 rw," | sudo tee -a /etc/apparmor.d/local/abstractions/libvirt-qemu || echo "❌ Error: AppArmor (Maybe you have to fix it manually with SElinux Rule on Redhat,Fedora...)"
sudo grep "/dev/kvmfr0" /etc/libvirt/qemu.conf > /dev/null && echo "✔ cgroups" ||\
(echo "1.Uncomment the cgroup_device_acl block
2.adding \"/dev/kvmfr0\" to the list" &&\
Yn "Are you ready?" &&\
sudo nano +576 -l /etc/libvirt/qemu.conf
sudo systemctl restart libvirtd.service)

# qemu args: ls /etc/libvirt/qemu
for vm in $(virsh list --name --all); do
  virsh dumpxml $vm | grep "/dev/kvmfr0&quot;,&quot;size&quot;:$DISPLAY_MEM_SIZE_BYTES" > /dev/null && echo "✔ QEMU" ||\
  {
echo '<domain type="kvm" xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0">' |grep "xmlns:qemu=" --color=always
echo "  <qemu:commandline>
    <qemu:arg value='-device'/>
    <qemu:arg value='{\"driver\":\"ivshmem-plain\",\"id\":\"shmem0\",\"memdev\":\"looking-glass\"}'/>
    <qemu:arg value='-object'/>
    <qemu:arg value='{\"qom-type\":\"memory-backend-file\",\"id\":\"looking-glass\",\"mem-path\":\"/dev/kvmfr0\",\"size\":$DISPLAY_MEM_SIZE_BYTES,\"share\":true}'/>
  </qemu:commandline>
</domain>
"  | grep $DISPLAY_MEM_SIZE_BYTES -C 9 --color=always
  echo "Modify/Copy the above to XML conf of VMs"
  Yn "Are you ready?" && virsh edit $vm;
}
done