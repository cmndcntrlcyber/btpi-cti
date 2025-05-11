#!/bin/bash
set -e

# Display banner
echo "======================================================="
echo "     🔧 BTPI-CTI GRR Repair Script 🔧"
echo "======================================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

echo "🔍 Checking container status..."
docker ps -a

# Fix GRR configuration issue
echo "🛠️ Fixing GRR configuration..."
# Update the Client.server_urls format in grr.server.yaml
sed -i 's/Client.server_urls: \[.*\]/Client.server_urls: \["http:\/\/fleetspeak-frontend:4443"\]/' grr_configs/server/grr.server.yaml
echo "✅ GRR configuration updated"

# Restart the containers
echo "🔄 Restarting containers..."
echo "Restarting GRR containers..."
docker restart grr-fleetspeak-frontend grr-worker fleetspeak-frontend fleetspeak-admin

echo "🔍 Checking container status after fixes..."
docker ps -a

echo "✅ Repair process completed!"
echo "❗ Note: Container startup might take a few minutes."
echo "❗ Run 'docker logs <container_name>' to check startup progress."
echo "======================================================="
