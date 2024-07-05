#!/bin/bash

dpkg_old() {
  dpkg-query --show "$1" | cut -f1 | grep -v "$(uname -r)"
}

clean_old_kernel() {
  # https://serverfault.com/questions/1098556/how-to-cleanup-usr-lib-modules-and-usr-lib-x86-64-linux-gnu
  sudo apt remove $(dpkg_old 'linux-modules-*') $(dpkg_old 'linux-headers-*') $(dpkg-query --show 'linux-hwe-*-headers-*' | cut -f1 | grep -v "$(uname -r|sed 's/-generic//')")
}

clean_deb() {
  sudo dpkg --purge $(dpkg -l | grep '^rc' | awk '{print $2}')
  sudo apt remove --purge `deborphan`
}

clean_coredump_journal() {
  sudo journalctl --vacuum-size=1G
  systemd-tmpfiles --clean
  sudo rm -r /var/lib/systemd/coredump/*
}

list_deb() {
  dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | awk '{total += $1} {print $0} END {print total " KB\tTotal size"}' | less +G
}
list_deb_orphan() {
  deborphan -sPz | sort -n | awk '{total += $1} {print $0} END {print total " KB\tTotal size"}'
}

if [ -z "$1" ]; then
  list_deb_orphan
elif [[ "$1" == "l"* ]]; then
  list_deb
elif [ "$1" == "clean" ]; then
  set -x
  clean_old_kernel
  clean_coredump_journal
  clean_deb
  set +x
fi