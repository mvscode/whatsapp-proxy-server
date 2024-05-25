#!/bin/bash

# 更新系统并安装 Docker
echo "正在更新系统并安装 Docker..."
if [ -f /etc/os-release ]; then
    # Ubuntu/Debian
    sudo apt update && sudo apt upgrade -y
    sudo apt install docker.io -y
else
    # CentOS/Fedora/RHEL
    sudo yum update -y
    sudo yum install docker -y
fi
sudo systemctl enable docker
sudo systemctl start docker

# 安装 Docker Compose
echo "正在安装 Docker Compose..."
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose

# 克隆 WhatsApp 代理仓库
echo "正在克隆 WhatsApp 代理仓库..."
git clone https://github.com/WhatsApp/proxy.git
cd proxy

# 构建 WhatsApp 代理镜像
echo "正在构建 WhatsApp 代理镜像..."
docker build proxy/ -t whatsapp_proxy:1.0

# 运行 WhatsApp 代理容器
echo "正在运行 WhatsApp 代理容器..."
docker run -it -p 5222:5222 whatsapp_proxy:1.0
docker-compose -f /root/proxy/proxy/ops/docker-compose.yml up