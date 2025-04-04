#!/bin/bash
#
# CTI Platform Restore Script
# This script restores backups of the CTI platform components
#

set -e

# Configuration
RESTORE_DIR="/opt/cti-restore"
DATE_FORMAT=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="/var/log/cti-restore-${DATE_FORMAT}.log"
CONFIG_DIR="$(pwd)/configs"

# Start logging
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "====================================================="
echo "  CTI Platform Restore - $(date)"
echo "====================================================="
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running"
    exit 1
fi

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Error: No backup file specified"
    echo "Usage: $0 <backup_file.tar.gz>"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "Error: Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

# Create temporary directory for restore
mkdir -p "${RESTORE_DIR}"
echo "Creating temporary restore directory: ${RESTORE_DIR}"

# Extract backup archive
echo "Extracting backup archive: ${BACKUP_FILE}"
tar -xzf "${BACKUP_FILE}" -C "${RESTORE_DIR}"

# Stop all CTI containers
echo "Stopping all CTI containers..."
docker-compose down || true

# Restore Docker volumes
echo "Restoring Docker volumes..."
if [ -d "${RESTORE_DIR}/volumes" ]; then
    for volume_dir in "${RESTORE_DIR}/volumes"/*; do
        if [ -d "${volume_dir}" ]; then
            volume_name=$(basename "${volume_dir}")
            echo "  - Restoring volume: ${volume_name}"
            
            # Check if volume exists, create if not
            if ! docker volume inspect "${volume_name}" > /dev/null 2>&1; then
                echo "    Creating volume: ${volume_name}"
                docker volume create "${volume_name}"
            fi
            
            # Create a temporary container to access the volume
            CONTAINER_ID=$(docker create -v "${volume_name}:/volume" --name "restore-${volume_name}" alpine:latest /bin/true)
            
            # Copy data from backup to volume
            docker cp "${volume_dir}/." "${CONTAINER_ID}:/volume/"
            
            # Remove temporary container
            docker rm "${CONTAINER_ID}"
        fi
    done
else
    echo "Warning: No volumes found in backup"
fi

# Restore configuration files
echo "Restoring configuration files..."
if [ -d "${RESTORE_DIR}/configs" ]; then
    mkdir -p "${CONFIG_DIR}"
    cp -r "${RESTORE_DIR}/configs"/* "${CONFIG_DIR}/"
else
    echo "Warning: No configuration files found in backup"
fi

# Restore docker-compose.yml
echo "Restoring docker-compose.yml..."
if [ -f "${RESTORE_DIR}/docker-compose.yml" ]; then
    cp "${RESTORE_DIR}/docker-compose.yml" "$(pwd)/docker-compose.yml"
else
    echo "Warning: docker-compose.yml not found in backup"
fi

# Restore environment files
echo "Restoring environment files..."
if [ -f "${RESTORE_DIR}/config.env" ]; then
    cp "${RESTORE_DIR}/config.env" "$(pwd)/config.env"
else
    echo "Warning: config.env not found in backup"
fi

# Clean up temporary directory
echo "Cleaning up temporary files..."
rm -rf "${RESTORE_DIR}"

# Start CTI containers
echo "Starting CTI containers..."
docker-compose up -d

# Display restore information
echo ""
echo "Restore completed successfully!"
echo "  - Restored from: ${BACKUP_FILE}"
echo "  - Log file: ${LOG_FILE}"
echo ""
echo "Please verify that all services are running correctly:"
echo "  docker-compose ps"
echo ""

exit 0
