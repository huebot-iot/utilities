#!/bin/bash

API_KEY=$1
SECRET_KEY=$2
INSTALL_TYPE=$3
AP_INTERFACE=$4
PORT=$5

NETWORK_NODE_AP_IP=192.168.101.1
MQTT_USERNAME=huebot_mqtt
MQTT_PASSWORD=$(openssl rand -base64 10)

# Disable interactive prompts
sudo sed -i "/^#\$nrconf{restart} = 'i';/ c\$nrconf{restart} = 'a';" /etc/needrestart/needrestart.conf;

echo "Installing required packages. This could take a while.."
sudo apt-get update && sudo apt-get -y upgrade

sudo apt-get install -y docker \
    docker-compose \
    network-manager \
    dnsmasq \
    jq \
    libnss-mdns # Allow '.local' access

# Set user group permissions
sudo usermod -aG docker,netdev huebot

# Preemptively create local mosquitto volumes so we can grant permissions (persistence wont work otherwise)
# Note: we grant permissions to port 1883 as it is used within the container
# Note 2: If we move to spawning multiple mqtt brokers we'd need to rethink persisence so they don't 
# override eachother
sudo mkdir /usr/local/bin/mosquitto/data
sudo chown -R 1883:1883 data
sudo mkdir /usr/local/bin/mosquitto/log
sudo chown -R 1883:1883 log

if [ $INSTALL_TYPE = "development" ]; then
    echo "Install extra packages for development"

    sudo apt-get --with-new-pkgs upgrade -y && \
        sudo apt-get full-upgrade -y && \
        sudo add-apt-repository ppa:deadsnakes/ppa -y && \
        sudo apt-get update

    curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash
    
    # Need to revisit when install next - need to delete bluez, but also wondering
    # if all packages can be deleted (including node) because we are developing
    # inside docker containers
    sudo apt-get install -yq software-properties-common \
        bluetooth \
        bluez \
        libbluetooth-dev \
        libudev-dev \
        libusb-1.0-0-dev \
        nodejs \
        build-essential \
        python3.8 \
        python3-pip

    # Set NPM global path
    mkdir ~/.npm-global
    npm config set prefix '~/.npm-global'
    echo "export PATH=~/.npm-global/bin:$PATH" >> ~/.profile
    source ~/.profile

    # Enable full mosquitto logging in dev mode
    cat <<EOT | sudo tee -a /usr/local/bin/mosquitto/conf.d/default.conf
log_type all
EOT


    # Make db dir so huebot user has permission access
    # Otherwise it will be created from docker dev container which will cause permission issues
    mkdir "/home/huebot/db"

fi

# Downgrade wpa_supplicant - latest version (2.10) has NM hotspot bug
# https://askubuntu.com/questions/1406149/cant-connect-to-ubuntu-22-04-hotspot
cat <<EOT | sudo tee -a /etc/apt/sources.list
deb http://old-releases.ubuntu.com/ubuntu/ impish main restricted universe multiverse
deb http://old-releases.ubuntu.com/ubuntu/ impish-updates main restricted universe multiverse
deb http://old-releases.ubuntu.com/ubuntu/ impish-security main restricted universe multiverse
EOT
sudo apt update
sudo apt --allow-downgrades install -y wpasupplicant=2:2.9.0-21build1

echo "Setting service and config files"
sudo cp "/home/huebot/utilities/ports/$PORT/huebot-boot.sh" /usr/local/bin/
sudo cp "/home/huebot/utilities/ports/$PORT/huebot-boot.service" /etc/systemd/system/
sudo systemctl enable huebot-boot.service

# Vars that determine hub run environment
cat <<EOT | sudo tee -a /usr/local/bin/config.json
{
    "status": "normal",
    "environment": "$INSTALL_TYPE",
    "mqtt_username": "",
    "mqtt_password": ""
}
EOT

echo "Disabling Netplan, enabling Network Manager"
# Start/enable network manager service
# sudo systemctl start NetworkManager.service 
sudo systemctl enable NetworkManager.service
# disable netplan
sudo rm /etc/netplan/*
sudo cp "/home/huebot/utilities/ports/$PORT/netplan-config.yaml" /etc/netplan/
# sudo netplan apply 

echo "Updating firewall policies"
sudo ufw allow 22 #ssh
sudo ufw allow 80 
sudo ufw allow 1883 #mqtt
sudo ufw allow in on $AP_INTERFACE # AP
sudo ufw --force enable

echo "Setting up MQTT"
cat <<EOT | sudo tee -a /etc/NetworkManager/conf.d/00-use-dnsmasq.conf
[main]
dns=dnsmasq
EOT

cat <<EOT | sudo tee -a /etc/NetworkManager/dnsmasq.d/00-dnsmasq-config.conf
interface=$AP_INTERFACE
dhcp-range=192.168.101.2,192.168.101.250,255.255.255.0,24h
local=/huebot/
EOT

echo "Updating hostname to API key"
sudo hostnamectl set-hostname $API_KEY
sudo sed -i "s/127.0.1.1\s.*/127.0.1.1 ${API_KEY}/g" /etc/hosts

# Setup server dns
cat <<EOT | sudo tee -a /etc/hosts
$NETWORK_NODE_AP_IP hub.huebot
EOT

# create mqtt password file
# Note: the password will get encrypted once mosquitto docker service is spun up (file is shared volume)
cat <<EOT | sudo tee -a /usr/local/bin/mosquitto/passwd
${MQTT_USERNAME}:${MQTT_PASSWORD}
EOT

# Set environment variables
cat <<EOT >> ~/.bashrc
export HUEBOT_API_KEY=${API_KEY}
export HUEBOT_SECRET_KEY=${SECRET_KEY}
export OS_VERSION=${PORT}
export NETWORK_NODE_AP_IP=${NETWORK_NODE_AP_IP}
export MQTT_USERNAME=${MQTT_USERNAME}
export MQTT_PASSWORD=${MQTT_PASSWORD}
EOT

echo "************************ INSTALL COMPLETE ************************"
echo ""
echo "Rebooting device"
echo "Login using: ssh huebot@${API_KEY}.local"
echo ""
echo "******************************************************************"

sudo reboot
