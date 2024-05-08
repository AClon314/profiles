#!/bin/bash
INIT_SIZE=256M
TARGET_LV=${2:-/dev/lvm/root} #if not set, use /dev/lvm/root
TAG=$(basename $TARGET_LV)
HOW_MANY=0

function title {
  echo -e -n "\033]0;$*\007"
}
function list_pretty {
  sudo lvs -S 'lv_attr=~^s' -o lv_path,data_percent,lv_size,origin,lv_tags,lv_time | awk 'NR==1 || /auto/'
}
function list {
  sudo lvs -S 'lv_attr=~^s' -o lv_path | grep auto | awk -F: '{print $1}'
}
function auto {
  # if list is not null
  if [ -n "$(list)" ]; then
    # if list >= HOW_MANY
    if [ $(list|wc -l) -ge $HOW_MANY ]; then
      # counts ALL_LINES of `list`, lvremove for ALL_LINES-HOW_MANY-1 lines in head
      list|head -n $(($(list|wc -l)-HOW_MANY))|xargs -I {} sudo lvremove -y {}
    fi
  fi

  if [ $HOW_MANY -gt 0 ]; then
    sudo lvcreate --size=$INIT_SIZE -s -n auto$(date "+%y%m%d-%H%M%S") --addtag $TAG $TARGET_LV
  else
    echo \$HOW_MANY=$HOW_MANY, skip
    exit 1
  fi
}
function recover {
  sudo lvconvert --merge $(list|grep $1|awk '{print $1}')
}
function config {
  # snapshot_autoextend_threshold
  title "threshold=85, 20%"
  sudo nano +1543 -c /etc/lvm/lvm.conf
  echo "⚠️reboot to take effect"
  echo "💡Tips: more config in $0"
}
function help {
  echo -e "Usage:\t$0\tauto|list|recover|config"
  echo -e "  auto [path]\t:always keep recent $HOW_MANY shots"
  echo -e "  list\t\t:list auto-shots"
  echo -e "  recover [lv]\t:merge snapshot"
  echo -e "  config\t:edit lvm.conf to set snapshot threshold and size"
}



if [ -z "$1" ]; then
  list
  help
elif [ "$1" == "auto" ]; then
  auto $2
elif [ "$1" == "config" ]; then
  config
elif [ "$1" == "recover" ]; then
  recover $2
elif [[ "$1" == *"h"* ]]; then
  help
elif [[ "$1" == *"l"* ]]; then
  list_pretty
else
  echo "Invalid command: $1"
  exit 1
fi