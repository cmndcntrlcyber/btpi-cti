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
