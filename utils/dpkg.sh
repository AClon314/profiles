#!/bin/bash

clean_old_kernel() {
  # https://serverfault.com/questions/1098556/how-to-cleanup-usr-lib-modules-and-usr-lib-x86-64-linux-gnu
  sudo apt remove $(dpkg-query --show 'linux-modules-*' | cut -f1 | grep -v "$(uname -r)")
}

clean_deb() {
  sudo apt-get remove --purge `deborphan`
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
  # clean_old_kernel
  clean_deb
fi