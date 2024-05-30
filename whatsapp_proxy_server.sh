#!/bin/bash

## Script Code Description

# This script updates system packages, installs Docker and Docker Compose,
# then clones the WhatsApp Proxy repository from GitHub and runs the Proxy service.
# It also includes some auxiliary functions, such as checking if the Proxy service is running.

# Colors for better output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to update system packages
update_system() {
    echo -e "${YELLOW}Backing up files before updating system packages...${NC}"
    sudo tar -czf /tmp/backup.tar.gz /etc/*

    echo -e "${YELLOW}Checking user confirmation...${NC}"
    read -rp "Do you want to continue with the update? (Y/N) [Y]: " -n 1 -r confirm
    echo
    confirm=${confirm:-Y} # Default to 'Y' if user presses Enter

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Updating system packages...${NC}"
        if [ -f /etc/debian_version ]; then
            sudo apt-get update
            sudo apt-get full-upgrade -y || { echo -e "${RED}Update failed${NC}"; exit 1; }
        elif [ -f /etc/redhat-release ]; then
            sudo yum update -y || { echo -e "${RED}Update failed${NC}"; exit 1; }
        else
            echo -e "${RED}Unsupported Linux distribution.${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Update cancelled.${NC}"
        exit 1
    fi
}

# Function to install Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker is not installed. Installing Docker...${NC}"
        curl -fsSL https://get.docker.com | sh
        if [ $? -ne 0 ]; then
            echo -e "${RED}Docker installation failed${NC}"
            exit 1
        fi
        sudo usermod -aG docker "$USER"
        echo -e "${GREEN}Docker installed successfully. Please log out and log back in for changes to take effect.${NC}"
    else
        docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        echo -e "${YELLOW}Docker version $docker_version is already installed.${NC}"
    fi
}

# Function to install Docker Compose
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Docker Compose is not installed. Installing Docker Compose...${NC}"
        if [ -f /etc/debian_version ]; then
            sudo apt-get install -y docker-compose || { echo -e "${RED}Docker Compose installation failed${NC}"; exit 1; }
        elif [ -f /etc/redhat-release ]; then
            sudo yum install -y docker-compose || { echo -e "${RED}Docker Compose installation failed${NC}"; exit 1; }
        else
            echo -e "${RED}Unsupported Linux distribution.${NC}"
            exit 1
        fi
    fi

    docker_compose_version=$(docker-compose --version --short)
    if [ -n "$docker_compose_version" ]; then
        echo -e "${YELLOW}Docker Compose version $docker_compose_version is already installed.${NC}"
    else
        echo -e "${RED}Failed to retrieve Docker Compose version.${NC}"
    fi
}

# Function to clone WhatsApp Proxy repository and run the proxy
run_proxy() {
    local proxy_dir="proxy"
    local compose_file="/root/proxy/proxy/ops/docker-compose.yml"

    if [ -d "$proxy_dir" ]; then
        echo -e "${YELLOW}Removing existing '$proxy_dir' directory...${NC}"
        rm -rf "$proxy_dir"
    fi

    echo -e "${GREEN}Cloning WhatsApp Proxy repository...${NC}"
    git clone https://github.com/WhatsApp/proxy.git "$proxy_dir" || { echo -e "${RED}Failed to clone repository${NC}"; exit 1; }

    pushd "$proxy_dir" > /dev/null || { echo -e "${RED}Failed to enter directory${NC}"; exit 1; }
    echo -e "${GREEN}Building Docker image...${NC}"
    sudo docker-compose -f "$compose_file" up -d || { echo -e "${RED}Docker Compose failed. Check logs for more information.${NC}"; exit 1; }
    popd > /dev/null
}

# Check if WhatsApp proxy service is running
check_proxy() {
    if sudo docker ps --format '{{.Names}}' | grep -q "whatsapp_proxy"; then
        echo -e "${GREEN}WhatsApp proxy service is running successfully.${NC}"
    else
        echo -e "${RED}WhatsApp proxy service failed to start.${NC}"
        exit 1
    fi
}

# Main script execution
update_system
install_docker
install_docker_compose
run_proxy
check_proxy
