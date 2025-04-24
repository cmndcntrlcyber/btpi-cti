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
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "Warning: .env file not found at $ENV_FILE, using default network name 'cti-network'"
    NETWORK="cti-network"
fi

# Remove existing network if it exists - to ensure it's created with proper labels
if docker network inspect ${NETWORK} > /dev/null 2>&1; then
    echo "Removing existing network '${NETWORK}'..."
    
    # Check if any containers are using the network
    CONTAINERS=$(docker network inspect ${NETWORK} -f '{{range .Containers}}{{.Name}} {{end}}')
    
    if [ ! -z "$CONTAINERS" ]; then
        echo "Disconnecting containers from network: $CONTAINERS"
        for container in $CONTAINERS; do
            docker network disconnect -f ${NETWORK} $container || true
        done
    fi
    
    # Remove the network
    docker network rm ${NETWORK} || true
    echo "Network '${NETWORK}' removed."
fi

# Create the network with proper labels for Docker Compose
echo "Creating '${NETWORK}'..."
# Do not add any Docker Compose specific labels - let Docker Compose manage those
docker network create \
    --driver=bridge \
    --subnet=172.20.0.0/16 \
    --gateway=172.20.0.1 \
    ${NETWORK}

echo -e "${GREEN}✓${NC} Network '${NETWORK}' created successfully."

echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✓${NC} Network setup complete."
echo -e "${BLUE}=====================================================${NC}"
