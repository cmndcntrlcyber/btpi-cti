#!/bin/bash
# Deploy script for Portainer service

set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}           Deploying Portainer Service               ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Check if running as root/sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script as root or with sudo privileges${NC}"
  exit 1
fi

# Navigate to script directory
cd "$(dirname "$0")"

# Ensure network exists
if ! docker network inspect cti-network > /dev/null 2>&1; then
    echo -e "${YELLOW}Required network 'cti-network' does not exist${NC}"
    echo -e "${YELLOW}Please run the create-network.sh script first${NC}"
    exit 1
fi

# Stop and remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^portainer$"; then
    echo "Stopping and removing existing Portainer container..."
    docker stop portainer >/dev/null 2>&1 || true
    docker rm portainer >/dev/null 2>&1 || true
fi

# Deploy the service
echo "Deploying Portainer..."
docker-compose up -d

# Verify deployment
if docker ps --format '{{.Names}}' | grep -q "^portainer$"; then
    echo -e "${GREEN}✓${NC} Portainer deployed successfully!"
    echo -e "  - UI available at: http://<your-ip>:9010"
    echo -e "  - Agent endpoint available at: http://<your-ip>:9000"
    echo -e "  - Secure UI available at: https://<your-ip>:9443"
else
    echo -e "${RED}✗${NC} Portainer deployment failed. Check logs with 'docker logs portainer'"
    exit 1
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✓${NC} Portainer deployment complete."
echo -e "${BLUE}=====================================================${NC}"
