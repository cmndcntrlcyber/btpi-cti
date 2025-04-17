# BTPI-CTI: Cyber Threat Intelligence Platform

BTPI-CTI is a comprehensive Cyber Threat Intelligence platform that integrates multiple open-source security tools into a unified solution.

## Components

The platform consists of the following components:

- **Portainer**: Container management interface
- **GRR Rapid Response**: Remote forensics and incident response tool
- **TheHive**: Security incident response platform 
- **Cortex**: Observable analysis engine that integrates with TheHive
- **MISP**: Malware Information Sharing Platform
- **Integration API**: Documentation and APIs for component integration

## Architecture

Each component is deployed as a separate service within its own directory. This modular approach allows for:

- Independent service management (start/stop/update)
- Separation of configuration files
- Prevention of port conflicts
- Easier troubleshooting and maintenance

The platform uses a shared Docker network (`cti-network`) to facilitate communication between services.

## Prerequisites

- Linux OS (tested on Ubuntu 22.04)
- Docker and Docker Compose installed
- At least 8GB RAM and 50GB disk space
- Sudo/root access for deployment

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/btpi/btpi-cti.git
   cd btpi-cti
   ```

2. Run the master deployment script:
   ```
   sudo ./deploy.sh
   ```

This will:
- Create the Docker network
- Generate necessary secrets and passwords
- Deploy all services in proper order
- Display access URLs and credentials

## Service Management

### Full Deployment

To deploy the entire platform:
```
sudo ./deploy.sh
```

### Individual Services

Each service has its own deployment script for independent management:

```
# Deploy/redeploy just Portainer
sudo ./services/portainer/deploy.sh

# Deploy/redeploy just GRR
sudo ./services/grr/deploy.sh

# Deploy/redeploy just TheHive + Cortex
sudo ./services/thehive/deploy.sh

# Deploy/redeploy just MISP
sudo ./services/misp/deploy.sh

# Deploy/redeploy just the Integration API
sudo ./services/integration-api/deploy.sh
```

## Access Information

After deployment, services are available at:

- **Portainer**: http://[your-ip]:9010
- **GRR Admin UI**: http://[your-ip]:8001
- **TheHive**: http://[your-ip]:9000
- **Cortex**: http://[your-ip]:9001
- **MISP**: http://[your-ip]:8083
- **Integration API**: http://[your-ip]:8888

Default credentials are generated during installation and displayed at the end of the deployment process.

## Troubleshooting

If a service is not working correctly:

1. Check its status:
   ```
   docker ps | grep [service-name]
   ```

2. View service logs:
   ```
   docker logs [container-name]
   ```

3. Redeploy the service:
   ```
   sudo ./services/[service-name]/deploy.sh
   ```

## Security Notice

This platform contains sensitive security tools. Ensure proper access controls are in place and consider deploying behind a VPN or secure network.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
