#!/bin/bash

PORT=$1
INSTALL_TYPE=$2

echo "Installing required packages. This could take a while.."
sudo apt-get update > /dev/null && \
sudo apt-get upgrade -y -qq 1> /dev/null || exit 1

sudo apt-get install -y -qq docker docker-compose

if [ $INSTALL_TYPE = "development" ]; then
    echo "Install extra packages for development"

    sudo apt-get --with-new-pkgs upgrade -y -qq && \
        sudo apt-get full-upgrade -y && \
        sudo add-apt-repository ppa:deadsnakes/ppa -y && \
        sudo apt-get update

    curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash || exit 1
    sudo apt-get install -y -qq software-properties-common \
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
fi

echo "Setting service and config files"
sudo cp "$HOME/install/ports/$PORT/harness-boot.sh" /usr/local/bin/
sudo cp "$HOME/install/ports/$PORT/harness_env_vars" /usr/local/bin/
sudo cp "$HOME/install/ports/$PORT/harness-boot.service" /etc/systemd/system/
# Set system environment
sudo sed -ir "s/^[#]*\s*HARNESS_ENV=.*/HARNESS_ENV=$INSTALL_TYPE/" /usr/local/bin/harness_env_vars
sudo systemctl daemon-reload
sudo systemctl enable harness-boot.service
sudo systemctl start harness-boot.service
