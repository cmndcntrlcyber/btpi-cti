#!/bin/bash
# Fix script for BTPI-CTI stack issues
# This script addresses several critical issues in the stack:
# 1. Elasticsearch password file permissions
# 2. GRR frontend service configuration 
# 3. GRR client repackaging
# 4. Port conflicts between containers

set -e
echo "Starting BTPI-CTI stack fixes..."

# 1. Fix Elasticsearch password file permissions
echo "Fixing Elasticsearch password file permissions..."
chmod 600 ./secrets/elastic_password
echo "Elastic password file permissions fixed."

# 2. Fix GRR frontend service configuration
echo "Fixing GRR frontend service configuration..."
cat > ./grr_configs/server/grr_frontend.service << 'EOF'
name: "GRR"
factory: "GRPC"
config {
  server_name: "fleetspeak-frontend"
  services_name: "GRR"
  verbose: true
}
EOF
echo "GRR frontend service configuration fixed."

# 3. Fix GRR client repackaging script
echo "Fixing GRR client repackaging script..."
cat > ./services/grr/configs/repack_clients.sh << 'EOF'
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
grr_config_updater repack_clients --platform=windows --output_dir=/client_installers

# Linux client
echo "Repacking Linux client..."
grr_config_updater repack_clients --platform=linux --output_dir=/client_installers

# macOS client
echo "Repacking macOS client..."
grr_config_updater repack_clients --platform=darwin --output_dir=/client_installers

echo "Client repackaging completed successfully."
exit 0
EOF
chmod +x ./services/grr/configs/repack_clients.sh
echo "GRR client repackaging script fixed."

# 4. Fix port conflicts by updating TheHive container port
echo "Fixing port conflicts between TheHive and Portainer..."
# This change updates the service-level docker-compose file for TheHive
if grep -q "\"9000:9000\"" ./services/thehive/docker-compose.yml; then
  sed -i 's/"9000:9000"/"9002:9000"/' ./services/thehive/docker-compose.yml
  echo "Updated TheHive port mapping to 9002:9000"
else
  echo "TheHive port mapping not found in expected format."
fi

# Ensure we fix any environment variables and the main docker-compose file
if [ -f ".env" ]; then
  if grep -q "THEHIVE_PORT=9000" .env; then
    sed -i 's/THEHIVE_PORT=9000/THEHIVE_PORT=9002/' .env
    echo "Updated THEHIVE_PORT in .env to 9002"
  fi
fi

# Also update main docker-compose if necessary
if grep -q "\"\${THEHIVE_PORT}:9000\"" ./docker-compose.yml; then
  echo "Confirmed THEHIVE_PORT reference exists in docker-compose.yml. The port will be picked up from .env"
fi

echo "All fixes have been applied. Please restart your containers for changes to take effect."
echo "You can use: sudo docker restart \$(sudo docker ps -aq)"
