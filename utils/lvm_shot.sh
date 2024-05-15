#!/bin/bash
HOW_MANY=1
INIT_SIZE=256M
TARGET_LV=${2:-/dev/lvm/root} #if not set, use /dev/lvm/root
TAG=$(basename $TARGET_LV)

#DON'T modify these var
SELF0=$(basename $0) 
FULL0="$(readlink -f "$0")"

title() {
  echo -e -n "\033]0;$*\007"
}
list_pretty() {
  sudo lvs -S 'lv_attr=~^s' -o lv_path,data_percent,lv_size,origin,lv_tags,lv_time | awk 'NR==1 || /auto/'
}
list() {
  sudo lvs -S 'lv_attr=~^s' -o lv_path | grep auto | awk -F: '{print $1}'
}
auto() {
  # if list is not null
  if [ -n "$(list)" ]; then
    # if list >= HOW_MANY
    if [ $(list|wc -l) -ge $HOW_MANY ]; then
      # counts ALL_LINES of `list`, lvremove for ALL_LINES-HOW_MANY+1 lines in head
      list|head -n $(($(list|wc -l)-HOW_MANY+1))|xargs -I {} sudo lvremove -y {}
    fi
  fi

  if [ $HOW_MANY -gt 0 ]; then
    sudo lvcreate --size=$INIT_SIZE -s -n auto$(date "+%y%m%d-%H%M%S") --addtag $TAG $TARGET_LV
  else
    echo \$HOW_MANY=$HOW_MANY, skip
    exit 1
  fi
}
remove () {
  sudo lvremove $(list|awk '{print $1}') ||\
  { list | xargs -I % sudo lsof % && echo "❌ remove failed" && exit 1; }
}
recover() {
  sudo lvconvert --merge $(list|grep $1|awk '{print $1}')
}
config() {
  # snapshot_autoextend_threshold
  title "threshold=85, 20%"
  sudo nano +1543 -c /etc/lvm/lvm.conf
  echo "⚠️reboot to take effect"
  echo "💡Tips: more config in $0"
}
enable() {
  sudo bash -c "cat << EOF > /etc/systemd/system/$SELF0.service
[Unit]
Description=Run $SELF0.sh at startup

[Service]
ExecStart=$FULL0 auto

[Install]
WantedBy=multi-user.target
EOF"
  sudo systemctl enable $SELF0
  sudo systemctl start $SELF0
}
disable() {
  sudo systemctl stop $SELF0
  sudo systemctl disable $SELF0
  sudo rm /etc/systemd/system/$SELF0.service
}
mapper() {
  list | xargs -I % sudo lvchange --refresh --addtag noudevsync %
}
help() {
  echo -e "Usage:\t$0\tauto|list|recover|remove|config|enable|disable|mapper"
  echo -e "  auto [path]\t:always keep recent $HOW_MANY shots"
  echo -e "  list\t\t:list auto-shots"
  echo -e "  recover [lv]\t:merge snapshot"
  echo -e "  remove\t:remove all auto-shots"
  echo -e "  config\t:edit lvm.conf to set snapshot threshold and size"
  echo -e "  enable\t:enable startup as systemd service"
  echo -e "  disable\t:disable startup as systemd service"
  echo -e "  mapper\t:show snapshot in /dev/mapper"
}



if [ -z "$1" ]; then
  list_pretty
  echo
  help
elif [ "$1" == "auto" ]; then
  auto $2
elif [ "$1" == "config" ]; then
  config
elif [ "$1" == "recover" ]; then
  recover $2
elif [ "$1" == "remove" ]; then
  remove
elif [ "$1" == "enable" ]; then
  enable
elif [ "$1" == "disable" ]; then
  disable
elif [ "$1" == "mapper" ]; then
  mapper
elif [[ "$1" == *"h"* ]]; then
  help
elif [[ "$1" == *"l"* ]]; then
  list_pretty
else
  echo "Invalid command: $1"
  exit 1
fi
