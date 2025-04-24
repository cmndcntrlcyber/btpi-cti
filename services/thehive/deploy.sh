#!/bin/bash
# Deploy script for TheHive service

set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}           Deploying TheHive Service                 ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Check if running as root/sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script as root or with sudo privileges${NC}"
  exit 1
fi

# Navigate to script directory
cd "$(dirname "$0")"

# Export network variable from environment or default to cti-network
export NETWORK=${NETWORK:-cti-network}
export COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-btpi_cti}

# Ensure network exists
if ! docker network inspect ${NETWORK} > /dev/null 2>&1; then
    echo -e "${YELLOW}Required network '${NETWORK}' does not exist${NC}"
    echo -e "${YELLOW}Please run the create-network.sh script first${NC}"
    exit 1
fi

# Make secrets directory if it doesn't exist
mkdir -p ../../secrets

# Create required passwords if they don't exist
if [ ! -f "../../secrets/elastic_password" ]; then
    echo "Creating Elasticsearch password..."
    openssl rand -base64 16 > ../../secrets/elastic_password
    echo -e "${GREEN}✓${NC} Elasticsearch password created"
fi

if [ ! -f "../../secrets/minio_root_user" ]; then
    echo "Creating MinIO root user..."
    echo "admin" > ../../secrets/minio_root_user
    echo -e "${GREEN}✓${NC} MinIO root user created"
fi

if [ ! -f "../../secrets/minio_root_password" ]; then
    echo "Creating MinIO root password..."
    openssl rand -base64 16 > ../../secrets/minio_root_password
    echo -e "${GREEN}✓${NC} MinIO root password created"
fi

if [ ! -f "../../secrets/thehive_secret" ]; then
    echo "Creating TheHive secret..."
    openssl rand -base64 32 > ../../secrets/thehive_secret
    echo -e "${GREEN}✓${NC} TheHive secret created"
fi

if [ ! -f "../../secrets/cortex_api_key" ]; then
    echo "Creating Cortex API key..."
    openssl rand -hex 32 > ../../secrets/cortex_api_key
    echo -e "${GREEN}✓${NC} Cortex API key created"
fi

# Stop and remove existing containers if they exist
for container in elasticsearch minio cassandra cortex thehive; do
    prefixed_container="${COMPOSE_PROJECT_NAME}_${container}"
    if docker ps -a --format '{{.Names}}' | grep -q "^${prefixed_container}$"; then
        echo "Stopping and removing existing ${prefixed_container} container..."
        docker stop ${prefixed_container} >/dev/null 2>&1 || true
        docker rm ${prefixed_container} >/dev/null 2>&1 || true
    fi
done

# Deploy the service
echo "Deploying TheHive services..."
docker-compose up -d

# Wait for Elasticsearch to become healthy
echo "Waiting for Elasticsearch to initialize (this may take a few minutes)..."
attempt=0
max_attempts=30
while [ $attempt -lt $max_attempts ]; do
    if docker ps --format '{{.Status}}' | grep -q "${COMPOSE_PROJECT_NAME}_elasticsearch.*healthy"; then
        echo -e "${GREEN}✓${NC} Elasticsearch is healthy."
        break
    fi
    
    attempt=$((attempt+1))
    echo "Waiting for Elasticsearch to become healthy... ($attempt/$max_attempts)"
    sleep 10
    
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${YELLOW}⚠${NC} Timed out waiting for Elasticsearch to become healthy."
        echo -e "${YELLOW}⚠${NC} Deployment continues, but TheHive may not work correctly."
    fi
done

# Wait for TheHive to become available
echo "Waiting for TheHive to initialize (this may take a few minutes)..."
attempt=0
max_attempts=30
while [ $attempt -lt $max_attempts ]; do
    if docker ps --format '{{.Names}}' | grep -q "^${COMPOSE_PROJECT_NAME}_thehive$"; then
        echo -e "${GREEN}✓${NC} TheHive is running."
        break
    fi
    
    attempt=$((attempt+1))
    echo "Waiting for TheHive to start... ($attempt/$max_attempts)"
    sleep 10
    
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${YELLOW}⚠${NC} Timed out waiting for TheHive to start."
        echo -e "${YELLOW}⚠${NC} Please check status with 'docker logs ${COMPOSE_PROJECT_NAME}_thehive'"
    fi
done

# Check if all containers are running
all_running=true
for container in elasticsearch minio cassandra cortex thehive; do
    prefixed_container="${COMPOSE_PROJECT_NAME}_${container}"
    if ! docker ps --format '{{.Names}}' | grep -q "^${prefixed_container}$"; then
        all_running=false
        echo -e "${RED}✗${NC} ${prefixed_container} is not running"
    fi
done

if $all_running; then
    echo -e "${GREEN}✓${NC} All TheHive services deployed successfully!"
    echo -e "  - TheHive UI available at: http://<your-ip>:9000"
    echo -e "  - Cortex UI available at: http://<your-ip>:9001"
    echo -e "  - MinIO UI available at: http://<your-ip>:9090"
    echo -e "  - Elasticsearch API available at: http://<your-ip>:9200"
else
    echo -e "${YELLOW}⚠${NC} Some TheHive services failed to start. Check logs with 'docker logs [container-name]'"
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✓${NC} TheHive deployment complete."
echo -e "${BLUE}=====================================================${NC}"
