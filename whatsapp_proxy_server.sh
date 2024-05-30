#!/bin/bash

# Function to update system packages
update_system() {
    echo "Backing up files before updating system packages... "
    tar -cvf backup.tar  /etc/*
    echo "Checking user confirmation... "

    read -p "Do you want to continue with the update? (Y/N): "
    confirm=$?

    if [ $confirm -eq 0 ]; then
        echo "Updating system packages... "
        if [ -f /etc/debian_version ]; then
            sudo apt update && sudo apt upgrade -y || {
                echo "Update failed"; exit 1;
            }
        elif [ -f /etc/redhat-release ]; then
            sudo yum update -y || {
                echo "Update failed"; exit 1;
            }
        else
            echo "Unsupported Linux distribution."
            exit 1
        fi
    else
        echo "Update cancelled."
        exit 1
    fi
}

# Function to install Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Installing Docker..."
        sudo apt install docker.io || { echo "Docker installation failed"; exit 1; }
        sudo systemctl enable docker
        sudo systemctl start docker
    else
        echo "Docker is already installed."
    fi
}

# Function to install Docker Compose
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose is not installed. Installing Docker Compose..."
        sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose || { echo "Docker Compose download failed"; exit 1; }
        sudo chmod +x /usr/bin/docker-compose
    else
        echo "Docker Compose is already installed."
    fi
}

# Function to clone WhatsApp Proxy repository and run the proxy
run_proxy() {
    git clone https://github.com/WhatsApp/proxy.git  || { echo "Failed to clone repository"; exit 1; }
    cd proxy || { echo "Failed to enter directory"; exit 1; }
    docker build -t whatsapp_proxy:1.0 proxy/ || { echo "Docker build failed"; exit 1; }
    docker run -it -p 5222:5211 whatsapp_proxy:1.0 || { echo "Failed to run Docker"; exit 1; }
    docker-compose -f /root/proxy/proxy/ops/docker-compose.yml  up || { echo "Docker Compose failed"; exit 1; }
}

# Check if WhatsApp proxy service is running
if [ $(sudo docker ps | grep "whatsapp_proxy") -ne 0 ]; then
    echo "WhatsApp proxy service is running successfully."
else
    echo "WhatsApp proxy service failed to start."
    exit 1
fi

# 主脚本执行
update_system() {
    echo "正在更新系统..."
    sudo apt-get update && sudo apt-get upgrade
}

install_docker() {
    echo "正在安装Docker... "
    # 使用官方脚本自动安装Docker
    curl -fsSL https://get.docker.com  | bash
}

install_docker-compose() {
    echo "正在安装Docker Compose... "
    # 使用apt命令快速安装Docker Compose
    sudo apt install docker-compose
}

run_proxy() {
    echo "正在运行代理服务..."
    # 假设代理服务已经配置好，可以直接启动
    docker-compose up -d proxy
}
