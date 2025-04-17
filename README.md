# BTPI-CTI Platform

Comprehensive Cyber Threat Intelligence (CTI) platform that integrates multiple security tools for threat analysis, incident response, and intelligence sharing.

## Overview

The BTPI-CTI platform provides a containerized environment with the following components:

- **TheHive**: Case management and incident response platform
- **Cortex**: Security operations orchestration with analyzers and responders
- **MISP**: Threat intelligence platform for sharing IOCs
- **GRR Rapid Response**: Remote live forensics tool
- **Attack Workbench**: MITRE ATT&CK framework implementation
- **Portainer**: Container management interface
- **Kasm Workspaces**: Browser isolation and secure desktop environments

## Prerequisites

### Docker and Docker Compose

Docker is required to run the BTPI-CTI platform. If not already installed, follow these steps:

```bash
# Add Docker's official GPG key
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker packages
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin curl git

# Verify installation
sudo docker run hello-world
```

> Note: If you use an Ubuntu derivative distro like Linux Mint, you may need to use `UBUNTU_CODENAME` instead of `VERSION_CODENAME`.

## Installation

### Quick Start

For a quick deployment of the entire stack with all fixes applied:

```bash
# Clone the repository
git clone https://github.com/your-organization/btpi-cti.git
cd btpi-cti

# Run the comprehensive fix script with sudo permissions
sudo ./scripts/fix-stack-issues.sh
```

This script will:
1. Fix TheHive Docker image tag issue
2. Create all necessary configuration files
3. Set up missing directories and configurations
4. Generate secure secrets for all components
5. Start the entire CTI stack

### Kasm Workspaces Integration

After deploying the main stack, you can integrate all CTI applications with Kasm Workspaces for enhanced security:

```bash
sudo ./scripts/kasm-integration.sh
```

This will:
1. Install Kasm Workspaces if not already installed
2. Configure Nginx proxies for all CTI applications
3. Create secure SSL-enabled access to all tools

## Components

### Portainer

Portainer provides a web-based management interface for Docker:

- **Web Interface**: https://localhost:9443
- **Username**: admin (first-time setup)
- **Password**: Set during first login

### TheHive

TheHive is a scalable, open-source security incident response platform:

- **Web Interface**: http://localhost:9000
- **Default Username**: admin@thehive.local
- **Default Password**: secret

### Cortex

Cortex is a powerful observable analysis engine that connects to many external services:

- **Web Interface**: http://localhost:9001
- **Default Username**: admin@cortex.local
- **Default Password**: secret

### MISP

MISP is an open-source threat intelligence platform for sharing, storing, and correlating IOCs:

- **Web Interface**: http://localhost:8083
- **Default Username**: admin@admin.test
- **Default Password**: admin

### GRR Rapid Response

GRR is an incident response framework focused on remote live forensics:

- **Web Interface**: http://localhost:8001
- **Default Username**: admin
- **Default Password**: Set during first login

### Attack Workbench

Attack Workbench provides a collaborative environment for working with ATT&CK data:

- **Web Interface**: http://localhost:9080
- **MongoDB**: localhost:27018
- **REST API**: http://localhost:3500

## Secure Access via Kasm Workspaces

When Kasm Workspaces integration is enabled, you can access all CTI applications through the secure Kasm interface:

- **Kasm Web Interface**: https://localhost
- **TheHive**: https://thehive.kasm.local
- **Cortex**: https://cortex.kasm.local
- **MISP**: https://misp.kasm.local
- **GRR**: https://grr.kasm.local
- **Portainer**: https://portainer.kasm.local

> Note: Add the appropriate entries to your hosts file to resolve these domains locally.

## Troubleshooting

If you encounter issues with the stack, you can use the provided fix scripts:

```bash
# Fix TheHive Docker image tag issue
sudo ./scripts/thehive-fix.sh

# Fix all stack configuration issues
sudo ./scripts/fix-stack-issues.sh

# Integrate with Kasm Workspaces
sudo ./scripts/kasm-integration.sh
```

### Common Issues

1. **TheHive container fails to start**:
   - Check if you're using a valid image tag with `docker-compose pull thehive`
   - Ensure the application.conf file exists

2. **Nginx configuration errors**:
   - Verify the configs/nginx/default.conf file exists and is properly formatted

3. **GRR client repackaging script not found**:
   - Ensure grr_configs/server/repack_clients.sh exists and is executable

## Custom Kasm Workspace Images

BTPI-CTI includes specialized Kasm Workspace images for:

- **OSINT Investigations**: Pre-configured with OSINT tools
- **Threat Hunting**: Tools for active threat hunting
- **Malware Analysis**: Isolated environment for malware analysis

You can build these custom images using:

```bash
./kasm-builder.sh osint
./kasm-builder.sh threat-hunting
./kasm-builder.sh malware-analysis
```

## Additional Setup Information

### Kasm Workspaces Full Installation

For a direct installation of Kasm Workspaces:

```bash
cd /tmp
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_1.15.0.06fdc8.tar.gz
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_service_images_amd64_1.15.0.06fdc8.tar.gz
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_workspace_images_amd64_1.15.0.06fdc8.tar.gz
tar -xf kasm_release_1.15.0.06fdc8.tar.gz
sudo bash kasm_release/install.sh --offline-workspaces /tmp/kasm_release_workspace_images_amd64_1.15.0.06fdc8.tar.gz --offline-service /tmp/kasm_release_service_images_amd64_1.15.0.06fdc8.tar.gz
```

### Attack Workbench Manual Setup

To manually set up Attack Workbench:

```bash
# Clone repositories
git clone https://github.com/center-for-threat-informed-defense/attack-workbench-frontend.git
git clone https://github.com/center-for-threat-informed-defense/attack-workbench-rest-api.git

# Pull and run Attack Flow
docker pull ghcr.io/center-for-threat-informed-defense/attack-flow:main
docker run --rm --name AttackFlowBuilder -p8000:80 ghcr.io/center-for-threat-informed-defense/attack-flow:main

# Start Attack Workbench
cd attack-workbench-frontend/
docker compose up -d
```

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.
