#!/bin/bash

API_KEY=$1
SECRET_KEY=$2
INSTALL_TYPE=${3:-production} # development | production (defaults to production)
AP_INTERFACE=$4

if [[ ! $API_KEY =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]; then
  echo "Install failed. First arg must be API key (uuid)"
  exit 1;
fi

if [[ ! $SECRET_KEY =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]; then
  echo "Install failed. Second arg must be secret key (uuid)"
  exit 1;
fi

PORT=$(cat /etc/os-release | grep -oP '(^|[ ,])VERSION_CODENAME=\K[^,]*')

if [ -z "$PORT" ]; then
  echo "Install failed. OS version not found"
  exit 1;
fi

cd /home/huebot

# Clone repo if it doesn't exist locally or pull to update
git clone https://github.com/huebot-iot/utilities.git 2> /dev/null || git -C install pull

DIR="/home/huebot/utilities/ports/$PORT"

if [ ! -d $DIR ]; then
  echo "Install failed. OS version ($PORT) not supported"
  exit 1;
fi

echo "OS ($PORT) verified. Starting $INSTALL_TYPE install..."

# Run version-specific script
bash "$DIR/install.sh" $API_KEY $SECRET_KEY $INSTALL_TYPE $AP_INTERFACE $PORT 

