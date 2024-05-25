wget https://github.com/MvsCode/Whatsapp_proxy_server/blob/main/whatsapp_proxy_server.sh

sudo chmod +x whatsapp_proxy_server.sh
sudo ./whatsapp_proxy_server.sh


# Whatsapp_proxy_server

第 1 步：安裝 Docker和 Docker Compose
您可以按照所提供的說明快速輕鬆地在本地系統上激活代理服務。是時候啟動終端並通過輸入一些命令來安裝兩個必要的包了：


基於 Ubuntu/Debian 的發行版

$ sudo apt update && sudo apt upgrade 

$ sudo apt install docker.io


基於 CentOS、Fedora 和 RHEL 的發行版

$ sudo yum update -y

$ sudo yum install docker


然後，您必須運行以下命令來啟動該服務，該服務將在操作系統重新啟動時自行啟動並保持運行，無需人工干預。

$ sudo systemctl enable docker

$ sudo systemctl start docker


安裝 Docker 後，剩下要做的就是安裝 docker-compose，您可以通過運行以下命令來完成：

# Download the pkg
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose

# Enable execution of the script

sudo chmod +x /usr/bin/docker-compose

如果一切按計劃進行，docker --version和docker-compose --version命令將產生以下結果：

Docker version 20.10.12, build 20.10.12-0ubuntu2~20.04.1

Docker Compose version v2.15.1

第 2 步：克隆 WhatsApp 代理
接下來要做的是獲取實際文件，這將促進基於代理的 WhatsApp 連接。運行以下命令獲取代理文件：

sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose

sudo chmod +x /usr/bin/docker-compose

git clone https://github.com/WhatsApp/proxy.git

cd proxy/

docker build proxy/ -t whatsapp_proxy:1.0

docker run -it -p 5222:5222 whatsapp_proxy:1.0

docker-compose -f /root/proxy/proxy/ops/docker-compose.yml up


一键回程测试脚本
介绍

共有 8 个测试节点：北京电信、北京联通、北京移动，上海电信、上海联通、上海移动，深圳电信、深圳联通、深圳移动，成都教育网。

wget -qO- git.io/besttrace | bash
