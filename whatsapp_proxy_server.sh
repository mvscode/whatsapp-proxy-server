#!/bin/bash

# 更新系統並安裝必要的依賴
sudo apt-get update
sudo apt-get install -y curl git

# 安裝 Docker
if ! command -v docker &> /dev/null; then
    echo "Docker 未安裝。正在安裝 Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    if [ -f "get-docker.sh" ]; then
        sh get-docker.sh
        sudo usermod -aG docker $USER
        # 立即生效新的組設置
        newgrp docker
    else
        echo "下載 Docker 安裝腳本失敗。"
        exit 1
    fi
else
    echo "Docker 已安裝。"
fi

# 確認 Docker 安裝成功
docker --version

# 安裝 Docker Compose (可選)
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose 未安裝。正在安裝 Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    if [ -f "/usr/local/bin/docker-compose" ]; then
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "下載 Docker Compose 失敗。"
        exit 1
    fi
else
    echo "Docker Compose 已安裝。"
fi

# 確認 Docker Compose 安裝成功
docker-compose --version

# 克隆 WhatsApp Proxy 儲存庫
git clone https://github.com/WhatsApp/proxy.git
if [ -d "proxy" ]; then
    cd proxy
else
    echo "克隆儲存庫失敗。"
    exit 1
fi

# 從 Meta 的 DockerHub 拉取預構建的映像
docker pull facebook/whatsapp_proxy:latest

# 構建代理主機容器
docker build . -t whatsapp_proxy:1.0

# 運行代理容器
docker run -it -p 80:80 -p 443:443 -p 5222:5222 -p 8080:8080 -p 8443:8443 -p 8222:8222 -p 8199:8199 -p 587:587 -p 7777:7777 whatsapp_proxy:1.0

docker-compose -f /root/proxy/proxy/ops/docker-compose.yml up

# 提示用戶檢查連接
echo "代理已啟動。請訪問 http://<host-ip>:8199 確認 HAProxy 正在運行。"
echo "注意：如果您的公共 IP 地址不可訪問，您需要為使用的路由器/網關啟用端口轉發（上述端口）。"