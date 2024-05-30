#!/bin/bash

# Function to update system packages
update_system() {
    echo "Backing up files before updating system packages..."
    sudo tar -cvf /tmp/backup.tar /etc/*
    echo "Checking user confirmation..."

    read -p "Do you want to continue with the update? (Y/N): " confirm

    if [ "$confirm" == "Y" ] || [ "$confirm" == "y" ]; then
        echo "Updating system packages..."
        if [ -f /etc/debian_version ]; then
            # Remove or comment out any outdated or unavailable repositories
            sudo sed -i '/old-releases.ubuntu.com/s/^/#/' /etc/apt/sources.list
            sudo sed -i '/vbernat\/haproxy-2.8/s/^/#/' /etc/apt/sources.list
            sudo sed -i '/vbernat\/haproxy-2.9/s/^/#/' /etc/apt/sources.list

            sudo apt update
            sudo apt full-upgrade -y || { echo "Update failed"; exit 1; }
        elif [ -f /etc/redhat-release ]; then
            sudo yum update -y || { echo "Update failed"; exit 1; }
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
        curl -fsSL https://get.docker.com | sudo sh
        if [ $? -ne 0 ]; then
            echo "Docker installation failed"
            exit 1
        fi
        sudo usermod -aG docker $USER
        echo "Docker installed successfully. Please log out and log back in for changes to take effect."
    else
        echo "Docker is already installed."
    fi
}

# Function to install Docker Compose
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose is not installed. Installing Docker Compose..."
        if [ -f /etc/debian_version ]; then
            sudo apt install docker-compose -y || { echo "Docker Compose installation failed"; exit 1; }
        elif [ -f /etc/redhat-release ]; then
            sudo yum install docker-compose -y || { echo "Docker Compose installation failed"; exit 1; }
        else
            echo "Unsupported Linux distribution."
            exit 1
        fi
    else
        echo "Docker Compose is already installed."
    fi
}

# Function to clone WhatsApp Proxy repository and run the proxy
run_proxy() {
    echo "Cloning WhatsApp Proxy repository..."
    git clone https://github.com/WhatsApp/proxy.git || { echo "Failed to clone repository"; exit 1; }
    cd proxy || { echo "Failed to enter directory"; exit 1; }
    echo "Building Docker image..."
    docker build -t whatsapp_proxy:1.0 . || { echo "Docker build failed"; exit 1; }
    echo "Running Docker container..."
    docker run -d -p 5222:5211 whatsapp_proxy:1.0 || { echo "Failed to run Docker"; exit 1; }
    echo "Starting Docker Compose..."
    docker-compose -f ops/docker-compose.yml up -d || { echo "Docker Compose failed"; exit 1; }
}

# Check if WhatsApp proxy service is running
check_proxy() {
    if sudo docker ps | grep -q "whatsapp_proxy"; then
        echo "WhatsApp proxy service is running successfully."
    else
        echo "WhatsApp proxy service failed to start."
        exit 1
    fi
}

# Main script execution
update_system
install_docker
install_docker_compose
run_proxy
check_proxy
