#!/bin/bash

hciconfig hci0 up

ENVIRONMENT=$(jq .environment /usr/local/bin/config.json)

echo "Running $ENVIRONMENT environment"

# Always start up lib services
docker-compose -f /home/harness/utilities/docker-compose.lib.yml up -d

if [ $ENVIRONMENT = "\""development"\"" ]; then
   echo "do nothing"
elif [ $ENVIRONMENT = "\""production"\"" ]; then
   STATUS=$(jq .status /usr/local/bin/config.json)
   if [ $STATUS = "\""update"\"" ]; then
      echo "TO DO: Handle mid progress update"
   else
      echo "TO DO: Run docker-compose core"
fi
