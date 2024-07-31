# 删除或备份用户目录配置文件
rm -r $HOME/.config/Kingsoft $HOME/.local/share/Kingsoft
# 修改oem.ini文件（针对12.8.2.16969），12.8.2.15283版本删除以下脚本第二行即可。
sudo sed -i  -e 's/supportNormal=false/supportNormal=true/' \
		-e '/supportNormal=true/a ProductDefinition=Professional' \
		-e '/EnableCloudDocs=true/a IsShop=true' \
		/opt/kingsoft/wps-office/office6/cfgs/oem.ini \
		/opt/kingsoft/wps-office/office6/wtool/oem.ini \
		/opt/kingsoft/wtool/oem.ini
# 删除或备份验证文件
sudo rm -r /opt/kingsoft/.auth
