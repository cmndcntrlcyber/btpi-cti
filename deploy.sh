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

# Process command line arguments
ALL_SERVICES=true
CLEAN_INSTALL=false
SPECIFIC_PROFILE=""

function print_usage {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  --all         Deploy all services (default)"
  echo "  --frontends   Deploy only frontend services"
  echo "  --backends    Deploy only backend services"
  echo "  --databases   Deploy only database services"
  echo "  --management  Deploy only management services"
  echo "  --thehive     Deploy TheHive, Cortex, and dependencies"
  echo "  --grr         Deploy GRR services"
  echo "  --misp        Deploy MISP services"
  echo "  --clean       Force clean installation (reinitialize volumes)"
  echo "  --help        Show this help message"
}

# Parse command line arguments
for arg in "$@"; do
  case $arg in
    --all)
      ALL_SERVICES=true
      SPECIFIC_PROFILE=""
      ;;
    --frontends)
      ALL_SERVICES=false
      SPECIFIC_PROFILE="frontends"
      ;;
    --backends)
      ALL_SERVICES=false
      SPECIFIC_PROFILE="backends"
      ;;
    --databases)
      ALL_SERVICES=false
      SPECIFIC_PROFILE="databases"
      ;;
    --management)
      ALL_SERVICES=false
      SPECIFIC_PROFILE="management"
      ;;
    --thehive)
      ALL_SERVICES=false
      SPECIFIC_PROFILE="thehive-frontend thehive-backend"
      ;;
    --grr)
      ALL_SERVICES=false
      SPECIFIC_PROFILE="grr-frontend grr-backend"
      ;;
    --misp)
      ALL_SERVICES=false
      SPECIFIC_PROFILE="misp-frontend misp-backend"
      ;;
    --clean)
      CLEAN_INSTALL=true
      ;;
    --help)
      print_usage
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $arg${NC}"
      print_usage
      exit 1
      ;;
  esac
done

# Print deployment information
echo "BTPI-CTI Cyber Threat Intelligence Platform"
echo "This script will deploy the following services:"

if [ "$ALL_SERVICES" = true ]; then
  echo "  - All services (Portainer, GRR, TheHive, MISP, Integration API)"
  PROFILE_ARG="--profile all"
else
  echo "  - Selected profile(s): $SPECIFIC_PROFILE"
  # Build profile arguments for docker-compose
  PROFILE_ARG=""
  for profile in $SPECIFIC_PROFILE; do
    PROFILE_ARG="$PROFILE_ARG --profile $profile"
  done
fi

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

# Check if secrets files exist, create them if they don't
if [ ! -f secrets/mysql_root_password ]; then
  echo "Creating random MySQL root password..."
  openssl rand -base64 16 > secrets/mysql_root_password
fi

if [ ! -f secrets/mysql_password ]; then
  echo "Creating random MySQL user password..."
  openssl rand -base64 16 > secrets/mysql_password
fi

if [ ! -f secrets/elastic_password ]; then
  echo "Creating random Elasticsearch password..."
  openssl rand -base64 16 > secrets/elastic_password
fi

if [ ! -f secrets/minio_root_user ]; then
  echo "Creating MinIO root user..."
  echo "minioadmin" > secrets/minio_root_user
fi

if [ ! -f secrets/minio_root_password ]; then
  echo "Creating random MinIO root password..."
  openssl rand -base64 16 > secrets/minio_root_password
fi

if [ ! -f secrets/thehive_secret ]; then
  echo "Creating random TheHive secret key..."
  openssl rand -base64 32 > secrets/thehive_secret
fi

if [ ! -f secrets/cortex_api_key ]; then
  echo "Creating random Cortex API key..."
  openssl rand -hex 32 > secrets/cortex_api_key
fi

if [ ! -f secrets/misp_root_password ]; then
  echo "Creating random MISP root password..."
  openssl rand -base64 16 > secrets/misp_root_password
fi

if [ ! -f secrets/misp_mysql_password ]; then
  echo "Creating random MISP MySQL password..."
  openssl rand -base64 16 > secrets/misp_mysql_password
fi

if [ ! -f secrets/misp_admin_password ]; then
  echo "Creating random MISP admin password..."
  openssl rand -base64 12 > secrets/misp_admin_password
fi

# Create Docker network
echo -e "\n${BLUE}Step 1: Creating Docker network...${NC}"
./scripts/create-network.sh

# Allocate ports dynamically
echo -e "\n${BLUE}Step 2: Allocating ports...${NC}"
./scripts/allocate_ports.sh
# Source the .env file to get port information
source .env

# Clean installation if requested
if [ "$CLEAN_INSTALL" = true ]; then
  echo -e "\n${YELLOW}Performing clean installation. Removing existing volumes...${NC}"
  docker-compose down -v
fi

# Deploy services
echo -e "\n${BLUE}Step 3: Deploying BTPI-CTI services...${NC}"
docker-compose $PROFILE_ARG up -d

# Make all scripts executable
find scripts -name "*.sh" -exec chmod +x {} \;

# Deployment summary
echo -e "\n${BLUE}=====================================================${NC}"
echo -e "${GREEN}BTPI-CTI Deployment Complete!${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo "Access your services at:"
echo -e "  - ${GREEN}Portainer:${NC} http://<your-ip>:${PORTAINER_PORT}"
echo -e "  - ${GREEN}GRR Admin UI:${NC} http://<your-ip>:${GRR_ADMIN_UI_PORT}"
echo -e "  - ${GREEN}TheHive:${NC} http://<your-ip>:${THEHIVE_PORT}"
echo -e "  - ${GREEN}Cortex:${NC} http://<your-ip>:${CORTEX_PORT}" 
echo -e "  - ${GREEN}MISP:${NC} http://<your-ip>:${MISP_HTTP_PORT}"
echo -e "  - ${GREEN}Integration API:${NC} http://<your-ip>:${INTEGRATION_API_PORT}"
echo ""
echo "MISP default credentials:"
echo "  - Username: admin@admin.test"
echo "  - Password: $(cat secrets/misp_admin_password 2>/dev/null || echo "Check secrets/misp_admin_password file")"
echo ""
echo -e "${YELLOW}Note:${NC} Some services may still be initializing. Check status with:"
echo "  docker ps"
echo ""
echo "Available profiles for selective deployment:"
echo "  - all          : All services"
echo "  - frontends    : All frontend services"
echo "  - backends     : All backend services"
echo "  - databases    : All database services"
echo "  - management   : Management tools (Portainer)"
echo "  - thehive-frontend : TheHive & Cortex"
echo "  - thehive-backend  : TheHive databases and dependencies" 
echo "  - grr-frontend     : GRR Admin UI"
echo "  - grr-backend      : GRR backend services"
echo "  - misp-frontend    : MISP frontend"
echo "  - misp-backend     : MISP databases and dependencies"
echo ""
echo "Example for deploying only frontend services:"
echo "  sudo ./deploy.sh --frontends"
echo -e "${BLUE}=====================================================${NC}"
