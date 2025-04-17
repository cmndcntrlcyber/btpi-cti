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

# Check if the network already exists
if docker network inspect cti-network > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Network 'cti-network' already exists. Using existing network."
else
    # Create the network
    echo "Creating 'cti-network'..."
    docker network create \
        --driver=bridge \
        --subnet=172.20.0.0/16 \
        --gateway=172.20.0.1 \
        cti-network
    
    echo -e "${GREEN}✓${NC} Network 'cti-network' created successfully."
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✓${NC} Network setup complete."
echo -e "${BLUE}=====================================================${NC}"
