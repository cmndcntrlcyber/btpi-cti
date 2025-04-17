#!/bin/bash
# Deploy script for MISP service

set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}           Deploying MISP Service                    ${NC}"
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

# Make secrets directory if it doesn't exist
mkdir -p ../../secrets

# Create required passwords if they don't exist
if [ ! -f "../../secrets/misp_root_password" ]; then
    echo "Creating MISP MySQL root password..."
    openssl rand -base64 16 > ../../secrets/misp_root_password
    echo -e "${GREEN}✓${NC} MISP MySQL root password created"
fi

if [ ! -f "../../secrets/misp_mysql_password" ]; then
    echo "Creating MISP MySQL user password..."
    openssl rand -base64 16 > ../../secrets/misp_mysql_password
    echo -e "${GREEN}✓${NC} MISP MySQL user password created"
fi

if [ ! -f "../../secrets/misp_admin_password" ]; then
    echo "Creating MISP admin password..."
    openssl rand -base64 12 > ../../secrets/misp_admin_password
    echo -e "${GREEN}✓${NC} MISP admin password created"
fi

# Stop and remove existing containers if they exist
for container in redis misp-db misp-modules misp-core; do
    if docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
        echo "Stopping and removing existing $container container..."
        docker stop $container >/dev/null 2>&1 || true
        docker rm $container >/dev/null 2>&1 || true
    fi
done

# Clean MISP volumes only if requested
if [ "$1" == "--clean" ] || [ "$1" == "-c" ]; then
    echo -e "${YELLOW}Cleaning MISP database volume...${NC}"
    docker volume rm misp_data >/dev/null 2>&1 || true
    docker volume create misp_data >/dev/null 2>&1
    echo -e "${GREEN}✓${NC} MISP database volume cleaned"
else
    echo "Using existing MISP volumes (use --clean for a fresh start)"
fi

# Deploy database and redis first
echo "Deploying MISP database and Redis services..."
docker-compose up -d misp-db redis

# Wait for MySQL to initialize
echo "Waiting for MySQL to initialize..."
attempt=0
max_attempts=30
while [ $attempt -lt $max_attempts ]; do
    # Try to ping the database
    if docker exec misp-db mysqladmin ping -h localhost -u misp -p"$(cat ../../secrets/misp_mysql_password)" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} MISP database is ready."
        break
    fi
    
    attempt=$((attempt+1))
    echo "Waiting for MySQL to initialize... ($attempt/$max_attempts)"
    sleep 10
    
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${YELLOW}⚠${NC} Timed out waiting for MySQL to initialize."
        echo -e "${YELLOW}⚠${NC} Proceeding with deployment, but MISP may not start correctly."
    fi
done

# Deploy MISP core and modules
echo "Deploying MISP core and modules..."
docker-compose up -d misp-core misp-modules

# Wait for MISP to become available
echo "Waiting for MISP to initialize (this may take a few minutes)..."
attempt=0
max_attempts=30
while [ $attempt -lt $max_attempts ]; do
    if docker ps --format '{{.Status}}' | grep -q "misp-core.*healthy"; then
        echo -e "${GREEN}✓${NC} MISP is healthy."
        break
    fi
    
    attempt=$((attempt+1))
    echo "Waiting for MISP to become healthy... ($attempt/$max_attempts)"
    sleep 10
    
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${YELLOW}⚠${NC} Timed out waiting for MISP to become healthy."
        echo -e "${YELLOW}⚠${NC} Please check status with 'docker logs misp-core'"
    fi
done

# Check if all containers are running
all_running=true
for container in redis misp-db misp-modules misp-core; do
    if ! docker ps --format '{{.Names}}' | grep -q "^$container$"; then
        all_running=false
        echo -e "${RED}✗${NC} $container is not running"
    fi
done

if $all_running; then
    echo -e "${GREEN}✓${NC} All MISP services deployed successfully!"
    echo -e "  - MISP UI available at: http://<your-ip>:8083"
    echo -e "  - MISP Admin credentials:"
    echo -e "    - Username: admin@admin.test"
    echo -e "    - Password: $(cat ../../secrets/misp_admin_password)"
else
    echo -e "${YELLOW}⚠${NC} Some MISP services failed to start. Check logs with 'docker logs [container-name]'"
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✓${NC} MISP deployment complete."
echo -e "${BLUE}=====================================================${NC}"
