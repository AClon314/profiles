FULL0="$(readlink -f "$0")"
DIR0=$(dirname $FULL0)

# 判断显示器个数
monitor_count=$(xrandr | grep -c 'DP-1-2 connected')
if [ $monitor_count -gt 0 ]; then
    # 外置显示器
    gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.0
else
    # 内置显示器
    gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.2

    lsmod | grep nvidia > /dev/null &&\
    { if zenity --question --title="驱动下线：rmmod nvidia" --text="Detected nvidia driver, umount it?
检测到nvidia驱动，是否暂时移除？"; then
        systemctl start nvidia2guest.sh || exit 1
    else
        exit 0
    fi; } ||\
    { if zenity --question --title="挂载驱动：modprobe -i nvidia" --text="Not Detected nvidia driver, mount it?
未检测到nvidia驱动，是否加载？"; then
        systemctl start nvidia2host.sh || exit 1
    else
        exit 0
    fi; }
fi
