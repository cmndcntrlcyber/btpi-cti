#!/bin/bash
# Script to create the Docker network for BTPI-CTI services

set -e

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}      Creating Docker Network for BTPI-CTI Services   ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Source the .env file for variables
if [ -f ../.env ]; then
    source ../.env
else
    echo "Warning: .env file not found, using default network name 'cti-network'"
    NETWORK="cti-network"
fi

# Check if the network already exists
if docker network inspect ${NETWORK} > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Network '${NETWORK}' already exists. Using existing network."
else
    # Create the network
    echo "Creating '${NETWORK}'..."
    docker network create \
        --driver=bridge \
        --subnet=172.20.0.0/16 \
        --gateway=172.20.0.1 \
        ${NETWORK}
    
    echo -e "${GREEN}✓${NC} Network '${NETWORK}' created successfully."
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✓${NC} Network setup complete."
echo -e "${BLUE}=====================================================${NC}"
