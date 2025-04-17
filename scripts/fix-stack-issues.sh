#!/bin/bash
# Comprehensive script to fix BTPI-CTI stack issues
# Run this script with sufficient Docker permissions (e.g., sudo)

set -e
echo "Fixing BTPI-CTI stack configuration issues..."

# Create necessary configuration directories
echo "Creating required configuration directories..."
mkdir -p configs/nginx
mkdir -p grr_configs/server/textservices
mkdir -p grr_configs/healthchecks
mkdir -p integrations/cortex-thehive
mkdir -p integrations/grr-thehive
mkdir -p integrations/misp-thehive

# Create basic Nginx configuration if it doesn't exist
if [ ! -f "configs/nginx/default.conf" ]; then
  echo "Creating Nginx configuration..."
  cat > configs/nginx/default.conf << 'EOF'
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;
    
    access_log  /var/log/nginx/host.access.log  main;
    error_log   /var/log/nginx/error.log  warn;
    
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        try_files $uri $uri/ =404;
    }
    
    # Provide a status endpoint for healthchecks
    location /status {
        return 200 'Integration API is operational';
        add_header Content-Type text/plain;
    }
    
    # Redirect server error pages to the static page
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF
fi

# Create GRR configuration files
echo "Creating GRR configuration files..."

# Create GRR health check script
cat > grr_configs/healthchecks/grr-admin-ui.sh << 'EOF'
#!/bin/bash
# Simple health check for GRR admin UI
if curl -s http://localhost:8000/ | grep -q "GRR"; then
  exit 0
else
  exit 1
fi
EOF
chmod +x grr_configs/healthchecks/grr-admin-ui.sh

# Create repack clients script
cat > grr_configs/server/repack_clients.sh << 'EOF'
#!/bin/bash
# GRR Client Repackaging Script
# This script repacks GRR clients for different platforms

set -e

echo "Starting GRR client repackaging..."

# Ensure the client installers directory exists
mkdir -p /client_installers

# Check if we need to repack clients
# If client installers already exist, skip repackaging
if [ "$(ls -A /client_installers 2>/dev/null)" ]; then
  echo "Client installers already exist, skipping repackaging."
  exit 0
fi

# Otherwise, repack clients for all major platforms
echo "Repacking GRR clients for all platforms..."

# Windows client
echo "Repacking Windows client..."
grr_config_updater repack_clients --platform windows --output_dir=/client_installers

# Linux client
echo "Repacking Linux client..."
grr_config_updater repack_clients --platform linux --output_dir=/client_installers

# macOS client
echo "Repacking macOS client..."
grr_config_updater repack_clients --platform darwin --output_dir=/client_installers

echo "Client repackaging completed successfully."
exit 0
EOF
chmod +x grr_configs/server/repack_clients.sh

# Create GRR server configuration
cat > grr_configs/server/grr.server.yaml << 'EOF'
# GRR Server Configuration
# Basic configuration for GRR components

# Server Configuration
Client.server_urls: ["http://fleetspeak-frontend:4443/"]
Client.poll_max: 600
Client.poll_min: 60

# Database Configuration
Mysql.implementation: MySQLAdvanced
Mysql.host: mysql-host
Mysql.port: 3306
Mysql.username: grr
Mysql.password: $(cat /run/secrets/mysql_password)
Mysql.database: grr

# Admin UI Configuration
AdminUI.url: "http://admin-ui:8000/"
AdminUI.prompt_email_address_on_authorization_request: False
AdminUI.django_secret_key: "$(cat /run/secrets/thehive_secret)"

# Fleetspeak frontend Configuration
Server.fleetspeak_enabled: true
Server.fleetspeak_service_name: GRR

# Fleetspeak server address
Server.fleetspeak_server: fleetspeak-frontend:4443

# Logger Configuration
Logging.domain: localhost
Logging.verbose: True

# GRR Frontend Configuration
Frontend.bind_port: 11111
Frontend.bind_address: 0.0.0.0

# Worker Configuration
Worker.task_limit: 1000

# File storage configuration
Datastore.implementation: MySQLFleetspeak
Client.executable_signing_public_key: |
  -----BEGIN PUBLIC KEY-----
  MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEEIekOJ6vdWJzIk6YKp8mu31LAqJR
  w1pOJnfRUKdYhv2mQMWwJZrXE3HzKA3wHuNBWdlZYkveEsODMqXMZPeHBw==
  -----END PUBLIC KEY-----
EOF

# Create Fleetspeak admin components configuration
cat > grr_configs/server/textservices/admin.components.config << 'EOF'
# Fleetspeak admin components configuration
services {
  name: "GRR"
  factory: "GRPC"
  config {
    [type.googleapis.com/fleetspeak.grpcservice.Config] {
      target: "grr-fleetspeak-frontend:11111"
      insecure: true
    }
  }
}
EOF

# Create Fleetspeak frontend components configuration
cat > grr_configs/server/textservices/frontend.components.config << 'EOF'
# Fleetspeak frontend components configuration
services {
  name: "GRR"
  factory: "GRPC"
  config {
    [type.googleapis.com/fleetspeak.grpcservice.Config] {
      target: "grr-fleetspeak-frontend:11111"
      insecure: true
    }
  }
}
EOF

# Create GRR frontend service file
cat > grr_configs/server/grr_frontend.service << 'EOF'
name: "GRR"
EOF

# Create basic placeholder for integration
echo "Creating integration placeholders..."
for dir in integrations/*; do
  if [ -d "$dir" ]; then
    touch "$dir/index.html"
  fi
done

# Create a minimal index.html for integration API
cat > integrations/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>BTPI-CTI Integration API</title>
</head>
<body>
  <h1>BTPI-CTI Integration API</h1>
  <p>This is the integration API for BTPI-CTI components.</p>
  <ul>
    <li><a href="/cortex-thehive/">Cortex-TheHive Integration</a></li>
    <li><a href="/grr-thehive/">GRR-TheHive Integration</a></li>
    <li><a href="/misp-thehive/">MISP-TheHive Integration</a></li>
  </ul>
</body>
</html>
EOF

# Fix TheHive configuration
if [ ! -f "thehive-application.conf" ]; then
  echo "Downloading TheHive application configuration..."
  curl -sSL \
    https://raw.githubusercontent.com/StrangeBeeCorp/docker/prod1-thehive/thehive-application.conf \
    > thehive-application.conf
  echo "Configuration file downloaded."
fi

# Check if all required secret files exist, create if not
echo "Checking secret files..."
mkdir -p secrets

declare -a SECRET_FILES=(
  "secrets/mysql_root_password"
  "secrets/mysql_password"
  "secrets/elastic_password"
  "secrets/minio_root_user"
  "secrets/minio_root_password"
  "secrets/thehive_secret"
  "secrets/cortex_api_key"
  "secrets/misp_root_password"
  "secrets/misp_mysql_password"
  "secrets/misp_admin_password"
)

for secret_file in "${SECRET_FILES[@]}"; do
  if [ ! -f "$secret_file" ]; then
    echo "Creating missing secret file: $secret_file"
    if [[ "$secret_file" == *"user"* ]]; then
      echo "admin" > "$secret_file"
    else
      openssl rand -base64 16 > "$secret_file"
    fi
  fi
done

# Stop and remove problematic containers to allow clean start
echo "Stopping and removing problematic containers..."
docker-compose down --remove-orphans

# Restart the stack
echo "Restarting the entire stack..."
docker-compose up -d

echo "BTPI-CTI stack configuration fix completed."
echo "Check the status with: docker-compose ps"
echo "View logs with: docker-compose logs [service_name]"

# Integrate with Kasm Workspaces
echo ""
echo "====================================================="
echo "  Setting up Kasm Workspaces integration"
echo "====================================================="
echo ""
echo "This will configure Kasm Workspaces to proxy all CTI application interfaces."
echo "Would you like to proceed with Kasm Workspaces integration? (y/n)"
read -p " " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running Kasm integration script..."
    bash /opt/btpi-cti/scripts/kasm-integration.sh
else
    echo "Skipping Kasm integration. You can run it later with:"
    echo "  sudo /opt/btpi-cti/scripts/kasm-integration.sh"
fi
