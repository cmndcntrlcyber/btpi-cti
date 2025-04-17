#!/bin/bash
# Deploy script for Integration API service

set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}        Deploying Integration API Service            ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Check if running as root/sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script as root or with sudo privileges${NC}"
  exit 1
fi

# Navigate to script directory
cd "$(dirname "$0")"

# Ensure network exists
if ! docker network inspect cti-network > /dev/null 2>&1; then
    echo -e "${YELLOW}Required network 'cti-network' does not exist${NC}"
    echo -e "${YELLOW}Please run the create-network.sh script first${NC}"
    exit 1
fi

# Ensure integration directories exist
mkdir -p ../../integrations/{cortex-thehive,grr-thehive,misp-thehive}

# Create integration index page if it doesn't exist
if [ ! -f "../../integrations/index.html" ]; then
    echo "Creating integration index page..."
    cat > ../../integrations/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>BTPI-CTI Integration API</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 20px;
      color: #333;
      background-color: #f5f5f5;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
      background-color: #fff;
      padding: 20px;
      border-radius: 5px;
      box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
    }
    h1 {
      color: #2c3e50;
      border-bottom: 2px solid #3498db;
      padding-bottom: 10px;
    }
    ul {
      list-style-type: none;
      padding: 0;
    }
    li {
      margin-bottom: 15px;
      padding: 15px;
      background-color: #ecf0f1;
      border-radius: 5px;
      transition: all 0.3s ease;
    }
    li:hover {
      background-color: #e0e6ea;
      transform: translateY(-2px);
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    }
    a {
      color: #3498db;
      text-decoration: none;
      font-weight: bold;
      font-size: 18px;
    }
    a:hover {
      text-decoration: underline;
    }
    .description {
      margin-top: 5px;
      color: #555;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>BTPI-CTI Integration API</h1>
    <p>This is the integration API for BTPI-CTI components. Use the links below to access the specific integration guides and tools.</p>
    
    <ul>
      <li>
        <a href="/cortex-thehive/">Cortex-TheHive Integration</a>
        <div class="description">Integration between Cortex analyzers and TheHive for automated analysis of indicators.</div>
      </li>
      <li>
        <a href="/grr-thehive/">GRR-TheHive Integration</a>
        <div class="description">Integration between GRR Rapid Response and TheHive for incident response and endpoint investigation.</div>
      </li>
      <li>
        <a href="/misp-thehive/">MISP-TheHive Integration</a>
        <div class="description">Integration between MISP threat intelligence platform and TheHive for alert sharing and management.</div>
      </li>
    </ul>

    <div style="margin-top: 30px; font-size: 14px; color: #777; text-align: center;">
      BTPI-CTI Integration API &copy; 2025
    </div>
  </div>
</body>
</html>
EOF
    echo -e "${GREEN}✓${NC} Integration index page created"
fi

# Create placeholder for integration pages if they don't exist
for dir in ../../integrations/*-thehive/; do
    if [ -d "$dir" ] && [ ! -f "${dir}index.html" ]; then
        dir_name=$(basename "$dir")
        service_name="${dir_name%-*}"
        service_name_upper=$(echo $service_name | tr '[:lower:]' '[:upper:]')
        
        echo "Creating placeholder page for $service_name integration..."
        cat > "${dir}index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>${service_name_upper}-TheHive Integration</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 20px;
            color: #333;
        }
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .note {
            background-color: #e7f3fe;
            border-left: 4px solid #2196F3;
            padding: 10px;
            margin: 15px 0;
        }
        a {
            color: #3498db;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <h1>${service_name_upper}-TheHive Integration Guide</h1>
    
    <p>This page provides information about integrating ${service_name_upper} with TheHive platform.</p>

    <div class="note">
        <p><strong>Note:</strong> Documentation for this integration is under development.</p>
    </div>
    
    <p><a href="/">← Back to Integration Index</a></p>
</body>
</html>
EOF
        echo -e "${GREEN}✓${NC} Placeholder page for $service_name integration created"
    fi
done

# Stop and remove existing containers if they exist
if docker ps -a --format '{{.Names}}' | grep -q "^cti-integration-api$"; then
    echo "Stopping and removing existing integration-api container..."
    docker stop cti-integration-api >/dev/null 2>&1 || true
    docker rm cti-integration-api >/dev/null 2>&1 || true
fi

# Deploy the service
echo "Deploying Integration API service..."
docker-compose up -d

# Check if the container is running
if docker ps --format '{{.Names}}' | grep -q "^cti-integration-api$"; then
    echo -e "${GREEN}✓${NC} Integration API service deployed successfully!"
    echo -e "  - Integration API available at: http://<your-ip>:8888"
else
    echo -e "${RED}✗${NC} Integration API service failed to start. Check logs with 'docker logs cti-integration-api'"
    exit 1
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✓${NC} Integration API deployment complete."
echo -e "${BLUE}=====================================================${NC}"
