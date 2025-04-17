#!/bin/bash
#
# CTI Infrastructure Management Script
# This script provides utilities for managing the CTI infrastructure
#

set -e

# Configuration - can be overridden by config.env
CONFIG_FILE="./config.env"
CTI_DIR=$(pwd)
LOG_FILE="$CTI_DIR/cti-management.log"
BACKUP_DIR="$CTI_DIR/backups"

# Load configuration if available
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_DIR"

# Logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Display help
show_help() {
    echo "CTI Infrastructure Management Script"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  status              Show status of all CTI components"
    echo "  start               Start all CTI components"
    echo "  stop                Stop all CTI components"
    echo "  restart             Restart all CTI components"
    echo "  backup              Create a backup of all data"
    echo "  restore [BACKUP]    Restore from a backup"
    echo "  update              Update all components to latest versions"
    echo "  logs [COMPONENT]    Show logs for a specific component or all"
    echo "  health              Run health checks on all components"
    echo "  config              Show current configuration"
    echo "  setup-integration   Configure integrations between components"
    echo "  add-user            Add a new user to the infrastructure"
    echo "  help                Show this help message"
    echo ""
    echo "Options:"
    echo "  --force             Force operation even if warnings occur"
    echo "  --quiet             Suppress output except for errors"
    echo "  --verbose           Show detailed output"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 logs thehive"
    echo "  $0 backup"
    echo "  $0 update --force"
    echo ""
}

# Check Docker status
check_docker() {
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log "ERROR" "Docker daemon is not running or current user doesn't have permissions"
        log "INFO" "Try running: sudo systemctl start docker"
        log "INFO" "Or add current user to docker group: sudo usermod -aG docker $USER"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log "ERROR" "Docker Compose is not installed or not in PATH"
        exit 1
    fi
}

# Show status of all components
show_status() {
    log "INFO" "Checking status of CTI infrastructure components..."
    
    # Check all containers
    log "INFO" "Container Status:"
    docker-compose ps
    
    # Check resource usage
    log "INFO" "Resource Usage:"
    docker stats --no-stream
    
    # Check disk space
    log "INFO" "Disk Space:"
    df -h | grep -E '(Filesystem|/$)'
    
    # Check memory usage
    log "INFO" "Memory Usage:"
    free -h
    
    # Show port usage
    log "INFO" "Port Usage:"
    netstat -tulpn | grep -E '(Proto|docker)'
    
    log "INFO" "Status check completed"
}

# Start all components
start_components() {
    log "INFO" "Starting CTI infrastructure components..."
    docker-compose up -d
    log "INFO" "All components started"
}

# Stop all components
stop_components() {
    log "INFO" "Stopping CTI infrastructure components..."
    docker-compose down
    log "INFO" "All components stopped"
}

# Restart all components
restart_components() {
    log "INFO" "Restarting CTI infrastructure components..."
    docker-compose restart
    log "INFO" "All components restarted"
}

# Show logs for components
show_logs() {
    local component=$1
    
    if [ -z "$component" ]; then
        log "INFO" "Showing logs for all components..."
        docker-compose logs --tail=100
    else
        log "INFO" "Showing logs for component: $component..."
        if docker-compose logs "$component" 2>/dev/null; then
            docker-compose logs --tail=100 "$component"
        else
            log "ERROR" "Component not found: $component"
            log "INFO" "Available components:"
            docker-compose ps --services
            exit 1
        fi
    fi
}

# Run health checks
check_health() {
    log "INFO" "Running health checks on CTI infrastructure components..."
    
    # Check if containers are running
    log "INFO" "Checking container status..."
    if docker-compose ps | grep -q "Exit"; then
        log "WARNING" "Some containers are not running:"
        docker-compose ps | grep "Exit"
    else
        log "SUCCESS" "All containers are running"
    fi
    
    # Check component endpoints
    log "INFO" "Checking component endpoints..."
    
    # Check GRR
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8001 | grep -q "200\|302"; then
        log "SUCCESS" "GRR endpoint is accessible"
    else
        log "WARNING" "GRR endpoint is not responding"
    fi
    
    # Check TheHive
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9000 | grep -q "200\|302"; then
        log "SUCCESS" "TheHive endpoint is accessible"
    else
        log "WARNING" "TheHive endpoint is not responding"
    fi
    
    # Check Cortex
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9001 | grep -q "200\|302"; then
        log "SUCCESS" "Cortex endpoint is accessible"
    else
        log "WARNING" "Cortex endpoint is not responding"
    fi
    
    # Check MISP
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302"; then
        log "SUCCESS" "MISP endpoint is accessible"
    else
        log "WARNING" "MISP endpoint is not responding"
    fi
    
    # Check Portainer
    if curl -s -k -o /dev/null -w "%{http_code}" https://localhost:9443 | grep -q "200\|302"; then
        log "SUCCESS" "Portainer endpoint is accessible"
    else
        log "WARNING" "Portainer endpoint is not responding"
    fi
    
    # Check disk space
    log "INFO" "Checking disk space..."
    disk_usage=$(df -h | grep / | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        log "WARNING" "Disk space is critically low: ${disk_usage}%"
    elif [ "$disk_usage" -gt 75 ]; then
        log "WARNING" "Disk space is running low: ${disk_usage}%"
    else
        log "SUCCESS" "Disk space is adequate: ${disk_usage}%"
    fi
    
    # Check memory usage
    log "INFO" "Checking memory usage..."
    memory_free=$(free -m | grep "Mem:" | awk '{print $4}')
    if [ "$memory_free" -lt 1024 ]; then
        log "WARNING" "Available memory is low: ${memory_free}MB"
    else
        log "SUCCESS" "Available memory is adequate: ${memory_free}MB"
    fi
    
    # Check Docker resource usage
    log "INFO" "Checking Docker resource usage..."
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    
    log "INFO" "Health checks completed"
}

# Create a backup
create_backup() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/cti_backup_$timestamp.tar.gz"
    
    log "INFO" "Creating backup of CTI infrastructure data..."
    
    # Create a directory for temporary files
    local temp_dir=$(mktemp -d)
    
    # Export container configurations
    log "INFO" "Exporting container configurations..."
    docker-compose config > "$temp_dir/docker-compose-export.yml"
    
    # Create a directory for volume data
    mkdir -p "$temp_dir/volumes"
    
    # List all volumes used by the infrastructure
    log "INFO" "Identifying volumes to backup..."
    volumes=$(docker volume ls --filter "name=cti" -q)
    
    # Backup each volume
    log "INFO" "Backing up volumes..."
    for volume in $volumes; do
        log "INFO" "Backing up volume: $volume"
        
        # Create a temporary container to access the volume data
        docker run --rm -v $volume:/source -v $temp_dir/volumes:/backup alpine \
            sh -c "cd /source && tar cf /backup/$volume.tar ."
    done
    
    # Package everything into a single archive
    log "INFO" "Creating final backup archive..."
    tar -czf "$backup_file" -C "$temp_dir" .
    
    # Clean up
    rm -rf "$temp_dir"
    
    log "SUCCESS" "Backup created: $backup_file"
    
    # Create a manifest file with metadata
    cat > "$backup_file.manifest" << EOF
Backup Date: $(date)
Components: GRR, TheHive, Cortex, MISP, Portainer
Docker Compose Version: $(docker-compose version --short)
Docker Version: $(docker --version | awk '{print $3}' | sed 's/,//')
Host: $(hostname)
Size: $(du -h "$backup_file" | awk '{print $1}')
EOF

    log "INFO" "Backup manifest created: $backup_file.manifest"
}

# Restore from a backup
restore_backup() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        log "ERROR" "No backup file specified"
        echo "Available backups:"
        ls -lh "$BACKUP_DIR" | grep -E '\.tar\.gz$'
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        # Check if it might be in the backup directory
        if [ -f "$BACKUP_DIR/$backup_file" ]; then
            backup_file="$BACKUP_DIR/$backup_file"
        else
            log "ERROR" "Backup file not found: $backup_file"
            exit 1
        fi
    fi
    
    log "WARNING" "Restoring will stop all running containers and replace current data"
    read -p "Are you sure you want to continue? (y/N) " confirm
    if [[ $confirm != [yY] ]]; then
        log "INFO" "Restore cancelled"
        exit 0
    fi
    
    # Stop all containers
    log "INFO" "Stopping all containers..."
    docker-compose down
    
    # Create a temporary directory for extraction
    local temp_dir=$(mktemp -d)
    
    # Extract the backup
    log "INFO" "Extracting backup archive..."
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # Restore docker-compose configuration
    log "INFO" "Restoring container configurations..."
    if [ -f "$temp_dir/docker-compose-export.yml" ]; then
        cp "$temp_dir/docker-compose-export.yml" docker-compose.yml
    fi
    
    # Restore each volume
    log "INFO" "Restoring volumes..."
    for tar_file in "$temp_dir/volumes"/*.tar; do
        if [ -f "$tar_file" ]; then
            volume_name=$(basename "$tar_file" .tar)
            log "INFO" "Restoring volume: $volume_name"
            
            # Ensure volume exists
            docker volume create "$volume_name" &> /dev/null || true
            
            # Restore data to volume
            docker run --rm -v $volume_name:/dest -v "$temp_dir/volumes:/backup" alpine \
                sh -c "cd /dest && tar xf /backup/$(basename $tar_file) ."
        fi
    done
    
    # Clean up
    rm -rf "$temp_dir"
    
    # Restart containers
    log "INFO" "Starting containers with restored data..."
    docker-compose up -d
    
    log "SUCCESS" "Restore completed from: $backup_file"
}

# Update all components
update_components() {
    log "INFO" "Updating CTI infrastructure components..."
    
    # Pull latest images
    log "INFO" "Pulling latest images..."
    docker-compose pull
    
    # Restart services with new images
    log "INFO" "Restarting with updated images..."
    docker-compose up -d
    
    log "SUCCESS" "All components updated to latest versions"
}

# Show configuration
show_config() {
    log "INFO" "Current CTI infrastructure configuration:"
    
    if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE"
    else
        log "WARNING" "Configuration file not found: $CONFIG_FILE"
        log "INFO" "Using default configuration"
    fi
    
    # Show docker-compose configuration
    log "INFO" "Docker Compose Configuration:"
    docker-compose config
}

# Setup integration between components
setup_integration() {
    log "INFO" "Setting up integrations between CTI components..."
    
    # TheHive - Cortex Integration
    log "INFO" "Setting up TheHive-Cortex integration..."
    
    # Get Cortex API key
    read -p "Enter Cortex API Key: " cortex_api_key
    
    if [ -z "$cortex_api_key" ]; then
        log "ERROR" "No API key provided. Integration setup aborted."
        exit 1
    fi
    
    # Update docker-compose file with the API key
    if [ -f "docker-compose.yml" ]; then
        # Use sed to replace the API key placeholder
        sed -i "s/CORTEX_API_KEY_HERE/$cortex_api_key/" docker-compose.yml
        log "SUCCESS" "Updated TheHive configuration with Cortex API key"
        
        # Restart TheHive to apply changes
        log "INFO" "Restarting TheHive to apply changes..."
        docker-compose restart thehive
    else
        log "ERROR" "docker-compose.yml file not found"
        exit 1
    fi
    
    # TheHive - MISP Integration
    log "INFO" "Setting up TheHive-MISP integration..."
    log "INFO" "Please complete the following steps manually:"
    log "INFO" "1. Log in to MISP at http://localhost:8080"
    log "INFO" "2. Go to Administration > List Auth Keys"
    log "INFO" "3. Add a new authentication key for TheHive"
    log "INFO" "4. Log in to TheHive at http://localhost:9000"
    log "INFO" "5. Go to Admin > Configuration > MISP"
    log "INFO" "6. Add a new MISP connection with the URL and API key"
    
    log "SUCCESS" "Integration setup instructions provided"
}

# Add a new user
add_user() {
    log "INFO" "Adding a new user to CTI infrastructure..."
    
    # Prompt for user details
    read -p "Username: " username
    read -p "Email: " email
    read -p "Select component (thehive, cortex, misp, grr, all): " component
    
    if [ -z "$username" ] || [ -z "$email" ]; then
        log "ERROR" "Username and email are required"
        exit 1
    fi
    
    case $component in
        thehive)
            log "INFO" "Please complete the following steps manually:"
            log "INFO" "1. Log in to TheHive at http://localhost:9000"
            log "INFO" "2. Go to Admin > Users"
            log "INFO" "3. Add a new user with the following details:"
            log "INFO" "   - Login: $username"
            log "INFO" "   - Email: $email"
            ;;
        cortex)
            log "INFO" "Please complete the following steps manually:"
            log "INFO" "1. Log in to Cortex at http://localhost:9001"
            log "INFO" "2. Go to Organizations > [YourOrg] > Users"
            log "INFO" "3. Add a new user with the following details:"
            log "INFO" "   - Login: $username"
            log "INFO" "   - Email: $email"
            ;;
        misp)
            log "INFO" "Please complete the following steps manually:"
            log "INFO" "1. Log in to MISP at http://localhost:8080"
            log "INFO" "2. Go to Administration > Add User"
            log "INFO" "3. Add a new user with the following details:"
            log "INFO" "   - Email: $email"
            ;;
        grr)
            log "INFO" "Please complete the following steps manually:"
            log "INFO" "1. Log in to GRR at http://localhost:8001"
            log "INFO" "2. Go to User Management"
            log "INFO" "3. Add a new user with the following details:"
            log "INFO" "   - Username: $username"
            log "INFO" "   - Email: $email"
            ;;
        all)
            log "INFO" "Please add the user to all components following the instructions for each component."
            ;;
        *)
            log "ERROR" "Invalid component: $component"
            log "INFO" "Valid components: thehive, cortex, misp, grr, all"
            exit 1
            ;;
    esac
    
    log "SUCCESS" "User addition instructions provided"
}

# Main command processing
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Check Docker installation
check_docker

# Process command
command=$1
shift

case $command in
    status)
        show_status
        ;;
    start)
        start_components
        ;;
    stop)
        stop_components
        ;;
    restart)
        restart_components
        ;;
    backup)
        create_backup
        ;;
    restore)
        restore_backup "$1"
        ;;
    update)
        update_components
        ;;
    logs)
        show_logs "$1"
        ;;
    health)
        check_health
        ;;
    config)
        show_config
        ;;
    setup-integration)
        setup_integration
        ;;
    add-user)
        add_user
        ;;
    help)
        show_help
        ;;
    *)
        echo "Unknown command: $command"
        show_help
        exit 1
        ;;
esac

exit 0
