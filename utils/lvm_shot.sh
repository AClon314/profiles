#!/bin/bash
function new {
  
  lvcreate --size=512M -s -n $(date "+%m%d-%H:%M") --addtag root /dev/lvm/root
}
function del {
  lvremove /dev/mint-vg/$1
}
function list {
  lvdisplay -c | grep -v "root" | awk -F: '{print $1}'
}
function autoextend {
  title "threshold=85, 20%"
  sudo nano +1543 -c /etc/lvm/lvm.conf
}
function help{
  echo "Usage: $0 new|autodel|list <lvm_snapshot_name>"
  exit 1
}
function title {
  echo -e -n "\033]0;$*\007"
}


if [ -z "$1" ]; then
  help
else if [ "$1" == "new" ] then
  new
else if [ "$1" == "autodel" ] then
  del
else if [ "$1" == "list" ] then
  list
else
  help
fi