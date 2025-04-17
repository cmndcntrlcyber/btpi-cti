#!/bin/bash
#
# Attack Workbench Setup Script for BTPI-CTI
# This script sets up the MITRE ATT&CK Workbench and integrates it with the CTI platform
#

set -e

WORKBENCH_DIR="/opt/btpi-cti/attack-workbench"
MONGO_PORT=27017
ATTACK_FRONTEND_PORT=9080
ATTACK_API_PORT=3500
ATTACK_FLOW_PORT=8000

echo "====================================================="
echo "  MITRE ATT&CK Workbench Setup for BTPI-CTI Platform"
echo "====================================================="
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Create directories
mkdir -p $WORKBENCH_DIR
cd $WORKBENCH_DIR

echo "Cloning Attack Workbench repositories..."
# Clone repositories if they don't exist
if [ ! -d "$WORKBENCH_DIR/attack-workbench-frontend" ]; then
    git clone https://github.com/center-for-threat-informed-defense/attack-workbench-frontend.git
fi

if [ ! -d "$WORKBENCH_DIR/attack-workbench-rest-api" ]; then
    git clone https://github.com/center-for-threat-informed-defense/attack-workbench-rest-api.git
fi

# Create a docker-compose file for Attack Workbench
echo "Creating Docker Compose configuration..."
cat > $WORKBENCH_DIR/docker-compose.yml << 'EOF'
version: '3'

services:
  frontend:
    container_name: attack-workbench-frontend
    image: ghcr.io/center-for-threat-informed-defense/attack-workbench-frontend:latest
    depends_on:
      - rest-api
    ports:
      - "9080:80"
    restart: unless-stopped
    networks:
      - attack-network
      - cti-network

  rest-api:
    container_name: attack-workbench-rest-api
    image: ghcr.io/center-for-threat-informed-defense/attack-workbench-rest-api:latest
    depends_on:
      - mongodb
    ports:
      - "3500:3000"
    environment:
      - DATABASE_URL=mongodb://mongodb:27017/attack-workspace
      - SERVICE_ACCOUNT_APIKEY_ENABLE=true
      - WORKBENCH_HOST=http://attack-workbench-rest-api
      - WORKBENCH_AUTHN_SERVICE_NAME=collection-manager
      - WORKBENCH_AUTHN_APIKEY=sample-key
    restart: unless-stopped
    networks:
      - attack-network
      - cti-network

  mongodb:
    container_name: attack-workbench-database
    image: mongo:latest
    volumes:
      - attack-db-data:/data/db
    ports:
      - "27017:27017"
    restart: unless-stopped
    networks:
      - attack-network
      - cti-network
  
  attack-flow:
    container_name: attack-flow-builder
    image: ghcr.io/center-for-threat-informed-defense/attack-flow:main
    ports:
      - "8000:80"
    restart: unless-stopped
    networks:
      - attack-network
      - cti-network

networks:
  attack-network:
    driver: bridge
  cti-network:
    external: true

volumes:
  attack-db-data:
EOF

# Create a Kasm proxy configuration for Attack Workbench
mkdir -p /opt/btpi-cti/configs/kasm-proxy

cat > /opt/btpi-cti/configs/kasm-proxy/attack-workbench.conf << 'EOF'
server {
    listen 443 ssl;
    server_name attack.kasm.local;

    # SSL configuration (uses Kasm's certificates)
    include /opt/kasm/current/conf/nginx/ssl.conf;

    location / {
        proxy_pass http://attack-workbench-frontend:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

cat > /opt/btpi-cti/configs/kasm-proxy/attack-flow.conf << 'EOF'
server {
    listen 443 ssl;
    server_name attack-flow.kasm.local;

    # SSL configuration (uses Kasm's certificates)
    include /opt/kasm/current/conf/nginx/ssl.conf;

    location / {
        proxy_pass http://attack-flow-builder:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Update hosts file for Attack Workbench domains
if ! grep -q "attack.kasm.local" /etc/hosts; then
    echo "127.0.0.1 attack.kasm.local" >> /etc/hosts
    echo "Added: attack.kasm.local to /etc/hosts"
fi

if ! grep -q "attack-flow.kasm.local" /etc/hosts; then
    echo "127.0.0.1 attack-flow.kasm.local" >> /etc/hosts
    echo "Added: attack-flow.kasm.local to /etc/hosts"
fi

# Start Attack Workbench Docker Compose
echo "Starting Attack Workbench services..."
cd $WORKBENCH_DIR
docker-compose up -d

# Configure Attack Workbench as a MITRE ATT&CK data source
echo "Waiting for Attack Workbench API to be ready..."
sleep 10

# Copy Kasm proxy configurations to Kasm Nginx directory if Kasm is installed
if [ -d "/opt/kasm/current/conf/nginx/servers" ]; then
    echo "Copying proxy configurations to Kasm Nginx directory..."
    cp /opt/btpi-cti/configs/kasm-proxy/attack-workbench.conf /opt/kasm/current/conf/nginx/servers/
    cp /opt/btpi-cti/configs/kasm-proxy/attack-flow.conf /opt/kasm/current/conf/nginx/servers/
    
    # Restart Kasm Nginx if running
    if systemctl is-active --quiet kasm_nginx; then
        echo "Restarting Kasm Nginx service..."
        systemctl restart kasm_nginx
    fi
fi

echo ""
echo "====================================================="
echo "  Attack Workbench Setup Complete"
echo "====================================================="
echo ""
echo "You can access the Attack Workbench at:"
echo "  - ATT&CK Workbench UI: http://localhost:$ATTACK_FRONTEND_PORT"
echo "  - ATT&CK Workbench API: http://localhost:$ATTACK_API_PORT"
echo "  - ATT&CK Flow Builder: http://localhost:$ATTACK_FLOW_PORT"
echo ""
if [ -d "/opt/kasm/current/conf/nginx/servers" ]; then
    echo "Via Kasm Workspaces:"
    echo "  - ATT&CK Workbench UI: https://attack.kasm.local"
    echo "  - ATT&CK Flow Builder: https://attack-flow.kasm.local"
fi
echo ""
echo "MongoDB is running on port $MONGO_PORT"
echo "====================================================="

exit 0
