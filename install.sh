#!/bin/bash

# API key
API_KEY=$1

if [[ ! $API_KEY =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]; then
  echo "Install failed. First arg must be API key (uuid)"
  exit 1;
fi

# development | production (defaults to production)
INSTALL_TYPE=${2:-production}

PORT=$(cat /etc/os-release | grep -oP '(^|[ ,])VERSION_CODENAME=\K[^,]*')

if [ -z "$PORT" ]; then
  echo "Install failed. OS version not found"
  exit 1;
fi

cd /home/harness

# Clone repo if it doesn't exist locally or pull to update
git clone https://github.com/harness-iot/install.git 2> /dev/null || git -C install pull

DIR="/home/harness/install/ports/$PORT"

if [ ! -d $DIR ]; then
  echo "Install failed. OS version ($PORT) not supported"
  exit 1;
fi

echo "OS ($PORT) verified. Starting $INSTALL_TYPE install..."

# Run version-specific script
bash "$DIR/install.sh" $API_KEY $PORT $INSTALL_TYPE

