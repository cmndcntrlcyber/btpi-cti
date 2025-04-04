#!/bin/bash
#
# CTI Platform Health Check Script
# This script checks the health of all CTI platform components
#

set -e

# Configuration
DATE_FORMAT=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="/var/log/cti-health-${DATE_FORMAT}.log"
EMAIL_ALERTS=false
EMAIL_RECIPIENT="admin@example.com"
SLACK_ALERTS=false
SLACK_WEBHOOK=""
VERBOSE=false
CHECK_DISK=true
CHECK_MEMORY=true
CHECK_CPU=true
CHECK_CONTAINERS=true
CHECK_SERVICES=true
DISK_THRESHOLD=90
MEMORY_THRESHOLD=90
CPU_THRESHOLD=90

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Start logging
if [ "$VERBOSE" = true ]; then
    exec > >(tee -a "${LOG_FILE}") 2>&1
else
    exec > "${LOG_FILE}" 2>&1
fi

echo "====================================================="
echo "  CTI Platform Health Check - $(date)"
echo "====================================================="
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    
    if [ "$status" = "OK" ]; then
        echo -e "[${GREEN}OK${NC}] $message"
    elif [ "$status" = "WARNING" ]; then
        echo -e "[${YELLOW}WARNING${NC}] $message"
    elif [ "$status" = "ERROR" ]; then
        echo -e "[${RED}ERROR${NC}] $message"
    else
        echo -e "[$status] $message"
    fi
}

# Function to send alerts
send_alert() {
    local subject=$1
    local message=$2
    
    if [ "$EMAIL_ALERTS" = true ]; then
        echo "$message" | mail -s "$subject" "$EMAIL_RECIPIENT"
    fi
    
    if [ "$SLACK_ALERTS" = true ] && [ -n "$SLACK_WEBHOOK" ]; then
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$subject\n$message\"}" \
            "$SLACK_WEBHOOK"
    fi
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_status "ERROR" "Docker is not running"
    send_alert "CTI Health Alert: Docker not running" "Docker service is not running on $(hostname)"
    exit 1
fi

# Check disk usage
if [ "$CHECK_DISK" = true ]; then
    echo "Checking disk usage..."
    
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
        print_status "ERROR" "Disk usage is at ${DISK_USAGE}% (threshold: ${DISK_THRESHOLD}%)"
        send_alert "CTI Health Alert: High Disk Usage" "Disk usage on $(hostname) is at ${DISK_USAGE}%"
    else
        print_status "OK" "Disk usage is at ${DISK_USAGE}% (threshold: ${DISK_THRESHOLD}%)"
    fi
    
    # Check Docker disk usage
    DOCKER_DISK=$(docker system df | grep "Images" | awk '{print $5}' | sed 's/%//')
    
    if [ -n "$DOCKER_DISK" ] && [ "$DOCKER_DISK" -gt "$DISK_THRESHOLD" ]; then
        print_status "WARNING" "Docker disk usage is at ${DOCKER_DISK}% (threshold: ${DISK_THRESHOLD}%)"
        send_alert "CTI Health Alert: High Docker Disk Usage" "Docker disk usage on $(hostname) is at ${DOCKER_DISK}%"
    else
        print_status "OK" "Docker disk usage is at ${DOCKER_DISK}% (threshold: ${DISK_THRESHOLD}%)"
    fi
fi

# Check memory usage
if [ "$CHECK_MEMORY" = true ]; then
    echo "Checking memory usage..."
    
    MEMORY_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
    
    if [ "$MEMORY_USAGE" -gt "$MEMORY_THRESHOLD" ]; then
        print_status "ERROR" "Memory usage is at ${MEMORY_USAGE}% (threshold: ${MEMORY_THRESHOLD}%)"
        send_alert "CTI Health Alert: High Memory Usage" "Memory usage on $(hostname) is at ${MEMORY_USAGE}%"
    else
        print_status "OK" "Memory usage is at ${MEMORY_USAGE}% (threshold: ${MEMORY_THRESHOLD}%)"
    fi
fi

# Check CPU usage
if [ "$CHECK_CPU" = true ]; then
    echo "Checking CPU usage..."
    
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    CPU_USAGE=${CPU_USAGE%.*}
    
    if [ "$CPU_USAGE" -gt "$CPU_THRESHOLD" ]; then
        print_status "ERROR" "CPU usage is at ${CPU_USAGE}% (threshold: ${CPU_THRESHOLD}%)"
        send_alert "CTI Health Alert: High CPU Usage" "CPU usage on $(hostname) is at ${CPU_USAGE}%"
    else
        print_status "OK" "CPU usage is at ${CPU_USAGE}% (threshold: ${CPU_THRESHOLD}%)"
    fi
fi

# Check container status
if [ "$CHECK_CONTAINERS" = true ]; then
    echo "Checking container status..."
    
    # Get all CTI containers
    CONTAINERS=$(docker ps -a --filter "name=cti" --format "{{.Names}}")
    
    if [ -z "$CONTAINERS" ]; then
        print_status "WARNING" "No CTI containers found"
    else
        for container in $CONTAINERS; do
            STATUS=$(docker inspect --format='{{.State.Status}}' "$container")
            
            if [ "$STATUS" = "running" ]; then
                HEALTH=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}' "$container")
                
                if [ "$HEALTH" = "healthy" ] || [ "$HEALTH" = "N/A" ]; then
                    print_status "OK" "Container $container is running (health: $HEALTH)"
                else
                    print_status "ERROR" "Container $container is running but health check failed (status: $HEALTH)"
                    send_alert "CTI Health Alert: Container Health Check Failed" "Container $container on $(hostname) is unhealthy"
                fi
            else
                print_status "ERROR" "Container $container is not running (status: $STATUS)"
                send_alert "CTI Health Alert: Container Not Running" "Container $container on $(hostname) is not running"
            fi
        done
    fi
fi

# Check service status
if [ "$CHECK_SERVICES" = true ]; then
    echo "Checking service status..."
    
    # Check TheHive
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9000 | grep -q "200\|302"; then
        print_status "OK" "TheHive service is responding"
    else
        print_status "ERROR" "TheHive service is not responding"
        send_alert "CTI Health Alert: TheHive Service Down" "TheHive service on $(hostname) is not responding"
    fi
    
    # Check Cortex
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9001 | grep -q "200\|302"; then
        print_status "OK" "Cortex service is responding"
    else
        print_status "ERROR" "Cortex service is not responding"
        send_alert "CTI Health Alert: Cortex Service Down" "Cortex service on $(hostname) is not responding"
    fi
    
    # Check MISP
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302"; then
        print_status "OK" "MISP service is responding"
    else
        print_status "ERROR" "MISP service is not responding"
        send_alert "CTI Health Alert: MISP Service Down" "MISP service on $(hostname) is not responding"
    fi
    
    # Check GRR
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 | grep -q "200\|302"; then
        print_status "OK" "GRR service is responding"
    else
        print_status "ERROR" "GRR service is not responding"
        send_alert "CTI Health Alert: GRR Service Down" "GRR service on $(hostname) is not responding"
    fi
    
    # Check Portainer
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9000 | grep -q "200\|302"; then
        print_status "OK" "Portainer service is responding"
    else
        print_status "ERROR" "Portainer service is not responding"
        send_alert "CTI Health Alert: Portainer Service Down" "Portainer service on $(hostname) is not responding"
    fi
fi

echo ""
echo "Health check completed. Log saved to: ${LOG_FILE}"
echo ""

exit 0
