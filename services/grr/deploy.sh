#!/bin/bash
# Deploy script for GRR Rapid Response service

set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}      Deploying GRR Rapid Response Service           ${NC}"
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

# Ensure config files are executable
chmod +x configs/repack_clients.sh
chmod +x configs/healthchecks/grr-admin-ui.sh

# Make secrets directory if it doesn't exist
mkdir -p ../../secrets

# Create required passwords if they don't exist
if [ ! -f "../../secrets/mysql_root_password" ]; then
    echo "Creating MySQL root password..."
    openssl rand -base64 16 > ../../secrets/mysql_root_password
    echo -e "${GREEN}✓${NC} MySQL root password created"
fi

if [ ! -f "../../secrets/mysql_password" ]; then
    echo "Creating MySQL user password..."
    openssl rand -base64 16 > ../../secrets/mysql_password
    echo -e "${GREEN}✓${NC} MySQL user password created"
fi

# Stop and remove existing containers if they exist
for container in grr-db grr-admin-ui grr-fleetspeak-frontend fleetspeak-admin fleetspeak-frontend grr-worker; do
    if docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
        echo "Stopping and removing existing $container container..."
        docker stop $container >/dev/null 2>&1 || true
        docker rm $container >/dev/null 2>&1 || true
    fi
done

# Deploy the service
echo "Deploying GRR Rapid Response services..."
docker-compose up -d

# Check if GRR Admin UI is running
echo "Waiting for GRR Admin UI to start (this may take a few minutes)..."
attempt=0
max_attempts=30
while [ $attempt -lt $max_attempts ]; do
    if docker ps --format '{{.Names}}' | grep -q "^grr-admin-ui$"; then
        echo -e "${GREEN}✓${NC} GRR Admin UI is running."
        break
    fi
    
    attempt=$((attempt+1))
    echo "Waiting for GRR Admin UI to start... ($attempt/$max_attempts)"
    sleep 10
    
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${YELLOW}⚠${NC} Timed out waiting for GRR Admin UI to start, but deployment continues."
        echo -e "${YELLOW}⚠${NC} Please check status with 'docker logs grr-admin-ui'"
    fi
done

# Check if all containers are running
all_running=true
for container in grr-db grr-admin-ui grr-fleetspeak-frontend fleetspeak-admin fleetspeak-frontend grr-worker; do
    if ! docker ps --format '{{.Names}}' | grep -q "^$container$"; then
        all_running=false
        echo -e "${RED}✗${NC} $container is not running"
    fi
done

if $all_running; then
    echo -e "${GREEN}✓${NC} All GRR Rapid Response services deployed successfully!"
    echo -e "  - GRR Admin UI available at: http://<your-ip>:8001"
else
    echo -e "${YELLOW}⚠${NC} Some GRR services failed to start. Check logs with 'docker logs [container-name]'"
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✓${NC} GRR Rapid Response deployment complete."
echo -e "${BLUE}=====================================================${NC}"
