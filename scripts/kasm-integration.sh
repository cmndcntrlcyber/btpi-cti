#!/bin/bash
#
# Kasm Workspaces Integration Script for BTPI-CTI
# This script configures Kasm Workspaces to proxy all CTI application interfaces
#

set -e

KASM_NGINX_DIR="/opt/kasm/current/conf/nginx/servers"
CTI_APPS_CONFIG_DIR="/opt/btpi-cti/configs/kasm-proxy"

echo "====================================================="
echo "  Kasm Workspaces Integration for CTI Platform"
echo "====================================================="
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Check if Kasm is installed
if [ ! -d "/opt/kasm" ]; then
    echo "Kasm Workspaces is not installed. Installing now..."
    bash /opt/btpi-cti/kasm-scripts/install_kasm.sh
else
    echo "Kasm Workspaces is already installed."
fi

# Create directories for Kasm proxy configurations
mkdir -p $CTI_APPS_CONFIG_DIR

# Create proxy configurations for each CTI application
echo "Creating proxy configurations for CTI applications..."

# TheHive proxy configuration
cat > $CTI_APPS_CONFIG_DIR/thehive.conf << 'EOF'
server {
    listen 443 ssl;
    server_name thehive.kasm.local;

    # SSL configuration (uses Kasm's certificates)
    include /opt/kasm/current/conf/nginx/ssl.conf;

    location / {
        proxy_pass http://thehive:9000;
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

# Cortex proxy configuration
cat > $CTI_APPS_CONFIG_DIR/cortex.conf << 'EOF'
server {
    listen 443 ssl;
    server_name cortex.kasm.local;

    # SSL configuration (uses Kasm's certificates)
    include /opt/kasm/current/conf/nginx/ssl.conf;

    location / {
        proxy_pass http://cortex:9001;
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

# MISP proxy configuration
cat > $CTI_APPS_CONFIG_DIR/misp.conf << 'EOF'
server {
    listen 443 ssl;
    server_name misp.kasm.local;

    # SSL configuration (uses Kasm's certificates)
    include /opt/kasm/current/conf/nginx/ssl.conf;

    location / {
        proxy_pass http://misp-core:80;
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

# GRR proxy configuration
cat > $CTI_APPS_CONFIG_DIR/grr.conf << 'EOF'
server {
    listen 443 ssl;
    server_name grr.kasm.local;

    # SSL configuration (uses Kasm's certificates)
    include /opt/kasm/current/conf/nginx/ssl.conf;

    location / {
        proxy_pass http://grr-admin-ui:8000;
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

# Portainer proxy configuration
cat > $CTI_APPS_CONFIG_DIR/portainer.conf << 'EOF'
server {
    listen 443 ssl;
    server_name portainer.kasm.local;

    # SSL configuration (uses Kasm's certificates)
    include /opt/kasm/current/conf/nginx/ssl.conf;

    location / {
        proxy_pass http://portainer:9000;
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

# Copy proxy configurations to Kasm Nginx directory
echo "Copying proxy configurations to Kasm Nginx directory..."
if [ -d "$KASM_NGINX_DIR" ]; then
    cp $CTI_APPS_CONFIG_DIR/*.conf $KASM_NGINX_DIR/
    echo "Configurations copied successfully."
else
    echo "Error: Kasm Nginx directory not found at $KASM_NGINX_DIR"
    echo "You may need to manually copy the configurations after Kasm installation completes."
fi

# Update /etc/hosts file with entries for the proxy domains
echo "Updating /etc/hosts file with entries for proxy domains..."
ENTRIES=(
    "127.0.0.1 thehive.kasm.local"
    "127.0.0.1 cortex.kasm.local"
    "127.0.0.1 misp.kasm.local"
    "127.0.0.1 grr.kasm.local"
    "127.0.0.1 portainer.kasm.local"
)

for ENTRY in "${ENTRIES[@]}"; do
    if ! grep -q "$ENTRY" /etc/hosts; then
        echo "$ENTRY" >> /etc/hosts
        echo "Added: $ENTRY"
    else
        echo "Entry already exists: $ENTRY"
    fi
done

# Restart Kasm Nginx service if running
if systemctl is-active --quiet kasm_nginx; then
    echo "Restarting Kasm Nginx service..."
    systemctl restart kasm_nginx
    echo "Kasm Nginx service restarted."
else
    echo "Kasm Nginx service is not running. It will use the new configurations when started."
fi

echo ""
echo "====================================================="
echo "  Kasm Workspaces Integration Complete"
echo "====================================================="
echo ""
echo "You can now access CTI applications through Kasm Workspaces at:"
echo "  - TheHive:    https://thehive.kasm.local"
echo "  - Cortex:     https://cortex.kasm.local"
echo "  - MISP:       https://misp.kasm.local"
echo "  - GRR:        https://grr.kasm.local"
echo "  - Portainer:  https://portainer.kasm.local"
echo ""
echo "Make sure to add these entries to your hosts file on client machines."
echo "====================================================="

exit 0
