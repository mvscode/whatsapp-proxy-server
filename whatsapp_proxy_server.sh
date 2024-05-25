#!/bin/bash

# 更新系统软件包
echo "正在更新系统软件包..."
if [ -f /etc/os-release ]; then
    # Ubuntu/Debian
    sudo apt update && sudo apt upgrade -y
else
    # CentOS/Fedora/RHEL
    sudo yum update -y
fi

# 检查 Docker 是否已安装
if ! command -v docker &> /dev/null
then
    echo "Docker 未安装,正在安装..."
    if [ -f /etc/os-release ]; then
        # Ubuntu/Debian
        sudo apt install docker.io -y
    else
        # CentOS/Fedora/RHEL
        sudo yum install docker -y
    fi
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "Docker 已安装,版本为:"
    docker --version
fi

# 检查 Docker Compose 是否已安装
if ! command -v docker-compose &> /dev/null
then
    echo "Docker Compose 未安装,正在安装..."
    sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
    sudo chmod +x /usr/bin/docker-compose
else
    echo "Docker Compose 已安装,版本为:"
    docker-compose --version
fi

# 克隆 WhatsApp proxy 仓库
echo "正在克隆 WhatsApp proxy 仓库..."
git clone https://github.com/WhatsApp/proxy.git

# 进入 WhatsApp proxy 目录
cd proxy

# 构建 WhatsApp proxy 镜像
echo "正在构建 WhatsApp proxy 镜像..."
docker build proxy/ -t whatsapp_proxy:1.0

# 运行 WhatsApp proxy 容器
echo "正在运行 WhatsApp proxy 容器..."
docker run -it -p 5222:5222 whatsapp_proxy:1.0
docker-compose -f ops/docker-compose.yml up