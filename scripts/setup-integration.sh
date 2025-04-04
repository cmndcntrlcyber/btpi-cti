#!/bin/bash
#
# CTI Platform Integration Setup Script
# This script sets up integrations between different CTI platform components
#

set -e

# Configuration
LOG_FILE="/var/log/cti-integration-setup.log"
CONFIG_DIR="$(pwd)/configs"

# Start logging
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "====================================================="
echo "  CTI Platform Integration Setup - $(date)"
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

# Function to check if a service is running
check_service() {
    local service=$1
    local port=$2
    
    echo "Checking if $service is running on port $port..."
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" | grep -q "200\|302"; then
        echo "  - $service is running"
        return 0
    else
        echo "  - $service is not running"
        return 1
    fi
}

# Function to get API key
get_api_key() {
    local service=$1
    local username=$2
    local password=$3
    local api_url=$4
    
    echo "Getting API key for $service..."
    
    # This is a placeholder - in a real implementation you would use the service's API
    # to authenticate and get an API key
    echo "Note: This is a placeholder for the actual API key retrieval."
    echo "In a production environment, you would need to implement the API calls to:"
    echo "1. Authenticate with the $service service"
    echo "2. Retrieve or generate an API key"
    
    # For demonstration purposes, we'll generate a random API key
    local api_key=$(openssl rand -hex 24)
    echo "Generated API key for $service: $api_key"
    
    echo "$api_key"
}

# Setup TheHive and Cortex integration
setup_thehive_cortex() {
    echo "Setting up TheHive and Cortex integration..."
    
    # Check if TheHive and Cortex are running
    if ! check_service "TheHive" 9000 || ! check_service "Cortex" 9001; then
        echo "Error: TheHive or Cortex is not running"
        echo "Please make sure both services are running before setting up the integration"
        return 1
    fi
    
    # Get Cortex API key
    CORTEX_API_KEY=$(get_api_key "Cortex" "admin" "password" "http://localhost:9001/api/user")
    
    # Update TheHive configuration
    echo "Updating TheHive configuration..."
    
    # Create Cortex configuration file
    mkdir -p "$CONFIG_DIR/thehive"
    cat > "$CONFIG_DIR/thehive/application.conf" <<EOF
# TheHive configuration file

play.http.secret.key="$(openssl rand -hex 24)"

# Cortex integration
play.modules.enabled += org.thehive.cortex.connector.CortexConnector

cortex {
  servers = [
    {
      name = "Cortex"
      url = "http://cortex:9001"
      auth {
        type = "bearer"
        key = "$CORTEX_API_KEY"
      }
    }
  ]
}
EOF
    
    # Restart TheHive container
    echo "Restarting TheHive container..."
    docker-compose restart thehive
    
    echo "TheHive and Cortex integration setup completed"
}

# Setup MISP and TheHive integration
setup_misp_thehive() {
    echo "Setting up MISP and TheHive integration..."
    
    # Check if MISP and TheHive are running
    if ! check_service "MISP" 8080 || ! check_service "TheHive" 9000; then
        echo "Error: MISP or TheHive is not running"
        echo "Please make sure both services are running before setting up the integration"
        return 1
    fi
    
    # Get MISP API key
    MISP_API_KEY=$(get_api_key "MISP" "admin@admin.test" "admin" "http://localhost:8080/users/view/me")
    
    # Get TheHive API key
    THEHIVE_API_KEY=$(get_api_key "TheHive" "admin" "password" "http://localhost:9000/api/user")
    
    # Update MISP configuration for TheHive integration
    echo "Updating MISP configuration..."
    
    # Create MISP configuration file
    mkdir -p "$CONFIG_DIR/misp"
    cat > "$CONFIG_DIR/misp/config.php" <<EOF
<?php
// MISP configuration file

// TheHive integration
\$config['Plugin.Cortex_thehive_misp_enabled'] = true;
\$config['Plugin.Cortex_thehive_misp_url'] = 'http://thehive:9000';
\$config['Plugin.Cortex_thehive_misp_key'] = '$THEHIVE_API_KEY';
?>
EOF
    
    # Update TheHive configuration for MISP integration
    echo "Updating TheHive configuration..."
    
    # Create or update TheHive configuration file
    mkdir -p "$CONFIG_DIR/thehive"
    cat >> "$CONFIG_DIR/thehive/application.conf" <<EOF

# MISP integration
play.modules.enabled += org.thehive.misp.connector.MispConnector

misp {
  interval = 1 hour
  servers = [
    {
      name = "MISP"
      url = "http://misp:8080"
      auth {
        type = "key"
        key = "$MISP_API_KEY"
      }
      wsConfig.ssl.loose.acceptAnyCertificate = true
    }
  ]
}
EOF
    
    # Restart MISP and TheHive containers
    echo "Restarting MISP and TheHive containers..."
    docker-compose restart misp thehive
    
    echo "MISP and TheHive integration setup completed"
}

# Setup GRR and TheHive integration
setup_grr_thehive() {
    echo "Setting up GRR and TheHive integration..."
    
    # Check if GRR and TheHive are running
    if ! check_service "GRR" 8000 || ! check_service "TheHive" 9000; then
        echo "Error: GRR or TheHive is not running"
        echo "Please make sure both services are running before setting up the integration"
        return 1
    fi
    
    # Get TheHive API key
    THEHIVE_API_KEY=$(get_api_key "TheHive" "admin" "password" "http://localhost:9000/api/user")
    
    # Create GRR to TheHive integration script
    echo "Creating GRR to TheHive integration script..."
    
    mkdir -p "$(pwd)/integrations/grr-thehive"
    cat > "$(pwd)/integrations/grr-thehive/grr2thehive.py" <<EOF
#!/usr/bin/env python3
#
# GRR to TheHive Integration Script
# This script forwards GRR findings to TheHive as alerts
#

import argparse
import json
import requests
import sys
import os
from datetime import datetime

# Configuration
THEHIVE_URL = "http://localhost:9000"
THEHIVE_API_KEY = "$THEHIVE_API_KEY"
GRR_URL = "http://localhost:8000"

def create_alert(title, description, artifacts):
    """Create an alert in TheHive"""
    
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {THEHIVE_API_KEY}'
    }
    
    alert_data = {
        "title": title,
        "description": description,
        "type": "grr",
        "source": "GRR",
        "sourceRef": f"grr-{datetime.now().strftime('%Y%m%d%H%M%S')}",
        "artifacts": artifacts
    }
    
    try:
        response = requests.post(
            f"{THEHIVE_URL}/api/alert", 
            headers=headers,
            json=alert_data
        )
        
        if response.status_code == 201:
            print(f"Alert created successfully: {title}")
            return True
        else:
            print(f"Failed to create alert: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"Error creating alert: {str(e)}")
        return False

def main():
    parser = argparse.ArgumentParser(description='GRR to TheHive Integration')
    parser.add_argument('--input', '-i', help='Input JSON file with GRR findings')
    args = parser.parse_args()
    
    if args.input:
        try:
            with open(args.input, 'r') as f:
                data = json.load(f)
        except Exception as e:
            print(f"Error reading input file: {str(e)}")
            sys.exit(1)
    else:
        print("No input file specified. Use --input to specify a JSON file with GRR findings.")
        sys.exit(1)
    
    # Process GRR findings and create TheHive alerts
    for finding in data.get('findings', []):
        title = finding.get('title', 'GRR Finding')
        description = finding.get('description', '')
        
        # Convert GRR artifacts to TheHive artifacts
        artifacts = []
        for item in finding.get('items', []):
            artifact = {
                "dataType": item.get('type', 'other'),
                "data": item.get('value', ''),
                "message": item.get('description', '')
            }
            artifacts.append(artifact)
        
        # Create alert in TheHive
        create_alert(title, description, artifacts)

if __name__ == "__main__":
    main()
EOF
    
    # Make the script executable
    chmod +x "$(pwd)/integrations/grr-thehive/grr2thehive.py"
    
    echo "GRR and TheHive integration setup completed"
    echo "You can use the integration script as follows:"
    echo "  python3 integrations/grr-thehive/grr2thehive.py --input grr_findings.json"
}

# Main menu
show_menu() {
    echo "CTI Platform Integration Setup"
    echo ""
    echo "Available integrations:"
    echo "  1) TheHive and Cortex"
    echo "  2) MISP and TheHive"
    echo "  3) GRR and TheHive"
    echo "  4) Setup all integrations"
    echo "  5) Exit"
    echo ""
    read -p "Select an option (1-5): " choice
    
    case $choice in
        1)
            setup_thehive_cortex
            ;;
        2)
            setup_misp_thehive
            ;;
        3)
            setup_grr_thehive
            ;;
        4)
            setup_thehive_cortex
            setup_misp_thehive
            setup_grr_thehive
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    show_menu
}

# Start the menu
show_menu

exit 0
