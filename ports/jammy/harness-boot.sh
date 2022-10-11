#!/bin/bash

hciconfig hci0 up

if [ $HARNESS_ENV = "development" ]; then
   echo "Development environment. Starting docker-compose services"
   OS_VERSION=${OS_VERSION} docker-compose -f /home/harness/utilities/docker-compose.lib.yml up -d
elif [ $HARNESS_ENV = "production" ]; then
   echo "Production Environment. Not supported yet.."
fi
