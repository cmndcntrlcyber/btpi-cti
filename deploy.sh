#!/bin/bash

# CTI Infrastructure Setup Script
echo "Starting CTI Infrastructure Setup..."

# Set working directory
WORKDIR=$(pwd)
CTI_DIR="$WORKDIR/cti-infrastructure"

# Create directories
mkdir -p "$CTI_DIR"
mkdir -p "$CTI_DIR/grr_configs/server/textservices"
mkdir -p "$CTI_DIR/grr_configs/client"
mkdir -p "$CTI_DIR/grr_configs/healthchecks"
mkdir -p "$CTI_DIR/configs"

# Copy docker-compose.yml
cp docker-compose.yml "$CTI_DIR/"

# Setup Docker if not already installed
setup_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        # Add Docker's official GPG key
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update

        # Install Docker packages
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Add current user to docker group to avoid sudo
        sudo usermod -aG docker $USER
        echo "Docker installed successfully. You may need to log out and back in for group changes to take effect."
    else
        echo "Docker already installed, skipping..."
    fi

    # Install docker-compose if not already installed
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose installed successfully."
    else
        echo "Docker Compose already installed, skipping..."
    fi
}

# Setup GRR configuration files
setup_grr() {
    echo "Setting up GRR configurations..."
    
    # Clone GRR repo if needed
    if [ ! -d "$CTI_DIR/grr" ]; then
        cd "$CTI_DIR"
        git clone https://github.com/google/grr
        cd grr
        # Generate certificates and keys
        ./docker_config_files/init_certs.sh
        # Copy generated configs
        cp -r docker_config_files/* "$CTI_DIR/grr_configs/"
        cd "$WORKDIR"
    fi

    # Create GRR healthcheck scripts
    cat > "$CTI_DIR/grr_configs/healthchecks/grr-admin-ui.sh" << 'EOF'
#!/bin/bash
if [ "$(ls -A /client_installers)" ]; then
  exit 0
else
  exit 1
fi
EOF

    cat > "$CTI_DIR/grr_configs/healthchecks/grr-client.sh" << 'EOF'
#!/bin/bash
if pgrep -f fleetspeak-client > /dev/null; then
  exit 0
else
  exit 1
fi
EOF

    # Make healthcheck scripts executable
    chmod +x "$CTI_DIR/grr_configs/healthchecks/grr-admin-ui.sh"
    chmod +x "$CTI_DIR/grr_configs/healthchecks/grr-client.sh"
}

# Setup MISP configuration
setup_misp() {
    echo "Setting up MISP configurations..."
    
    # No special configuration needed for MISP Docker deployment
    # as the container handles most of the setup automatically
}

# Setup TheHive and Cortex
setup_thehive() {
    echo "Setting up TheHive and Cortex configurations..."
    
    # Create a README for getting the Cortex API key
    cat > "$CTI_DIR/CORTEX_API_KEY_INSTRUCTIONS.md" << 'EOF'
# Obtaining Cortex API Key for TheHive Integration

Follow these steps after starting the containers:

1. Access Cortex at http://localhost:9001
2. Create an initial administrator account
3. Log in with your administrator credentials
4. Navigate to the "Organizations" section
5. Create a new organization (e.g., "CTI")
6. Navigate to the "Users" section within your organization
7. Create a new user with the "read, analyze, orgadmin" roles
8. Generate an API key for this user
9. Update the docker-compose.yml file, replacing "CORTEX_API_KEY_HERE" with your new API key
10. Restart TheHive container with: `docker-compose restart thehive`
EOF
}

# Setup Kasm Workspaces
setup_kasm() {
    echo "Setting up Kasm Workspaces..."
    
    # Create Kasm setup script
    cat > "$CTI_DIR/install_kasm.sh" << 'EOF'
#!/bin/bash

cd /tmp
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_1.15.0.06fdc8.tar.gz
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_service_images_amd64_1.15.0.06fdc8.tar.gz
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_workspace_images_amd64_1.15.0.06fdc8.tar.gz
tar -xf kasm_release_1.15.0.06fdc8.tar.gz
sudo bash kasm_release/install.sh --offline-workspaces /tmp/kasm_release_workspace_images_amd64_1.15.0.06fdc8.tar.gz --offline-service /tmp/kasm_release_service_images_amd64_1.15.0.06fdc8.tar.gz
EOF

    chmod +x "$CTI_DIR/install_kasm.sh"
}

# Create a master install script
create_master_script() {
    cat > "$CTI_DIR/deploy.sh" << 'EOF'
#!/bin/bash

echo "===== CTI Infrastructure Deployment ====="
echo "This script will set up and deploy the complete CTI infrastructure."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo"
  exit 1
fi

WORKDIR=$(pwd)

# Start containers
echo "Starting all CTI components..."
docker-compose up -d

# Wait for services to initialize
echo "Waiting for services to initialize..."
sleep 30

echo "===== CTI Infrastructure is now ready! ====="
echo "Access points:"
echo "- GRR: http://localhost:8001"
echo "- TheHive: http://localhost:9000"
echo "- Cortex: http://localhost:9001"
echo "- MISP: http://localhost:8080"
echo "- Portainer: https://localhost:9443"
echo "- Minio Console: http://localhost:9090"

echo ""
echo "IMPORTANT: Please read CORTEX_API_KEY_INSTRUCTIONS.md to complete TheHive-Cortex integration."
echo ""
echo "To install Kasm Workspaces separately, run ./install_kasm.sh"
EOF

    chmod +x "$CTI_DIR/deploy.sh"
}

# Create a README file
create_readme() {
    cat > "$CTI_DIR/README.md" << 'EOF'
# CTI Infrastructure

This repository contains the necessary files to quickly deploy a Cyber Threat Intelligence (CTI) infrastructure using Docker.

## Components

- **GRR Rapid Response**: For remote live forensics
- **TheHive**: Case management platform
- **Cortex**: Observable analysis engine
- **MISP**: Threat Intelligence Platform
- **Kasm Workspaces**: Browser isolation and virtual workspace
- **Portainer**: Container management

## Prerequisites

- Ubuntu 20.04 LTS or newer
- Docker and Docker Compose
- Git
- Sufficient system resources (recommended: 16GB RAM, 4+ CPU cores, 100GB+ storage)

## Quick Start

1. Clone this repository
2. Run the setup script: `./setup.sh`
3. Deploy the infrastructure: `sudo ./deploy.sh`
4. Follow the instructions in CORTEX_API_KEY_INSTRUCTIONS.md to complete TheHive setup

## Access Points

- GRR: http://localhost:8001
- TheHive: http://localhost:9000
- Cortex: http://localhost:9001
- MISP: http://localhost:8080
- Portainer: https://localhost:9443
- Minio Console: http://localhost:9090

## Kasm Workspaces

To install Kasm Workspaces separately, run:

```
./install_kasm.sh
```

Follow the on-screen instructions to complete the setup.

## Security Considerations

- Change default passwords
- Restrict network access
- Set up proper authentication
- Consider deploying behind a VPN

## Customization

You can modify the `docker-compose.yml` file to adjust ports, volumes, and other settings according to your needs.
EOF
}

# Create .deb package directory structure
create_deb_package() {
    echo "Creating .deb package structure..."
    
    DEB_DIR="$WORKDIR/cti-infrastructure-deb"
    mkdir -p "$DEB_DIR/DEBIAN"
    mkdir -p "$DEB_DIR/opt/cti-infrastructure"
    
    # Create control file
    cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: cti-infrastructure
Version: 1.0.0
Section: utils
Priority: optional
Architecture: all
Depends: docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin, git
Maintainer: CTI Infrastructure Team <admin@example.com>
Description: Rapidly deployable CTI infrastructure
 This package provides a complete Cyber Threat Intelligence infrastructure
 including GRR Rapid Response, TheHive, Cortex, MISP, and Kasm Workspaces.
EOF
    
    # Create postinst script
    cat > "$DEB_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Create a symbolic link to the deployment script
ln -sf /opt/cti-infrastructure/deploy.sh /usr/local/bin/deploy-cti

# Set permissions
chmod +x /opt/cti-infrastructure/deploy.sh
chmod +x /opt/cti-infrastructure/install_kasm.sh

echo "CTI Infrastructure package has been installed."
echo "To deploy, run: sudo deploy-cti"
echo "For more information, see /opt/cti-infrastructure/README.md"

exit 0
EOF
    
    # Make postinst executable
    chmod 755 "$DEB_DIR/DEBIAN/postinst"
    
    # Copy files to the package directory
    cp -r "$CTI_DIR"/* "$DEB_DIR/opt/cti-infrastructure/"
    
    # Build the package
    dpkg-deb --build "$DEB_DIR" "$WORKDIR/cti-infrastructure_1.0.0_all.deb"
    
    echo "Created .deb package: $WORKDIR/cti-infrastructure_1.0.0_all.deb"
}

# Main execution
setup_docker
setup_grr
setup_misp
setup_thehive
setup_kasm
create_master_script
create_readme
create_deb_package

echo "Setup complete! Navigate to $CTI_DIR to deploy your CTI infrastructure."
echo "To deploy, run: cd $CTI_DIR && sudo ./deploy.sh"
echo "To install as a package, run: sudo dpkg -i cti-infrastructure_1.0.0_all.deb"