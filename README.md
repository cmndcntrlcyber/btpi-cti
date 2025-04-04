# BTPI-CTI 
## Blue Team Portable Infrastructure - Cyber Threat Intelligence
A Cyber Threat Intelligence and Threat Hunting flavor of the Blue Team Portable Infrastructure

## Rapidly Deployable CTI Infrastructure

This project provides a comprehensive, ready-to-deploy Cyber Threat Intelligence (CTI) infrastructure using Docker containers. It integrates multiple industry-standard tools to enable effective threat hunting, incident response, and threat intelligence operations.

## Components

- **GRR Rapid Response**: Live forensics and incident response framework
- **TheHive**: Security incident response platform
- **Cortex**: Observable analysis engine
- **MISP**: Threat intelligence platform
- **Kasm Workspaces**: Browser isolation and virtual desktop environment
- **Portainer**: Container management interface

## Architecture

The architecture is designed to be modular and integrates all components within a common Docker network:



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
cd cti-infrastructure

# Run the setup script
chmod +x setup.sh
./setup.sh

# Deploy the infrastructure
sudo ./deploy.sh
```

### 2. Using Docker Compose Directly

If you already have Docker and Docker Compose installed:

```bash
# Clone the repository
git clone https://github.com/cmndcntrlcyber/btpi-cti.git
cd cti-infrastructure

# Start the infrastructure
docker-compose up -d
```

### 3. Using the DEB Package

On Debian-based systems, you can install the infrastructure as a package:

```bash
# Download the package
wget https://github.com/your-org/cti-infrastructure/releases/download/v1.0.0/cti-infrastructure_1.0.0_all.deb

# Install the package
sudo dpkg -i cti-infrastructure_1.0.0_all.deb
sudo apt-get install -f

# Deploy the infrastructure
sudo deploy-cti
```

## Post-Installation Configuration

### TheHive and Cortex Integration

1. Access Cortex at http://localhost:9001
2. Create an initial administrator account
3. Navigate to Organizations → Create a new organization (e.g., "CTI")
4. Create a new user with "read, analyze, orgadmin" roles
5. Generate an API key for this user
6. Update the docker-compose.yml file with this API key:
   ```yaml
   thehive:
     # other settings...
     command:
       # other settings...
       - "--cortex-keys"
       - "YOUR_API_KEY_HERE"   # Replace with your actual API key
   ```
7. Restart TheHive: `docker-compose restart thehive`

### MISP Configuration

1. Access MISP at http://localhost:8080
2. Default credentials are admin@admin.test / admin
3. Change the default password immediately
4. Configure MISP according to your organization's needs

### GRR Configuration

1. Access GRR at http://localhost:8001
2. Create an administrator account
3. Download client installers for deployment to endpoints

### Kasm Workspaces Setup

```bash
# Run the Kasm installer
./install_kasm.sh
```

After installation:
1. Access Kasm at https://localhost:443 or the IP of your server
2. Log in with the credentials provided during installation
3. Deploy the custom Threat Hunting workspace using the provided Dockerfile

## Custom Threat Hunting Workspace

This project includes a specialized Kasm workspace for threat hunting with pre-installed tools:

- OSINT tools (Shodan, Censys, etc.)
- Threat intelligence tools
- Analysis utilities
- Multiple browsers for investigative work
- Integration shortcuts to TheHive, Cortex, MISP, and GRR

To build and deploy the custom workspace:

```bash
# Build the image
docker build -t cti-threat-hunting -f kasm-threat-hunting.Dockerfile .

# Add to Kasm workspaces through the admin interface
# URL: http://localhost:3000
# Go to Workspaces → Add Workspace → Custom (Docker Registry)
# Image: cti-threat-hunting:latest
```

## Integration Points

### TheHive & Cortex
- TheHive uses Cortex for advanced observable analysis
- Cortex analyzers can be configured for additional integrations with VirusTotal, MISP, etc.

### MISP & TheHive
- Cases in TheHive can be exported to MISP as events
- MISP events can be imported into TheHive as cases or alerts

### GRR & TheHive
- Forensic findings from GRR can be manually added to TheHive cases
- Custom scripts for automating this integration are available in the `integrations` directory

## Security Considerations

- **Change Default Passwords**: Immediately change all default passwords
- **Network Security**: Deploy behind a VPN or in an isolated network
- **Access Control**: Implement proper user access controls for each tool
- **Data Protection**: Encrypt sensitive data at rest
- **Backup**: Regularly backup the Docker volumes containing your data
- **Updates**: Keep all components updated to the latest versions

## Troubleshooting

### Common Issues

1. **Container fails to start**:
   - Check logs: `docker logs [container_name]`
   - Verify resource availability: `free -m` and `df -h`
   - Ensure ports are not in use: `netstat -tulpn`

2. **Integration issues between components**:
   - Verify all containers are on the same network: `docker network inspect cti-network`
   - Check API keys are correctly configured
   - Ensure hostname resolution is working

3. **Kasm Workspaces issues**:
   - Run the diagnostic tool: `sudo /opt/kasm/bin/kasm_diagnostics`
   - Check browser compatibility for the admin interface

### Support Resources

- Each component has its own documentation and community:
  - GRR: https://grr-doc.readthedocs.io/
  - TheHive: https://docs.thehive-project.org/
  - Cortex: https://github.com/TheHive-Project/CortexDocs
  - MISP: https://www.misp-project.org/documentation/
  - Kasm: https://kasmweb.com/docs/latest/index.html

## Maintenance

### Backup Strategy

```bash
# Backup all volumes
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/backup \
  alpine sh -c "docker run --rm --volumes-from $(docker ps -q) -v /backup:/backup \
  alpine sh -c 'cd / && tar czf /backup/cti-volumes-backup.tar.gz \
  /var/lib/docker/volumes/'"
```

### Updating Components

To update the infrastructure to the latest versions:

```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d
```

## Extending the Infrastructure

### Adding Custom Tools

1. Create a directory for your tool
2. Add a Dockerfile and necessary files
3. Add the service to the docker-compose.yml file
4. Rebuild and restart: `docker-compose up -d --build`

### Integration with External Systems

- SIEM systems can be integrated with the infrastructure
- Custom API integrations can be developed using the APIs provided by each component
- EDR and NDR systems can feed data into TheHive and MISP

## Contributing

Contributions to improve this infrastructure are welcome:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

Please follow the coding standards and include appropriate tests and documentation.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

This project integrates and builds upon several open-source security tools:

- [GRR Rapid Response](https://github.com/google/grr)
- [TheHive Project](https://thehive-project.org/)
- [MISP Project](https://www.misp-project.org/)
- [Kasm Workspaces](https://www.kasmweb.com/)
- [Portainer](https://www.portainer.io/)

```
┌────────────────────────────────────────────────────────────────┐
│                        CTI Infrastructure                      │
│                                                                │
│  ┌──────────┐        ┌──────────┐        ┌──────────┐          │
│  │   GRR    │◄──────►│  TheHive │◄──────►│  Cortex  │          │
│  └──────────┘        └──────────┘        └──────────┘          │
│        ▲                   ▲                   ▲               │
│        │                   │                   │               │
│        │              ┌──────────┐             │               │
│        └──────────────┤   MISP   ├─────────────┘               │
│                       └──────────┘                             │
│                            ▲                                   │
│  ┌──────────┐              │              ┌──────────┐         │
│  │  Kasm    │◄─────────────┴──────────────┤Portainer │         │
│  │Workspaces│                             │          │         │
│  └──────────┘                             └──────────┘         │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```
