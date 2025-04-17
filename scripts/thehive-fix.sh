#!/bin/bash
# Script to fix TheHive Docker image tag issue and restart services
# Run this script with sufficient Docker permissions (e.g., with sudo)

set -e
echo "Fixing TheHive Docker configuration..."

# Verify that the thehive-application.conf exists
if [ ! -f "thehive-application.conf" ]; then
  echo "Downloading TheHive application configuration..."
  curl -sSL \
    https://raw.githubusercontent.com/StrangeBeeCorp/docker/prod1-thehive/thehive-application.conf \
    > thehive-application.conf
  echo "Configuration file downloaded."
fi

# Pull the specific TheHive image
echo "Pulling TheHive image with specific tag (5.2.7-1)..."
docker-compose pull thehive

# Restart TheHive service
echo "Restarting TheHive service..."
docker-compose up -d thehive

# Verify service status
echo "Verifying service status..."
docker-compose ps thehive
docker logs thehive --tail 20

echo "TheHive configuration fix completed."
echo "If you encounter any issues, check the logs with: docker logs thehive"
