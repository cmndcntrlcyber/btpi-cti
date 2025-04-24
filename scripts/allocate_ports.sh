#!/usr/bin/env bash
# Port allocation script for BTPI-CTI
# Dynamically assigns ports to avoid conflicts

set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}           BTPI-CTI Port Allocation                  ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Get script directory and parent
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PARENT_DIR/.env"

# Check if .env file exists, backup if it does
if [ -f "$ENV_FILE" ]; then
  cp "$ENV_FILE" "$ENV_FILE.bak"
  echo -e "${YELLOW}Backed up existing .env file to .env.bak${NC}"
fi

# Function to find a free port in a range
find_free_port() {
  local start_port=$1
  local end_port=$2
  local service_name=$3
  
  for port in $(seq $start_port $end_port); do
    if ! netstat -tuln | grep -q ":$port "; then
      echo "$service_name=$port"
      return 0
    fi
  done
  
  # If we get here, no ports were available
  echo "$service_name=$start_port # WARNING: No free ports found in range $start_port-$end_port" >&2
  return 1
}

# Create temporary file for new env
TMP_ENV=$(mktemp)

# Copy non-port settings from existing .env file
if [ -f "$ENV_FILE" ]; then
  grep -v "_PORT=" "$ENV_FILE" > "$TMP_ENV"
else
  # Add default settings if no .env exists
  cat > "$TMP_ENV" << EOF
# BTPI-CTI Environment Configuration
COMPOSE_PROJECT_NAME=btpi_cti
NETWORK=cti-network

# Build Tags
TAG=latest

# Resource Limits
ELASTICSEARCH_MEM_LIMIT=2048m
ELASTICSEARCH_JVM_HEAP=1g
CASSANDRA_MEM_LIMIT=2048m
CASSANDRA_MAX_HEAP_SIZE=1024M
CASSANDRA_HEAP_NEWSIZE=1024M
THEHIVE_MEM_LIMIT=2048m
THEHIVE_JVM_HEAP=1536M
MINIO_MEM_LIMIT=1024m
EOF
fi

# Add section header for ports
echo "" >> "$TMP_ENV"
echo "# Dynamic Ports (allocated $(date))" >> "$TMP_ENV"

# Allocate Portainer ports
echo "# Portainer" >> "$TMP_ENV"
find_free_port 9000 9010 "PORTAINER_AGENT_PORT" >> "$TMP_ENV"
find_free_port 9011 9020 "PORTAINER_PORT" >> "$TMP_ENV"
find_free_port 9440 9450 "PORTAINER_HTTPS_PORT" >> "$TMP_ENV"

# Allocate GRR ports
echo "" >> "$TMP_ENV"
echo "# GRR Rapid Response" >> "$TMP_ENV"
find_free_port 8000 8010 "GRR_ADMIN_UI_PORT" >> "$TMP_ENV"
find_free_port 3306 3310 "GRR_DB_PORT" >> "$TMP_ENV"

# Allocate TheHive & component ports
echo "" >> "$TMP_ENV"
echo "# TheHive & Components" >> "$TMP_ENV"
find_free_port 9000 9005 "THEHIVE_PORT" >> "$TMP_ENV"
find_free_port 9001 9010 "CORTEX_PORT" >> "$TMP_ENV"
find_free_port 9200 9210 "ELASTICSEARCH_PORT" >> "$TMP_ENV"
find_free_port 9300 9310 "ELASTICSEARCH_NODES_PORT" >> "$TMP_ENV"
find_free_port 9040 9050 "CASSANDRA_PORT" >> "$TMP_ENV"
find_free_port 10000 10010 "MINIO_PORT" >> "$TMP_ENV"
find_free_port 9090 9100 "MINIO_CONSOLE_PORT" >> "$TMP_ENV"

# Allocate MISP ports
echo "" >> "$TMP_ENV"
echo "# MISP & Components" >> "$TMP_ENV"
find_free_port 8080 8090 "MISP_HTTP_PORT" >> "$TMP_ENV"
find_free_port 8440 8450 "MISP_HTTPS_PORT" >> "$TMP_ENV"

# Allocate Integration API port
echo "" >> "$TMP_ENV"
echo "# Integration API" >> "$TMP_ENV"
find_free_port 8888 8898 "INTEGRATION_API_PORT" >> "$TMP_ENV"

# Move temporary file to .env
mv "$TMP_ENV" "$ENV_FILE"
chmod 644 "$ENV_FILE"

echo -e "${GREEN}Port allocation complete. New port settings written to .env${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Print the new port assignments
echo "New port assignments:"
grep "_PORT=" "$ENV_FILE" | sort
echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}Port allocation completed successfully.${NC}"
