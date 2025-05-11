#!/bin/bash
# Deploy script for OpenCTI service

set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}           Deploying OpenCTI Service                 ${NC}"
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
if [ ! -f "../../secrets/opencti_admin_password" ]; then
    echo "Creating OpenCTI admin password..."
    echo "changeme" > ../../secrets/opencti_admin_password
    echo -e "${GREEN}✓${NC} OpenCTI admin password created (default: changeme)"
    echo -e "${YELLOW}⚠${NC} Please change this password after first login"
fi

if [ ! -f "../../secrets/opencti_admin_token" ]; then
    echo "Creating random OpenCTI admin token..."
    openssl rand -hex 32 > ../../secrets/opencti_admin_token
    echo -e "${GREEN}✓${NC} OpenCTI admin token created"
fi

if [ ! -f "../../secrets/rabbitmq_user" ]; then
    echo "Creating RabbitMQ user..."
    echo "opencti" > ../../secrets/rabbitmq_user
    echo -e "${GREEN}✓${NC} RabbitMQ user created"
fi

if [ ! -f "../../secrets/rabbitmq_password" ]; then
    echo "Creating random RabbitMQ password..."
    openssl rand -base64 16 > ../../secrets/rabbitmq_password
    echo -e "${GREEN}✓${NC} RabbitMQ password created"
fi

# Generate UUIDs for connectors if they don't exist
if [ ! -f "../../secrets/opencti_connector_export_file_stix_id" ]; then
    echo "Creating connector IDs..."
    uuidgen > ../../secrets/opencti_connector_export_file_stix_id
    uuidgen > ../../secrets/opencti_connector_export_file_csv_id
    uuidgen > ../../secrets/opencti_connector_export_file_txt_id
    uuidgen > ../../secrets/opencti_connector_import_file_stix_id
    uuidgen > ../../secrets/opencti_connector_import_document_id
    echo -e "${GREEN}✓${NC} Connector IDs created"
fi

# Create the .env file for OpenCTI
cat > ./.env << EOF
OPENCTI_ADMIN_EMAIL=admin@opencti.io
OPENCTI_ADMIN_PASSWORD=$(cat ../../secrets/opencti_admin_password)
OPENCTI_ADMIN_TOKEN=$(cat ../../secrets/opencti_admin_token)
OPENCTI_BASE_URL=http://localhost:\${OPENCTI_PORT}
MINIO_ROOT_USER=$(cat ../../secrets/minio_root_user)
MINIO_ROOT_PASSWORD=$(cat ../../secrets/minio_root_password)
RABBITMQ_DEFAULT_USER=$(cat ../../secrets/rabbitmq_user)
RABBITMQ_DEFAULT_PASS=$(cat ../../secrets/rabbitmq_password)
CONNECTOR_EXPORT_FILE_STIX_ID=$(cat ../../secrets/opencti_connector_export_file_stix_id)
CONNECTOR_EXPORT_FILE_CSV_ID=$(cat ../../secrets/opencti_connector_export_file_csv_id)
CONNECTOR_EXPORT_FILE_TXT_ID=$(cat ../../secrets/opencti_connector_export_file_txt_id)
CONNECTOR_IMPORT_FILE_STIX_ID=$(cat ../../secrets/opencti_connector_import_file_stix_id)
CONNECTOR_IMPORT_DOCUMENT_ID=$(cat ../../secrets/opencti_connector_import_document_id)
SMTP_HOSTNAME=localhost
EOF

# Stop and remove existing containers if they exist
for container in opencti worker connector-export-file-stix connector-export-file-csv connector-export-file-txt connector-import-file-stix connector-import-document; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${COMPOSE_PROJECT_NAME}_${container}$"; then
        echo "Stopping and removing existing ${container} container..."
        docker stop ${COMPOSE_PROJECT_NAME}_${container} >/dev/null 2>&1 || true
        docker rm ${COMPOSE_PROJECT_NAME}_${container} >/dev/null 2>&1 || true
    fi
done

# Clean volumes if requested
if [ "$1" == "--clean" ] || [ "$1" == "-c" ]; then
    echo -e "${YELLOW}Cleaning OpenCTI volumes...${NC}"
    docker volume rm opencti_esdata opencti_s3data opencti_redisdata opencti_amqpdata >/dev/null 2>&1 || true
    echo -e "${GREEN}✓${NC} OpenCTI volumes cleaned"
else
    echo "Using existing OpenCTI volumes (use --clean for a fresh start)"
fi

# Deploy OpenCTI
echo "Deploying OpenCTI services..."
source ../../.env
docker-compose up -d

# Check if all containers are running
all_running=true
for container in opencti worker connector-export-file-stix connector-export-file-csv connector-export-file-txt connector-import-file-stix connector-import-document; do
    if ! docker ps --format '{{.Names}}' | grep -q "^${COMPOSE_PROJECT_NAME}_${container}$"; then
        all_running=false
        echo -e "${RED}✗${NC} ${container} is not running"
    fi
done

if $all_running; then
    echo -e "${GREEN}✓${NC} All OpenCTI services deployed successfully!"
    echo -e "  - OpenCTI UI available at: http://<your-ip>:${OPENCTI_PORT}"
    echo -e "  - OpenCTI Admin credentials:"
    echo -e "    - Username: admin@opencti.io"
    echo -e "    - Password: $(cat ../../secrets/opencti_admin_password)"
else
    echo -e "${YELLOW}⚠${NC} Some OpenCTI services failed to start. Check logs with 'docker logs [container-name]'"
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✓${NC} OpenCTI deployment complete."
echo -e "${BLUE}=====================================================${NC}"
