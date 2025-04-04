#!/bin/bash
#
# CTI Platform Backup Script
# This script creates backups of all CTI platform components
#

set -e

# Configuration
BACKUP_DIR="/opt/cti-backups"
DATE_FORMAT=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${BACKUP_DIR}/cti-backup-${DATE_FORMAT}.tar.gz"
DOCKER_VOLUMES_DIR="/var/lib/docker/volumes"
CONFIG_DIR="$(pwd)/configs"
LOG_FILE="${BACKUP_DIR}/backup-${DATE_FORMAT}.log"

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Start logging
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "====================================================="
echo "  CTI Platform Backup - $(date)"
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

# Create temporary directory for backup
TEMP_BACKUP_DIR=$(mktemp -d)
echo "Creating temporary backup directory: ${TEMP_BACKUP_DIR}"

# Backup Docker volumes
echo "Backing up Docker volumes..."
mkdir -p "${TEMP_BACKUP_DIR}/volumes"

# Get list of volumes used by CTI containers
CTI_VOLUMES=$(docker volume ls --filter "name=cti" -q)

for volume in ${CTI_VOLUMES}; do
    echo "  - Backing up volume: ${volume}"
    
    # Create a temporary container to access the volume
    CONTAINER_ID=$(docker create -v "${volume}:/volume" --name "backup-${volume}" alpine:latest /bin/true)
    
    # Create directory for volume backup
    mkdir -p "${TEMP_BACKUP_DIR}/volumes/${volume}"
    
    # Copy data from volume to backup directory
    docker cp "${CONTAINER_ID}:/volume/." "${TEMP_BACKUP_DIR}/volumes/${volume}/"
    
    # Remove temporary container
    docker rm "${CONTAINER_ID}"
done

# Backup configuration files
echo "Backing up configuration files..."
mkdir -p "${TEMP_BACKUP_DIR}/configs"
cp -r "${CONFIG_DIR}"/* "${TEMP_BACKUP_DIR}/configs/"

# Backup docker-compose.yml
echo "Backing up docker-compose.yml..."
cp "$(pwd)/docker-compose.yml" "${TEMP_BACKUP_DIR}/"

# Backup environment files
echo "Backing up environment files..."
cp "$(pwd)/config.env" "${TEMP_BACKUP_DIR}/"

# Create compressed archive
echo "Creating compressed backup archive: ${BACKUP_FILE}"
tar -czf "${BACKUP_FILE}" -C "${TEMP_BACKUP_DIR}" .

# Clean up temporary directory
echo "Cleaning up temporary files..."
rm -rf "${TEMP_BACKUP_DIR}"

# Set appropriate permissions
chmod 600 "${BACKUP_FILE}"

# Display backup information
BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
echo ""
echo "Backup completed successfully!"
echo "  - Backup file: ${BACKUP_FILE}"
echo "  - Size: ${BACKUP_SIZE}"
echo "  - Log file: ${LOG_FILE}"
echo ""
echo "To restore this backup, use: ./restore.sh ${BACKUP_FILE}"
echo ""

exit 0
