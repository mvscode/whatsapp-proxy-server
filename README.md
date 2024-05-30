# WhatsApp Proxy Server Deployment Script

This Bash script automates the process of updating system packages, installing Docker and Docker Compose, cloning the WhatsApp Proxy repository, building a Docker image, and starting the WhatsApp proxy service using Docker Compose.

## Prerequisites

- Linux operating system (tested on Debian and CentOS)
- Git installed
- Internet connection

## Usage

1. Clone this repository:

   ```bash
   git clone https://github.com/your-username/whatsapp-proxy-script.git
cd whatsapp-proxy-script
Change to the script directory:
bash
cd whatsapp-proxy-script

Make the script executable:
bash
chmod +x whatsapp-proxy.sh

Run the script with sudo:
bash
sudo ./whatsapp-proxy.sh

The script will prompt you to confirm the system update. Enter "Y" to proceed.
The script will perform the following tasks:
Update system packages
Install Docker if not already installed
Install Docker Compose if not already installed
Clone the WhatsApp Proxy repository
Build a Docker image
Start the WhatsApp proxy service using Docker Compose
After the script completes successfully, the WhatsApp proxy service should be running. You can check its status using:
bash
sudo docker ps

Look for a container with the name "whatsapp_proxy".
Customization
You can modify the docker-compose.yml file located in the ops directory to customize the proxy configuration.
Adjust the compose_file variable in the run_proxy function to point to the correct location of the docker-compose.yml file.
Troubleshooting
If you encounter any issues during the script execution, check the error messages and logs for more information.
Make sure your Linux distribution is supported (Debian or CentOS).
Ensure that you have the necessary permissions to run Docker commands.
Contributing
If you find any bugs or have suggestions for improvements, feel free to open an issue or submit a pull request.
License
This project is licensed under the MIT License.

Remember to replace `your-username` with your actual GitHub username in the cloning command.

This README provides a basic structure and instructions for us
