#!/bin/bash
# Deploy script for OpenBAS service

set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}           Deploying OpenBAS Service                 ${NC}"
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

# Create directories
mkdir -p ./data
mkdir -p ./logs
mkdir -p ./conf

# Create secrets directory if it doesn't exist
mkdir -p ../../secrets

# Check if secrets files exist, create them if they don't
if [ ! -f "../../secrets/openbas_admin_password" ]; then
    echo "Creating OpenBAS admin password..."
    echo "changeme" > ../../secrets/openbas_admin_password
    echo -e "${GREEN}✓${NC} OpenBAS admin password created (default: changeme)"
    echo -e "${YELLOW}⚠${NC} Please change this password after first login"
fi

if [ ! -f "../../secrets/openbas_admin_token" ]; then
    echo "Creating random OpenBAS admin token..."
    openssl rand -hex 32 > ../../secrets/openbas_admin_token
    echo -e "${GREEN}✓${NC} OpenBAS admin token created"
fi

if [ ! -f "../../secrets/rabbitmq_user" ]; then
    echo "Creating RabbitMQ user..."
    echo "openbas" > ../../secrets/rabbitmq_user
    echo -e "${GREEN}✓${NC} RabbitMQ user created"
fi

if [ ! -f "../../secrets/rabbitmq_password" ]; then
    echo "Creating random RabbitMQ password..."
    openssl rand -base64 16 > ../../secrets/rabbitmq_password
    echo -e "${GREEN}✓${NC} RabbitMQ password created"
fi

# Create the .env file for OpenBAS
cat > ./.env << EOF
OPENBAS_ADMIN_EMAIL=admin@openbas.io
OPENBAS_ADMIN_PASSWORD=$(cat ../../secrets/openbas_admin_password)
OPENBAS_ADMIN_TOKEN=$(cat ../../secrets/openbas_admin_token)
OPENBAS_BASE_URL=http://localhost:\${OPENBAS_PORT}
MINIO_ROOT_USER=$(cat ../../secrets/minio_root_user)
MINIO_ROOT_PASSWORD=$(cat ../../secrets/minio_root_password)
RABBITMQ_DEFAULT_USER=$(cat ../../secrets/rabbitmq_user)
RABBITMQ_DEFAULT_PASS=$(cat ../../secrets/rabbitmq_password)
SMTP_HOSTNAME=localhost
EOF

# Stop and remove existing containers if they exist
for container in openbas worker; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${COMPOSE_PROJECT_NAME}_${container}$"; then
        echo "Stopping and removing existing ${container} container..."
        docker stop ${COMPOSE_PROJECT_NAME}_${container} >/dev/null 2>&1 || true
        docker rm ${COMPOSE_PROJECT_NAME}_${container} >/dev/null 2>&1 || true
    fi
done

# Clean volumes if requested
if [ "$1" == "--clean" ] || [ "$1" == "-c" ]; then
    echo -e "${YELLOW}Cleaning OpenBAS volumes...${NC}"
    docker volume rm openbas_esdata openbas_s3data openbas_redisdata openbas_amqpdata >/dev/null 2>&1 || true
    echo -e "${GREEN}✓${NC} OpenBAS volumes cleaned"
else
    echo "Using existing OpenBAS volumes (use --clean for a fresh start)"
fi

# Deploy OpenBAS
echo "Deploying OpenBAS services..."
source ../../.env
docker-compose up -d

# Check if all containers are running
all_running=true
for container in openbas worker; do
    if ! docker ps --format '{{.Names}}' | grep -q "^${COMPOSE_PROJECT_NAME}_${container}$"; then
        all_running=false
        echo -e "${RED}✗${NC} ${container} is not running"
    fi
done

if $all_running; then
    echo -e "${GREEN}✓${NC} All OpenBAS services deployed successfully!"
    echo -e "  - OpenBAS UI available at: http://<your-ip>:${OPENBAS_PORT}"
    echo -e "  - OpenBAS Admin credentials:"
    echo -e "    - Username: admin@openbas.io"
    echo -e "    - Password: $(cat ../../secrets/openbas_admin_password)"
else
    echo -e "${YELLOW}⚠${NC} Some OpenBAS services failed to start. Check logs with 'docker logs [container-name]'"
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✓${NC} OpenBAS deployment complete."
echo -e "${BLUE}=====================================================${NC}"
