#!/bin/bash
# Master deployment script for BTPI-CTI

set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}              BTPI-CTI Deployment                    ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Check if running as root/sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script as root or with sudo privileges${NC}"
  exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Print deployment information
echo "BTPI-CTI Cyber Threat Intelligence Platform"
echo "This script will deploy the following services:"
echo "  - Portainer (Container Management)"
echo "  - GRR (Rapid Response)"
echo "  - TheHive (Case Management)"
echo "  - MISP (Threat Intelligence)"
echo "  - Integration API"
echo ""
echo -e "${YELLOW}Note: This deployment may take 15-30 minutes depending on your system.${NC}"
echo ""

# Ask for confirmation
read -p "Do you want to proceed with deployment? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Create secrets directory if it doesn't exist
mkdir -p secrets

# Create Docker network
echo -e "\n${BLUE}Step 1: Creating Docker network...${NC}"
./scripts/create-network.sh

# Deploy Portainer
echo -e "\n${BLUE}Step 2: Deploying Portainer...${NC}"
cd "$SCRIPT_DIR/services/portainer"
./deploy.sh
cd "$SCRIPT_DIR"

# Deploy GRR
echo -e "\n${BLUE}Step 3: Deploying GRR Rapid Response...${NC}"
cd "$SCRIPT_DIR/services/grr"
# Use --clean flag to ensure clean database initialization
./deploy.sh --clean
cd "$SCRIPT_DIR"

# Deploy TheHive
echo -e "\n${BLUE}Step 4: Deploying TheHive...${NC}"
cd "$SCRIPT_DIR/services/thehive"
./deploy.sh
cd "$SCRIPT_DIR"

# Deploy MISP
echo -e "\n${BLUE}Step 5: Deploying MISP...${NC}"
cd "$SCRIPT_DIR/services/misp"
# Use --clean flag to ensure clean database initialization
./deploy.sh --clean
cd "$SCRIPT_DIR"

# Deploy Integration API
echo -e "\n${BLUE}Step 6: Deploying Integration API...${NC}"
cd "$SCRIPT_DIR/services/integration-api"
./deploy.sh
cd "$SCRIPT_DIR"

# Make all deploy scripts executable
find services -name "deploy.sh" -exec chmod +x {} \;
chmod +x scripts/*.sh

# Deployment summary
echo -e "\n${BLUE}=====================================================${NC}"
echo -e "${GREEN}BTPI-CTI Deployment Complete!${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo "Access your services at:"
echo -e "  - ${GREEN}Portainer:${NC} http://<your-ip>:9010"
echo -e "  - ${GREEN}GRR Admin UI:${NC} http://<your-ip>:8001"
echo -e "  - ${GREEN}TheHive:${NC} http://<your-ip>:9000"
echo -e "  - ${GREEN}Cortex:${NC} http://<your-ip>:9001" 
echo -e "  - ${GREEN}MISP:${NC} http://<your-ip>:8083"
echo -e "  - ${GREEN}Integration API:${NC} http://<your-ip>:8888"
echo ""
echo "MISP default credentials:"
echo "  - Username: admin@admin.test"
echo "  - Password: $(cat secrets/misp_admin_password 2>/dev/null || echo "Check secrets/misp_admin_password file")"
echo ""
echo -e "${YELLOW}Note:${NC} Some services may still be initializing. Check status with:"
echo "  docker ps"
echo ""
echo "To manage individual services, use the deploy scripts in each service directory:"
echo "  sudo ./services/[service-name]/deploy.sh"
echo -e "${BLUE}=====================================================${NC}"
