#!/bin/bash
#
# Kasm Workspaces Installation Script
# This script installs Kasm Workspaces for the CTI platform
#

set -e

# Configuration
KASM_VERSION="1.12.0"
KASM_RELEASE="1.12.0"
INSTALL_DIR="/opt/kasm"
ADMIN_USERNAME="admin@kasm.local"
ADMIN_PASSWORD=$(openssl rand -base64 12)
DEFAULT_ZONE="default"
DEFAULT_MEMORY="8192"
DEFAULT_CPUS="4"

# Display banner
echo "====================================================="
echo "  Kasm Workspaces Installation for CTI Platform"
echo "====================================================="
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Check system requirements
echo "Checking system requirements..."
CPU_CORES=$(nproc)
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')

if [ "$CPU_CORES" -lt 2 ]; then
    echo "Warning: Kasm recommends at least 2 CPU cores. You have $CPU_CORES cores."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

if [ "$TOTAL_MEM" -lt 4096 ]; then
    echo "Warning: Kasm recommends at least 4GB of RAM. You have $TOTAL_MEM MB."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
else
    echo "Docker is already installed."
fi

# Download Kasm Workspaces
echo "Downloading Kasm Workspaces ${KASM_VERSION}..."
wget -q "https://kasm-static-content.s3.amazonaws.com/kasm_release_${KASM_RELEASE}.tar.gz" -O /tmp/kasm.tar.gz
mkdir -p /tmp/kasm
tar -xf /tmp/kasm.tar.gz -C /tmp/kasm
cd /tmp/kasm

# Prepare installation configuration
echo "Preparing installation configuration..."
cat > /tmp/kasm/conf/app.json <<EOF
{
  "admin_user": "${ADMIN_USERNAME}",
  "admin_password": "${ADMIN_PASSWORD}",
  "zone": "${DEFAULT_ZONE}",
  "memory": "${DEFAULT_MEMORY}",
  "cpus": "${DEFAULT_CPUS}",
  "installation_type": "standard",
  "accept_eula": "Y"
}
EOF

# Run the installation
echo "Installing Kasm Workspaces..."
bash /tmp/kasm/install.sh

# Clean up
rm -rf /tmp/kasm /tmp/kasm.tar.gz

# Display installation information
echo ""
echo "====================================================="
echo "  Kasm Workspaces Installation Complete"
echo "====================================================="
echo ""
echo "Access your Kasm Workspaces at: https://$(hostname -I | awk '{print $1}')"
echo ""
echo "Admin credentials:"
echo "  Username: ${ADMIN_USERNAME}"
echo "  Password: ${ADMIN_PASSWORD}"
echo ""
echo "IMPORTANT: Save these credentials in a secure location!"
echo ""
echo "To add custom workspaces, use the kasm-image-builder.sh script."
echo ""
echo "====================================================="

# Save credentials to a file
echo "Admin credentials:" > /root/kasm_credentials.txt
echo "  Username: ${ADMIN_USERNAME}" >> /root/kasm_credentials.txt
echo "  Password: ${ADMIN_PASSWORD}" >> /root/kasm_credentials.txt
chmod 600 /root/kasm_credentials.txt

echo "Credentials saved to /root/kasm_credentials.txt"
echo ""

exit 0
