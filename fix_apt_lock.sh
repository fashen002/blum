#!/bin/bash

# 检查是否有 apt 或 dpkg 进程运行
apt_dpkg_process=$(ps aux | grep -E 'apt|dpkg' | grep -v grep)

if [ -n "$apt_dpkg_process" ]; then
    echo "检测到正在运行的 apt 或 dpkg 进程，正在终止这些进程..."
    
    # 提取正在运行的进程 ID 并终止它们
    for pid in $(ps aux | grep -E 'apt|dpkg' | grep -v grep | awk '{print $2}'); do
        echo "终止进程 PID: $pid"
        sudo kill -9 $pid
    done
fi

# 删除锁文件
echo "删除锁文件..."
sudo rm -f /var/lib/dpkg/lock-frontend
sudo rm -f /var/cache/apt/archives/lock

# 重新配置 dpkg
echo "重新配置 dpkg..."
sudo dpkg --configure -a

# 更新软件包列表
echo "更新软件包列表..."
sudo apt update

echo "处理完成。"
