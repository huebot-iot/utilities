#!/bin/bash
PORT=$(cat /etc/os-release | grep -oP '(^|[ ,])VERSION_CODENAME=\K[^,]*')

if [ -z "$PORT" ]; then
    echo "Install failed. OS version not found"
    exit 1;
fi

# Check if install repo exists locally

echo "CONTINUE!"