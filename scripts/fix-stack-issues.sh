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

# Create basic GRR health check script if it doesn't exist
if [ ! -f "grr_configs/healthchecks/grr-admin-ui.sh" ]; then
  echo "Creating GRR health check script..."
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
fi

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
