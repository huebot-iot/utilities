#!/bin/bash

API_KEY=$1
SECRET_KEY=$2
INSTALL_TYPE=$3
AP_INTERFACE=$4
PORT=$5

# Disable interactive prompts
sudo sed -i "/^#\$nrconf{restart} = 'i';/ c\$nrconf{restart} = 'a';" /etc/needrestart/needrestart.conf;

echo "Installing required packages. This could take a while.."
sudo apt-get update && sudo apt-get -y upgrade

sudo apt-get install -y docker \
    docker-compose \
    network-manager \
    isc-dhcp-server \
    libnss-mdns # Allow '.local' access

# Set user group permissions
sudo usermod -aG docker,netdev harness

# Make user sudoer (don't require pw for sudo commands)
echo 'harness ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers.d/010_harness-nopasswd

if [ $INSTALL_TYPE = "development" ]; then
    echo "Install extra packages for development"

    sudo apt-get --with-new-pkgs upgrade -y && \
        sudo apt-get full-upgrade -y && \
        sudo add-apt-repository ppa:deadsnakes/ppa -y && \
        sudo apt-get update

    curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash
    sudo apt-get install -yq software-properties-common \
        bluetooth \
        bluez \
        libbluetooth-dev \
        libudev-dev \
        libusb-1.0-0-dev \
        nodejs \
        sqlite3 \
        build-essential \
        python3.8 \
        python3-pip

    # Set NPM global path
    mkdir ~/.npm-global
    npm config set prefix '~/.npm-global'
    echo "export PATH=~/.npm-global/bin:$PATH" >> ~/.profile
    source ~/.profile

    # Required for Bleno
    sudo npm install -g node-gyp
    sudo setcap cap_net_raw+eip $(eval readlink -f `which node`)
    sudo service bluetooth stop
    sudo systemctl disable bluetooth

    # Set alias helpers
    cat <<EOT >> ~/.bashrc
alias run_api='cd ${HOME}/hub && npm run api:dev'
alias run_controller='cd ${HOME}/hub && npm run controller:dev'
alias run_broker='cd ${HOME}/hub && npm run broker:dev'
EOT

fi

echo "Setting service and config files"
sudo cp "/home/harness/install/ports/$PORT/harness-boot.sh" /usr/local/bin/
sudo cp "/home/harness/install/ports/$PORT/harness_env_vars" /usr/local/bin/
sudo cp "/home/harness/install/ports/$PORT/harness-boot.service" /etc/systemd/system/
# Set system environment
sudo sed -ir "s/^[#]*\s*HARNESS_ENV=.*/HARNESS_ENV=$INSTALL_TYPE/" /usr/local/bin/harness_env_vars
sudo systemctl daemon-reload
sudo systemctl enable harness-boot.service
# sudo systemctl start harness-boot.service

echo "Disabling Netplan, enabling Network Manager"
# Start/enable network manager service
# sudo systemctl start NetworkManager.service 
sudo systemctl enable NetworkManager.service
# disable netplan
sudo rm /etc/netplan/*
sudo cp "/home/harness/install/ports/$PORT/netplan-config.yaml" /etc/netplan/
# sudo netplan apply 

echo "Updating firewall policies"
sudo ufw allow 22 #ssh
sudo ufw allow 80 
sudo ufw allow 1883 #mqtt
sudo ufw --force enable

echo "Setting up MQTT AP"
sudo mv /etc/dhcp/dhcpd.conf{,.original}
sudo cp "/home/harness/install/ports/$PORT/dhcpd.conf" /etc/dhcp/
# Overwrite file
cat <<EOT > /etc/default/isc-dhcp-server
DHCPDv4_CONF=/etc/dhcp/dhcpd.conf
INTERFACESv4="$AP_INTERFACE"
INTERFACESv6=""
EOT

echo "Updating hostname to API key"
sudo hostnamectl set-hostname $API_KEY
sudo sed -i "s/127.0.1.1\s.*/127.0.1.1 ${API_KEY}/g" /etc/hosts

# Set environment variables
cat <<EOT >> ~/.bashrc
export HARNESS_API_KEY=${API_KEY}
export HARNESS_SECRET_KEY=${SECRET_KEY}
export OS_VERSION=${PORT}
EOT

echo "************************ INSTALL COMPLETE ************************"
echo ""
echo "Rebooting device"
echo "Login using: ssh harness@${API_KEY}.local"
echo ""
echo "******************************************************************"

sudo reboot
