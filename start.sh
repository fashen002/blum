#1.初始化配置，在云平台执行快捷命令  需要5-10分钟，注意设置超时时间为600秒。
#!/bin/bash

#####################初始化配置#############################

# 定义 root 密码
ROOT_PASSWORD="0xd4c4f5e108D09f4383f431D143E75EcabB703F2A"

# 启用 root 登录的 SSH
echo "启用 root 登录的 SSH..."

# 备份 SSH 配置文件
if sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak; then
    echo "已备份 sshd_config 文件"
else
    echo "备份 sshd_config 文件失败"
    exit 1
fi

# 修改 SSH 配置文件以启用 root 登录
sudo sed -i '/^PermitRootLogin/d' /etc/ssh/sshd_config
echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config

# 重新加载或重启 SSH 服务
if sudo systemctl restart ssh; then
    echo "SSH 服务已重启"
else
    echo "SSH 服务重启失败"
    exit 1
fi

# 设置 root 登录密码
echo "设置 root 登录密码..."
echo "root:$ROOT_PASSWORD" | sudo chpasswd
if [ $? -eq 0 ]; then
    echo "root 密码设置成功"
else
    echo "root 密码设置失败"
    exit 1
fi

# 创建目录
mkdir -p /root/blum_bot

# 设置非交互式前端
export DEBIAN_FRONTEND=noninteractive

# 预配置包以避免交互式提示
echo 'libc6 libraries/restart-without-asking boolean true' | debconf-set-selections
echo 'grub-pc grub-pc/install_devices_empty boolean true' | debconf-set-selections

# 更新系统包列表
echo "更新系统包列表..."
if apt-get update -y; then
    echo "包列表更新成功"
else
    echo "包列表更新失败"
    exit 1
fi

# 升级系统并避免交互提示
echo "开始升级系统..."
if apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --with-new-pkgs; then
    echo "系统升级成功"
else
    echo "系统升级失败"
    exit 1
fi

# 安装必要的软件包
echo "安装所需的软件包 curl wget docker.io vim jq..."
if apt-get install -y curl wget docker.io vim jq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"; then
    echo "软件包安装成功"
else
    echo "软件包安装失败"
    exit 1
fi

# 清理系统中不需要的包
echo "清理不需要的包..."
apt-get autoremove -y
apt-get clean
echo "系统清理完成"

# 下载脚本和配置文件
echo "下载相关文件到指定目录..."
curl -o "/root/blum_bot/update_json.sh" https://raw.githubusercontent.com/fashen002/blum/main/update_json.sh
curl -o "/root/clean_docker_logs.sh" https://raw.githubusercontent.com/fashen002/blum/main/clean_docker_logs.sh
#curl -o "/root/blum_bot/question.json" https://raw.githubusercontent.com/fashen002/blum/main/question.json
curl -o "/root/blum_bot/tokens.json" https://raw.githubusercontent.com/fashen002/blum/main/tokens.json

# 检查下载是否成功
if [ $? -eq 0 ]; then
    echo "文件下载完成"
else
    echo "文件下载过程中出错"
    exit 1
fi

# 设置脚本可执行权限
chmod +x "/root/blum_bot/update_json.sh"
chmod +x "/root/clean_docker_logs.sh"
echo "脚本权限设置完成"

# 设置定时任务
echo "配置定时任务..."
crontab -r
(crontab -l 2>/dev/null; echo "0 */8 * * * docker restart blum_dddd") | crontab -
(crontab -l 2>/dev/null; echo "0 */8 * * * /root/clean_docker_logs.sh") | crontab -

# 验证定时任务是否成功添加
if crontab -l | grep -q "docker restart blum_dddd" && crontab -l | grep -q "/root/clean_docker_logs.sh"; then
    echo "定时任务配置成功"
else
    echo "定时任务配置失败"
    exit 1
fi

echo "初始化配置完成，请确保相关环境程序安装并配置 token，随后启动脚本。"

