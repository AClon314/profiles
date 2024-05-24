dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | awk '{total += $1} {print $0} END {print total "\tTotal size"}' | less +G

clean() {
  # https://serverfault.com/questions/1098556/how-to-cleanup-usr-lib-modules-and-usr-lib-x86-64-linux-gnu
  sudo apt remove $(dpkg-query --show 'linux-modules-*' | cut -f1 | grep -v "$(uname -r)")
}