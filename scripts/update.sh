#!/bin/bash
#
# CTI Platform Update Script
# This script updates all CTI platform components
#

set -e

# Configuration
DATE_FORMAT=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="/var/log/cti-update-${DATE_FORMAT}.log"
BACKUP_BEFORE_UPDATE=true
RESTART_AFTER_UPDATE=true

# Start logging
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "====================================================="
echo "  CTI Platform Update - $(date)"
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

# Function to display help
show_help() {
    echo "CTI Platform Update Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help                 Display this help message"
    echo "  -n, --no-backup            Skip backup before update"
    echo "  -r, --no-restart           Don't restart services after update"
    echo "  -c, --component NAME       Update specific component only"
    echo "  -f, --force                Force update even if no updates are available"
    echo "  -v, --verbose              Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0                         Update all components"
    echo "  $0 -c thehive              Update TheHive only"
    echo "  $0 -n -r                   Update without backup or restart"
    echo ""
}

# Parse command line arguments
COMPONENT=""
FORCE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            show_help
            exit 0
            ;;
        -n|--no-backup)
            BACKUP_BEFORE_UPDATE=false
            shift
            ;;
        -r|--no-restart)
            RESTART_AFTER_UPDATE=false
            shift
            ;;
        -c|--component)
            COMPONENT="$2"
            shift
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $key"
            show_help
            exit 1
            ;;
    esac
done

# Function to create backup
create_backup() {
    echo "Creating backup before update..."
    
    if [ -f "$(pwd)/scripts/backup.sh" ]; then
        bash "$(pwd)/scripts/backup.sh"
        if [ $? -ne 0 ]; then
            echo "Warning: Backup failed, but continuing with update"
        else
            echo "Backup completed successfully"
        fi
    else
        echo "Warning: Backup script not found at $(pwd)/scripts/backup.sh"
        echo "Skipping backup"
    fi
}

# Function to update Docker images
update_images() {
    local component=$1
    
    if [ -z "$component" ]; then
        echo "Updating all Docker images..."
        docker-compose pull
    else
        echo "Updating Docker image for $component..."
        docker-compose pull "$component"
    fi
}

# Function to update specific component
update_component() {
    local component=$1
    
    echo "Updating $component..."
    
    case $component in
        thehive)
            update_images "thehive"
            if [ "$RESTART_AFTER_UPDATE" = true ]; then
                echo "Restarting TheHive..."
                docker-compose up -d --no-deps thehive
            fi
            ;;
        cortex)
            update_images "cortex"
            if [ "$RESTART_AFTER_UPDATE" = true ]; then
                echo "Restarting Cortex..."
                docker-compose up -d --no-deps cortex
            fi
            ;;
        misp)
            update_images "misp"
            if [ "$RESTART_AFTER_UPDATE" = true ]; then
                echo "Restarting MISP..."
                docker-compose up -d --no-deps misp
            fi
            ;;
        grr)
            update_images "grr"
            if [ "$RESTART_AFTER_UPDATE" = true ]; then
                echo "Restarting GRR..."
                docker-compose up -d --no-deps grr
            fi
            ;;
        portainer)
            update_images "portainer"
            if [ "$RESTART_AFTER_UPDATE" = true ]; then
                echo "Restarting Portainer..."
                docker-compose up -d --no-deps portainer
            fi
            ;;
        *)
            echo "Unknown component: $component"
            echo "Available components: thehive, cortex, misp, grr, portainer"
            return 1
            ;;
    esac
    
    echo "$component updated successfully"
}

# Function to update all components
update_all() {
    echo "Updating all CTI platform components..."
    
    # Pull all Docker images
    update_images
    
    if [ "$RESTART_AFTER_UPDATE" = true ]; then
        echo "Restarting all services..."
        docker-compose up -d
    fi
    
    echo "All components updated successfully"
}

# Function to check for updates
check_for_updates() {
    echo "Checking for updates..."
    
    # This is a simplified check - in a real implementation you would check
    # for new versions of each component
    
    local updates_available=false
    
    # Check for Docker image updates
    for image in $(docker-compose config --services); do
        local image_id=$(docker-compose images -q "$image")
        local remote_image=$(docker-compose config | grep "image:" | grep "$image" | awk '{print $2}')
        
        if [ -n "$remote_image" ]; then
            echo "Checking for updates to $image ($remote_image)..."
            
            # Pull the image silently to check for updates
            docker pull "$remote_image" > /dev/null 2>&1
            
            local new_id=$(docker images -q "$remote_image")
            
            if [ "$image_id" != "$new_id" ]; then
                echo "  - Update available for $image"
                updates_available=true
            else
                echo "  - $image is up to date"
            fi
        fi
    done
    
    if [ "$updates_available" = false ] && [ "$FORCE" = false ]; then
        echo "No updates available"
        return 1
    fi
    
    return 0
}

# Main update process
echo "Starting update process..."

# Create backup if enabled
if [ "$BACKUP_BEFORE_UPDATE" = true ]; then
    create_backup
fi

# Check for updates
if ! check_for_updates && [ "$FORCE" = false ]; then
    echo "No updates available. Use --force to update anyway."
    exit 0
fi

# Perform update
if [ -z "$COMPONENT" ]; then
    update_all
else
    update_component "$COMPONENT"
fi

echo ""
echo "Update completed successfully!"
echo "  - Log file: ${LOG_FILE}"
echo ""

if [ "$RESTART_AFTER_UPDATE" = false ]; then
    echo "Note: Services were not restarted. Use the following command to restart:"
    echo "  docker-compose up -d"
fi

exit 0
