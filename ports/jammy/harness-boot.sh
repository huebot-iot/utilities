#!/bin/bash
if [ $HARNESS_ENV = "development" ]; then
   echo "Development environment. Starting docker-compose services"
   docker-compose -f /home/harness/install/docker-compose.lib.yml up -d
elif [ $HARNESS_ENV = "production" ]; then
   echo "Production Environment. Not supported yet.."
fi
