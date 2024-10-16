#!/bin/bash

# 截断所有容器日志文件
for log_file in /var/lib/docker/containers/*/*.log
do
    truncate -s 0 "$log_file"
done

# 使用Logrotate进行日志管理
#cat <<EOF | sudo tee /etc/logrotate.d/docker-containers
#/var/lib/docker/containers/*/*.log {
#    rotate 7
#    daily
#    compress
#    missingok
#    delaycompress
#    copytruncate
#}
#EOF

# 重新加载logrotate配置
#sudo logrotate -f /etc/logrotate.d/docker-containers

