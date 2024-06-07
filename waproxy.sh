#!/bin/bash
# chkconfig: 2345 99 01
# description: Manage WhatsApp Proxy Service

### BEGIN INIT INFO
# Provides:          whatsapp-proxy
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Manage WhatsApp Proxy Service
# Description:       This script manages the WhatsApp Proxy service.
#                    It can install, start, stop, restart, configure and remove the service.
### END INIT INFO

# Colors for better output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to generate QR code for the connection link
generate_qr_code() {
    local connection_link="$1"
    
    # Install qrencode if not present
    if ! command -v qrencode &> /dev/null; then
        echo -e "${YELLOW}qrencode is not installed. Installing qrencode...${NC}"
        if [ -f /etc/debian_version ]; then
            apt-get install -y qrencode || { echo -e "${RED}qrencode installation failed${NC}"; return 1; }
        elif [ -f /etc/redhat-release ]; then
            yum install -y qrencode || { echo -e "${RED}qrencode installation failed${NC}"; return 1; }
        else
            echo -e "${RED}Unsupported Linux distribution.${NC}"
            return 1
        fi
    fi
    
    # Generate QR code with smaller size
    qr_code=$(qrencode -t ansiutf8 -s 4 "$connection_link")
    
    # Display QR code
    echo "$qr_code"
}

# Function to check if system packages are up-to-date
check_system_updates() {
    if [ -f /etc/debian_version ]; then
        apt-get update
        if ! apt-get upgrade -s | grep -q "^0 upgraded"; then
        echo -e "${YELLOW}Warning: Updating system packages may cause unexpected issues. Please ensure you have a backup of your system before proceeding.${NC}"
            read -rp "Do you want to update to the latest packages? (Y/N) [Y]: " -n 1 -r confirm
            echo
            confirm=${confirm:-Y} # Default to 'Y' if user presses Enter

            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                update_system
            else
                echo -e "${YELLOW}Skipping system package update.${NC}"
            fi
        else
            echo -e "${GREEN}Your system packages are up-to-date.${NC}"
        fi
    elif [ -f /etc/redhat-release ]; then
        yum check-update
        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}Your system packages are not up-to-date.${NC}"
            read -rp "Do you want to update to the latest packages? (Y/N) [Y]: " -n 1 -r confirm
            echo
            confirm=${confirm:-Y} # Default to 'Y' if user presses Enter

            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                update_system
            else
                echo -e "${YELLOW}Skipping system package update.${NC}"
            fi
        else
            echo -e "${GREEN}Your system packages are up-to-date.${NC}"
        fi
    else
        echo -e "${RED}Unsupported Linux distribution.${NC}"
        exit 1
    fi
}

# Function to update system packages
update_system() {
    echo -e "${YELLOW}Backing up files before updating system packages...${NC}"
    tar -czf /tmp/backup.tar.gz /etc/*

    echo -e "${GREEN}Updating system packages...${NC}"
    if [ -f /etc/debian_version ]; then
        apt-get update
        apt-get full-upgrade -y || { echo -e "${RED}Update failed${NC}"; exit 1; }
    elif [ -f /etc/redhat-release ]; then
        yum update -y || { echo -e "${RED}Update failed${NC}"; exit 1; }
    else
        echo -e "${RED}Unsupported Linux distribution.${NC}"
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
        usermod -aG docker "$USER"
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
            apt-get install -y docker-compose || { echo -e "${RED}Docker Compose installation failed${NC}"; exit 1; }
        elif [ -f /etc/redhat-release ]; then
            yum install -y docker-compose || { echo -e "${RED}Docker Compose installation failed${NC}"; exit 1; }
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
    local default_port=$(grep -oP '(?<=ports:\n  - )\d+' "$compose_file" | head -n 1)
    local proxy_port=$default_port

    # Check if WhatsApp Proxy is already installed
    if docker ps --format '{{.Names}}' | grep -q "whatsapp_proxy"; then
        echo -e "${YELLOW}WhatsApp Proxy is already installed.${NC}"
        read -rp "Do you want to reinstall? (Y/N) [N]: " -n 1 -r reinstall
        echo
        reinstall=${reinstall:-N} # Default to 'N' if user presses Enter

        if [[ "$reinstall" =~ ^[Nn]$ ]]; then
            echo -e "${GREEN}Skipping WhatsApp Proxy installation.${NC}"
            return
        fi
    fi

    if [ -d "$proxy_dir" ]; then
        echo -e "${YELLOW}Removing existing '$proxy_dir' directory...${NC}"
        rm -rf "$proxy_dir"
    fi

    echo -e "${GREEN}Cloning WhatsApp Proxy repository...${NC}"
    git clone https://github.com/WhatsApp/proxy.git "$proxy_dir" || { echo -e "${RED}Failed to clone repository${NC}"; exit 1; }

    pushd "$proxy_dir" > /dev/null || { echo -e "${RED}Failed to enter directory${NC}"; exit 1; }

    # Check if the default port is available
    while true; do
        if ! lsof -i :"$proxy_port" -sTCP:LISTEN -t &> /dev/null; then
            break
        else
            echo -e "${YELLOW}Port $proxy_port is already in use. Please enter a new port number.${NC}"
            read -rp "Enter port number [${default_port}]: " new_port
            proxy_port=${new_port:-$default_port}
        fi
    done

    echo -e "${YELLOW}Checking user confirmation to run WhatsApp Proxy...${NC}"
    read -rp "Do you want to run the WhatsApp Proxy service? (Y/N) [Y]: " -n 1 -r confirm
    echo
    confirm=${confirm:-Y} # Default to 'Y' if user presses Enter

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Building Docker image...${NC}"
        docker-compose -f "$compose_file" -p "$proxy_port" up -d || { echo -e "${RED}Docker Compose failed. Check logs for more information.${NC}"; exit 1; }
    else
        echo -e "${YELLOW}Cancelled running WhatsApp Proxy.${NC}"
    fi

    popd > /dev/null || exit
}

# Check if WhatsApp proxy service is running
check_proxy() {
    if docker ps --format '{{.Names}}' | grep -q "whatsapp_proxy"; then
        echo -e "${GREEN}WhatsApp proxy service is running successfully.${NC}"
        
        # Get server's public IP address
        server_ip=$(curl -s https://ipinfo.io/ip)
        
        # Generate the connection link
        connection_link="https://wa.me/proxy?host=$server_ip&chatPort=443&mediaPort=587&chatTLS=1"
        echo -e "${GREEN}To connect to WhatsApp Proxy, use the following link:${NC}"
        echo -e "$connection_link"
        
        # Generate QR code for the connection link
        echo -e "${GREEN}QR code for the connection link:${NC}"
        generate_qr_code "$connection_link"
    else
        echo -e "${RED}WhatsApp proxy service failed to start.${NC}"
        exit 1
    fi
}

remove_proxy() {
    local proxy_dir="proxy"
    local compose_file="/root/proxy/proxy/ops/docker-compose.yml"

    echo -e "${RED}WARNING: This operation will stop and remove the WhatsApp Proxy service and all related files. This action is irreversible.${NC}"
    read -rp "Are you sure you want to proceed? (Y/N) " -n 1 -r confirm
    echo

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Stopping WhatsApp Proxy...${NC}"
        docker-compose -f "$compose_file" stop
        echo -e "${YELLOW}Removing WhatsApp Proxy service...${NC}"
        docker-compose -f "$compose_file" down -v --rmi all
        echo -e "${YELLOW}Removing '$proxy_dir' directory...${NC}"
        rm -rf "$proxy_dir"
        echo -e "${GREEN}WhatsApp Proxy service has been removed.${NC}"
    else
        echo -e "${GREEN}Cancelled removing WhatsApp Proxy service.${NC}"
    fi
}

# Function to manage the WhatsApp proxy service
manage_proxy() {
    local proxy_dir="proxy"
    local compose_file="/root/proxy/proxy/ops/docker-compose.yml"

    case "$1" in
        0)
            echo -e "${YELLOW}Checking WhatsApp Proxy status...${NC}"
            docker-compose -f "$compose_file" ps
            
            # Get server's public IP address
            server_ip=$(curl -s https://ipinfo.io/ip)

            # Generate the connection link
            connection_link="https://wa.me/proxy?host=$server_ip&chatPort=443&mediaPort=587&chatTLS=1"
            echo -e "${GREEN}To connect to WhatsApp Proxy, use the following link:${NC}"
            echo -e "$connection_link"

            # Generate QR code for the connection link
            echo -e "${GREEN}QR code for the connection link:${NC}"
            generate_qr_code "$connection_link"
            ;;
        1)
            echo -e "${YELLOW}Stopping WhatsApp Proxy...${NC}"
            docker-compose -f "$compose_file" stop
            echo -e "${GREEN}WhatsApp Proxy stopped successfully.${NC}"
            ;;
        2)
            echo -e "${GREEN}Starting WhatsApp Proxy...${NC}"
            docker-compose -f "$compose_file" start
            echo -e "${GREEN}WhatsApp Proxy started successfully.${NC}"
            ;;
        3)
            echo -e "${YELLOW}Restarting WhatsApp Proxy...${NC}"
            docker-compose -f "$compose_file" restart
            echo -e "${GREEN}WhatsApp Proxy restarted successfully.${NC}"
            ;;
        4)
            echo -e "${GREEN}Configuring WhatsApp Proxy...${NC}"
            ${EDITOR:-nano} "$compose_file"
            ;;
        5)
            remove_proxy
            ;;
        *)
            echo -e "${YELLOW}Manage WhatsApp Proxy Service${NC}"
            echo -e "0. Check WhatsApp Proxy Status"
            echo -e "1. Stop WhatsApp Proxy"
            echo -e "2. Start WhatsApp Proxy"
            echo -e "3. Restart WhatsApp Proxy"
            echo -e "4. Configure WhatsApp Proxy"
            echo -e "5. Remove WhatsApp Proxy Service"
            read -rp "Enter your choice (0-5) or press Enter to exit: " choice
            case "$choice" in
                0|1|2|3|4|5)
                    manage_proxy "$choice"
                    ;;
                "")
                    echo -e "${GREEN}Exiting script...${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Invalid choice. Exiting script.${NC}"
                    exit 1
                    ;;
            esac
            ;;
    esac
}


install() {
    echo -e "${RED}$0 <install|manage|remove>${NC}"
    echo -e " install: Update system packages, install Docker and Docker Compose, clone WhatsApp Proxy repository, and run the proxy service."
    echo -e " manage: Manage the WhatsApp Proxy service (start, stop, restart, configure)."
    echo -e " remove: Stop and remove the WhatsApp Proxy service and all related files."

    case "$1" in
        install)
            update_system
            install_docker
            install_docker_compose
            run_proxy
            check_proxy
            ;;
        manage)
            manage_proxy
            ;;
        remove)
            remove_proxy
            ;;
        *)
            exit 1
            ;;
    esac
    exit 0
}

install "$1"
