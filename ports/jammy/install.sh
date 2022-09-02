#!/bin/bash

PORT=$1
INSTALL_TYPE=$2

echo "Installing required packages. This could take a while.."
# sudo apt-get update > /dev/null && \
# sudo apt-get upgrade -y -qq 1> /dev/null || exit 1

# sudo apt-get install -y -qq docker docker-compose

# if [ $INSTALL_TYPE = "development" ]; then
#     echo "Install extra packages for development"

#     sudo apt-get --with-new-pkgs upgrade -y -qq 1> /dev/null && \
#         sudo aptitude full-upgrade -y -qq 1> /dev/null && \
#         sudo add-apt-repository ppa:deadsnakes/ppa -y -qq 1> /dev/null && \
#         sudo apt-get update && \
#         || exit 1

#     curl -sL https://deb.nodesource.com/setup_17.x | sudo -E bash 1> /dev/null || exit 1
#     sudo apt-get install -y -qq software-properties-common \ 
#         bluetooth \
#         bluez \
#         libbluetooth-dev \
#         libudev-dev \
#         libusb-1.0-0-dev \
#         nodejs \
#         sqlite3 \
#         build-essential \
#         python3.8 \
#         python3-pip \
# fi

echo "Setting service and config files"
sudo cp "$HOME/install/ports/$PORT/harness-boot.sh" /usr/local/bin/
sudo cp "$HOME/install/ports/$PORT/harness_env_vars" /usr/local/bin/
sudo cp "$HOME/install/ports/$PORT/harness-boot.service" /etc/systemd/system/
# Set system environment
sudo sed -ir "s/^[#]*\s*HARNESS_ENV=.*/HARNESS_ENV=$INSTALL_TYPE/" /usr/local/bin/harness_env_vars
sudo systemctl daemon-reload
sudo systemctl enable harness-boot.service
sudo systemctl start harness-boot.service
