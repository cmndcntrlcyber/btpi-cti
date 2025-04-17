#!/bin/bash
set -e

# Display banner
echo "======================================================="
echo "     🔧 BTPI-CTI Container Repair Script 🔧"
echo "======================================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

echo "🔍 Checking container status..."
docker ps -a

# 1. Fix GRR configuration issue
echo "🛠️ Fixing GRR configuration..."
# Update the Client.server_urls format in grr.server.yaml
sed -i 's/Client.server_urls: \[.*\]/Client.server_urls: \["http:\/\/fleetspeak-frontend:4443"\]/' grr_configs/server/grr.server.yaml
echo "✅ GRR configuration updated"

# 2. Fix MISP database issue
echo "🛠️ Fixing MISP database issue..."
echo "Stopping MISP containers..."
docker stop misp-core misp-modules misp-db 2>/dev/null || true

echo "Cleaning MISP database volume..."
# Create a temporary container to clean the volume
docker run --rm -v misp_data:/data alpine:latest sh -c "rm -rf /data/* || true"
echo "✅ MISP database volume cleaned"

# 3. Restart the containers
echo "🔄 Restarting containers..."
echo "Starting MISP containers in correct order..."
docker start misp-db
echo "Waiting for MISP database to initialize (60 seconds)..."
sleep 60
docker start misp-core misp-modules

echo "Restarting GRR containers..."
docker restart grr-fleetspeak-frontend grr-worker fleetspeak-frontend fleetspeak-admin

echo "🔍 Checking container status after fixes..."
docker ps -a

echo "✅ Repair process completed!"
echo "❗ Note: Container startup might take a few minutes."
echo "❗ Run 'docker logs <container_name>' to check startup progress."
echo "======================================================="
