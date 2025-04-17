#!/bin/bash
#
# BTPI-CTI Management Script
# This script provides a unified management interface for the BTPI-CTI platform
#

set -e

# Configuration
CTI_BASE_DIR="/opt/btpi-cti"
CTI_VERSION="1.0.0"
CTI_CONFIG_FILE="${CTI_BASE_DIR}/config.env"
CURRENT_DIR=$(pwd)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display banner
display_banner() {
    echo -e "${BLUE}"
    echo "==========================================================="
    echo "       BTPI-CTI - Threat Intelligence Platform v${CTI_VERSION}"
    echo "==========================================================="
    echo -e "${NC}\n"
}

# Display help information
display_help() {
    display_banner
    echo -e "Usage: ${GREEN}./cti-manage.sh [COMMAND]${NC}\n"
    echo "Commands:"
    echo -e "  ${GREEN}install${NC}              Complete installation of the CTI platform"
    echo -e "  ${GREEN}start${NC}                Start all CTI services"
    echo -e "  ${GREEN}stop${NC}                 Stop all CTI services"
    echo -e "  ${GREEN}restart${NC}              Restart all CTI services"
    echo -e "  ${GREEN}status${NC}               Display the status of all CTI services"
    echo -e "  ${GREEN}logs [service]${NC}       Display logs for a specific service"
    echo -e "  ${GREEN}update${NC}               Update all components to latest versions"
    echo -e "  ${GREEN}backup${NC}               Backup all CTI data"
    echo -e "  ${GREEN}restore [backup_file]${NC} Restore from a previous backup"
    echo -e "  ${GREEN}fix${NC}                  Run diagnostics and fix common issues"
    echo -e "  ${GREEN}kasm${NC}                 Set up Kasm Workspaces integration"
    echo -e "  ${GREEN}attack${NC}               Set up MITRE ATT&CK Workbench"
    echo -e "  ${GREEN}credentials${NC}          Display access credentials for services"
    echo -e "  ${GREEN}ports${NC}                Display port assignments for services"
    echo -e ""
    echo -e "Examples:"
    echo -e "  ${GREEN}./cti-manage.sh install${NC}       # Full installation"
    echo -e "  ${GREEN}./cti-manage.sh logs thehive${NC}  # View TheHive logs"
    echo -e ""
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        exit 1
    fi
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker not found. Installing Docker...${NC}"
        apt-get update
        apt-get install -y ca-certificates curl gnupg
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin curl git
        
        systemctl enable docker
        systemctl start docker
        
        echo -e "${GREEN}Docker installed successfully.${NC}"
    else
        echo -e "${GREEN}Docker is already installed.${NC}"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Installing Docker Compose plugin...${NC}"
        apt-get install -y docker-compose-plugin
        echo -e "${GREEN}Docker Compose plugin installed.${NC}"
    fi
}

# Run the fix script to repair any issues
run_fix_script() {
    echo -e "${BLUE}Running diagnostics and fixing common issues...${NC}"
    
    # Run the comprehensive fix script
    bash "${CURRENT_DIR}/scripts/fix-stack-issues.sh"
    
    echo -e "${GREEN}Fix operation completed.${NC}"
}

# Install the complete CTI platform
install_cti() {
    display_banner
    check_root
    check_docker
    
    echo -e "${BLUE}Starting installation of BTPI-CTI platform...${NC}"
    
    # Create needed directories
    mkdir -p "${CTI_BASE_DIR}/configs/nginx"
    mkdir -p "${CTI_BASE_DIR}/grr_configs/server/textservices"
    mkdir -p "${CTI_BASE_DIR}/grr_configs/healthchecks"
    mkdir -p "${CTI_BASE_DIR}/integrations"
    mkdir -p "${CTI_BASE_DIR}/secrets"
    
    # Run the fix script to set up all configurations
    run_fix_script
    
    echo -e "${GREEN}BTPI-CTI platform installation completed.${NC}"
    echo -e "You can now access the platform services at their respective ports."
    echo -e "Run '${YELLOW}./cti-manage.sh credentials${NC}' to view access details."
    echo -e "Run '${YELLOW}./cti-manage.sh ports${NC}' to view port assignments."
}

# Start all CTI services
start_cti() {
    display_banner
    check_root
    
    echo -e "${BLUE}Starting all CTI services...${NC}"
    docker-compose up -d
    
    echo -e "${GREEN}All services started.${NC}"
}

# Stop all CTI services
stop_cti() {
    display_banner
    check_root
    
    echo -e "${BLUE}Stopping all CTI services...${NC}"
    docker-compose down
    
    echo -e "${GREEN}All services stopped.${NC}"
}

# Restart all CTI services
restart_cti() {
    display_banner
    check_root
    
    echo -e "${BLUE}Restarting all CTI services...${NC}"
    docker-compose restart
    
    echo -e "${GREEN}All services restarted.${NC}"
}

# Display the status of all CTI services
status_cti() {
    display_banner
    
    echo -e "${BLUE}Current status of CTI services:${NC}"
    docker-compose ps
}

# Display logs for a specific service
logs_cti() {
    display_banner
    
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Please specify a service name. Available services:${NC}"
        docker-compose ps --services
        exit 1
    fi
    
    echo -e "${BLUE}Displaying logs for ${YELLOW}$1${BLUE}:${NC}"
    docker-compose logs --tail=100 -f "$1"
}

# Update all components to the latest versions
update_cti() {
    display_banner
    check_root
    
    echo -e "${BLUE}Updating all CTI components...${NC}"
    
    # Pull latest docker images
    docker-compose pull
    
    # Restart services with new images
    docker-compose up -d
    
    echo -e "${GREEN}All services updated to latest versions.${NC}"
}

# Backup all CTI data
backup_cti() {
    display_banner
    check_root
    
    echo -e "${BLUE}Starting backup of all CTI data...${NC}"
    bash "${CURRENT_DIR}/scripts/backup.sh"
    
    echo -e "${GREEN}Backup completed.${NC}"
}

# Restore from a previous backup
restore_cti() {
    display_banner
    check_root
    
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Please specify a backup file to restore from.${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Restoring from backup $1...${NC}"
    bash "${CURRENT_DIR}/scripts/restore.sh" "$1"
    
    echo -e "${GREEN}Restore completed.${NC}"
}

# Set up Kasm Workspaces integration
setup_kasm() {
    display_banner
    check_root
    
    echo -e "${BLUE}Setting up Kasm Workspaces integration...${NC}"
    bash "${CURRENT_DIR}/scripts/kasm-integration.sh"
    
    echo -e "${GREEN}Kasm Workspaces integration completed.${NC}"
}

# Set up MITRE ATT&CK Workbench
setup_attack() {
    display_banner
    check_root
    
    echo -e "${BLUE}Setting up MITRE ATT&CK Workbench...${NC}"
    bash "${CURRENT_DIR}/scripts/setup-attack-workbench.sh"
    
    echo -e "${GREEN}MITRE ATT&CK Workbench setup completed.${NC}"
}

# Display access credentials for all services
show_credentials() {
    display_banner
    
    echo -e "${BLUE}Access credentials for CTI services:${NC}\n"
    
    echo -e "${YELLOW}TheHive:${NC}"
    echo -e "  URL: http://localhost:9000"
    echo -e "  Default Username: admin@thehive.local"
    echo -e "  Default Password: secret"
    echo -e ""
    
    echo -e "${YELLOW}Cortex:${NC}"
    echo -e "  URL: http://localhost:9001"
    echo -e "  Default Username: admin@cortex.local"
    echo -e "  Default Password: secret"
    echo -e ""
    
    echo -e "${YELLOW}MISP:${NC}"
    echo -e "  URL: http://localhost:8080"
    echo -e "  Default Username: admin@admin.test"
    echo -e "  Default Password: admin"
    echo -e ""
    
    echo -e "${YELLOW}GRR Rapid Response:${NC}"
    echo -e "  URL: http://localhost:8001"
    echo -e "  Default Username: admin"
    echo -e "  Default Password: Set during first login"
    echo -e ""
    
    echo -e "${YELLOW}Portainer:${NC}"
    echo -e "  URL: https://localhost:9443"
    echo -e "  Default Username: admin"
    echo -e "  Default Password: Set during first login"
    echo -e ""
    
    echo -e "${YELLOW}ATT&CK Workbench:${NC}"
    echo -e "  URL: http://localhost:9080"
    echo -e ""
    
    echo -e "${YELLOW}Note:${NC} If Kasm Workspaces integration is enabled, you can access all services securely via Kasm."
}

# Display port assignments for all services
show_ports() {
    display_banner
    
    echo -e "${BLUE}Port assignments for CTI services:${NC}\n"
    
    echo -e "${YELLOW}TheHive:${NC} 9000"
    echo -e "${YELLOW}Cortex:${NC} 9001"
    echo -e "${YELLOW}MISP:${NC} 8080"
    echo -e "${YELLOW}GRR Rapid Response:${NC} 8001"
    echo -e "${YELLOW}Portainer:${NC} 9000 (HTTP), 9010 (Original UI), 9443 (HTTPS)"
    echo -e "${YELLOW}Attack Workbench:${NC} 9080"
    echo -e "${YELLOW}Attack Flow:${NC} 8002"
    echo -e "${YELLOW}Elasticsearch:${NC} 9200, 9300"
    echo -e "${YELLOW}Cassandra:${NC} 9042"
    echo -e "${YELLOW}MinIO:${NC} 10000 (API), 9090 (Console)"
    echo -e "${YELLOW}Integration API:${NC} 8888"
    echo -e "${YELLOW}MongoDB (Attack Workbench):${NC} 27018"
}

# Parse command line arguments
case "$1" in
    install)
        install_cti
        ;;
    start)
        start_cti
        ;;
    stop)
        stop_cti
        ;;
    restart)
        restart_cti
        ;;
    status)
        status_cti
        ;;
    logs)
        logs_cti "$2"
        ;;
    update)
        update_cti
        ;;
    backup)
        backup_cti
        ;;
    restore)
        restore_cti "$2"
        ;;
    fix)
        run_fix_script
        ;;
    kasm)
        setup_kasm
        ;;
    attack)
        setup_attack
        ;;
    credentials)
        show_credentials
        ;;
    ports)
        show_ports
        ;;
    *)
        display_help
        ;;
esac

exit 0
