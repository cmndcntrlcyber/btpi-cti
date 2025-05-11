# CTI Platform Setup Guide

This guide provides detailed instructions for setting up the CTI (Cyber Threat Intelligence) platform.

## System Requirements

- **CPU**: 4+ cores (8+ recommended for production use)
- **RAM**: 16GB minimum (32GB+ recommended for production use)
- **Storage**: 100GB+ (SSD preferred for better performance)
- **Operating System**: Ubuntu 20.04 LTS or newer
- **Network**: Internet access for initial setup, internal network for deployment

## Installation Options

This solution offers three installation methods:

### 1. Using the Setup Script

The setup script will prepare your environment, download necessary components, and configure the infrastructure:

```bash
# Clone the repository
git clone https://github.com/cmndcntrlcyber/btpi-cti.git
cd btpi-cti

# Run the setup script
chmod +x deploy.sh
./deploy.sh
```

### 2. Using Docker Compose Directly

If you already have Docker and Docker Compose installed:

```bash
# Clone the repository
git clone https://github.com/cmndcntrlcyber/btpi-cti.git
cd btpi-cti

# Start the infrastructure
docker-compose up -d
```

### 3. Using the DEB Package

On Debian-based systems, you can install the infrastructure as a package:

```bash
# Download the package
wget https://github.com/cmndcntrlcyber/btpi-cti/releases/download/v1.0.0/btpi-cti_1.0.0_all.deb

# Install the package
sudo dpkg -i btpi-cti_1.0.0_all.deb
sudo apt-get install -f

# Deploy the infrastructure
sudo deploy-cti
```

## Post-Installation Configuration

After installation, you'll need to configure each component of the CTI platform.

### TheHive and Cortex Integration

1. Access Cortex at http://localhost:9001
2. Create an initial administrator account
3. Navigate to Organizations → Create a new organization (e.g., "CTI")
4. Create a new user with "read, analyze, orgadmin" roles
5. Generate an API key for this user
6. Run the integration setup script:
   ```bash
   sudo ./scripts/setup-integration.sh
   ```
7. Select option 1 to set up TheHive and Cortex integration
8. Follow the prompts to complete the integration

### GRR Configuration

1. Access GRR at http://localhost:8001
2. Create an administrator account
3. Download client installers for deployment to endpoints
4. Run the integration setup script:
   ```bash
   sudo ./scripts/setup-integration.sh
   ```
5. Select option 3 to set up GRR and TheHive integration
6. Follow the prompts to complete the integration

### OpenCTI Configuration

1. Access OpenCTI at http://localhost:8080 (or the port assigned during installation)
2. Default credentials are admin@opencti.io / changeme
3. Change the default password immediately
4. Configure connectors and integrations:
   - Go to Data > Connectors
   - Enable and configure the connectors you need
5. To integrate with TheHive and Cortex:
   ```bash
   sudo ./scripts/setup-integration.sh
   ```
6. Select the option to set up OpenCTI integration
7. Follow the prompts to complete the integration

### OpenBAS Configuration

1. Access OpenBAS at http://localhost:8090 (or the port assigned during installation)
2. Default credentials are admin@openbas.io / changeme
3. Change the default password immediately
4. Configure your breach and attack simulation scenarios:
   - Go to Scenarios
   - Create or import scenarios based on your requirements
5. To integrate with other components:
   ```bash
   sudo ./scripts/setup-integration.sh
   ```
6. Select the option to set up OpenBAS integration
7. Follow the prompts to complete the integration

### Kasm Workspaces Setup

```bash
# Run the Kasm installer
sudo ./kasm-scripts/install_kasm.sh
```

After installation:
1. Access Kasm at https://localhost:443 or the IP of your server
2. Log in with the credentials provided during installation
3. Deploy the custom workspaces using the provided script:
   ```bash
   ./kasm-scripts/kasm-image-builder.sh --build-all
   ./kasm-scripts/kasm-image-builder.sh --register threat-hunting
   ./kasm-scripts/kasm-image-builder.sh --register malware-analysis
   ./kasm-scripts/kasm-image-builder.sh --register osint
   ```

## Verifying Installation

To verify that all components are running correctly:

```bash
# Check the status of all containers
docker-compose ps

# Run the health check script
sudo ./scripts/health-check.sh
```

## Next Steps

After completing the setup, refer to the following guides for more information:

- [User Guide](user-guide.md) - For instructions on using the CTI platform
- [Administrator Guide](admin-guide.md) - For advanced configuration and maintenance
- [API Examples](api-examples.md) - For integrating with the CTI platform APIs
- [Troubleshooting Guide](troubleshooting.md) - For resolving common issues

## Security Considerations

- **Change Default Passwords**: Immediately change all default passwords
- **Network Security**: Deploy behind a VPN or in an isolated network
- **Access Control**: Implement proper user access controls for each tool
- **Data Protection**: Encrypt sensitive data at rest
- **Backup**: Regularly backup the Docker volumes containing your data
- **Updates**: Keep all components updated to the latest versions
