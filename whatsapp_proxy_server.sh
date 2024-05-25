#!/bin/bash

# Install Docker and Docker Compose
echo "Installing Docker and Docker Compose..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose

# Clone the WhatsApp proxy repository
echo "Cloning the WhatsApp proxy repository..."
git clone https://github.com/WhatsApp/proxy.git
cd proxy

# Build the Docker image
echo "Building the Docker image..."
docker build proxy/ -t whatsapp_proxy:1.0

# Run the proxy
echo "Starting the WhatsApp proxy..."
docker run -it -p 5222:5222 whatsapp_proxy:1.0
docker-compose -f /root/proxy/proxy/ops/docker-compose.yml up
