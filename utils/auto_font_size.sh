# 判断显示器个数
monitor_count=$(xrandr | grep -c ' connected')
if [ $monitor_count -gt 1 ]; then
    # 多显示器
    gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.0
else
    # 单显示器
    gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.2
fi