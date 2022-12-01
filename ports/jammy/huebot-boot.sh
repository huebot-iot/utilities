#!/bin/bash

hciconfig hci0 up

ENVIRONMENT=$(jq .environment /usr/local/bin/config.json)

echo "Running $ENVIRONMENT environment"

# Always start up lib services
echo "Starting lib packages"
docker-compose -f /home/huebot/utilities/docker-compose.lib.yml up -d

if [ $ENVIRONMENT = "\""development"\"" ]; then
   echo "do nothing"
elif [ $ENVIRONMENT = "\""production"\"" ]; then
   STATUS=$(jq .status /usr/local/bin/config.json)
   if [ $STATUS = "\""update"\"" ]; then
      echo "TO DO: Handle mid progress update"
   else
      echo "Starting production core packages"
      docker-compose -f /home/huebot/utilities/docker-compose.core.yml up -d
fi
