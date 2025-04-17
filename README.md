# BTPI-CTI 
## Blue Team Portable Infrastructure - Cyber Threat Intelligence
A Cyber Threat Intelligence and Threat Hunting flavor of the Blue Team Portable Infrastructure

![BTPI-CTI Logo](/docs/BTPI-CTI-Logo.svg)

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

# Create the required secrets directory
mkdir -p secrets

# Generate secure passwords
cat << EOF > secrets/mysql_root_password
$(openssl rand -base64 16)
EOF
cat << EOF > secrets/mysql_password
$(openssl rand -base64 16)
EOF
cat << EOF > secrets/elastic_password
$(openssl rand -base64 16)
EOF
cat << EOF > secrets/minio_root_user
minioadmin
EOF
cat << EOF > secrets/minio_root_password
$(openssl rand -base64 16)
EOF
cat << EOF > secrets/thehive_secret
$(openssl rand -base64 32)
EOF
cat << EOF > secrets/cortex_api_key
API-KEY-PLACEHOLDER-REPLACE-AFTER-SETUP
EOF
cat << EOF > secrets/misp_root_password
$(openssl rand -base64 16)
EOF
cat << EOF > secrets/misp_mysql_password
$(openssl rand -base64 16)
EOF
cat << EOF > secrets/misp_admin_password
$(openssl rand -base64 16)
EOF

# Secure the password files
chmod 600 secrets/*

# Run the setup script
chmod +x deploy.sh
./deploy.sh

# Manage the infrastructure
./cti-manage.sh
```

### 2. Using Docker Compose Directly

If you already have Docker and Docker Compose installed:

```bash
# Clone the repository
git clone https://github.com/cmndcntrlcyber/btpi-cti.git
cd btpi-cti

# Create and prepare secrets (see steps above)

# Start the infrastructure
docker-compose up -d

# Check status
docker-compose ps
```

### 3. Using the DEB Package

On Debian-based systems, you can install the infrastructure as a package:

```bash
# Download the package
wget https://github.com/cmndcntrlcyber/btpi-cti/releases/download/v1.0.0/btpi-cti_1.0.0_all.deb

# Install the package
sudo dpkg -i btpi-cti_1.0.0_all.deb
sudo apt-get install -f

# Create and prepare secrets directory
sudo mkdir -p /opt/btpi-cti/secrets
# Generate all secrets as shown above
sudo chmod 600 /opt/btpi-cti/secrets/*

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
6. Update the cortex_api_key secret:
   ```bash
   echo "YOUR_CORTEX_API_KEY" > secrets/cortex_api_key
   chmod 600 secrets/cortex_api_key
   ```
7. Restart TheHive: `docker-compose restart thehive`

### MISP Configuration

1. Access MISP at http://localhost:8080
2. Login with the credentials:
   - Username: admin@admin.test
   - Password: (value stored in `secrets/misp_admin_password`)
3. Change the default password immediately
4. Configure MISP according to your organization's needs

### GRR Configuration

1. Access GRR at http://localhost:8001
2. Create an administrator account using the setup wizard
3. Download client installers for deployment to endpoints

### Kasm Workspaces Setup

```bash
# Run the Kasm installer
./kasm-builder.sh --build-all
```

After installation:
1. Access Kasm at https://localhost:443 or the IP of your server
2. Log in with the credentials provided during installation
3. Deploy the custom workspaces using the administration interface

## Custom Workspaces

### Threat Hunting Workspace

Specialized for threat hunting operations with pre-installed tools:
- Advanced OSINT capabilities
- Integrated with TheHive, Cortex, and MISP
- Custom functions for intelligence gathering
- CyberChef for data analysis
- Multiple browsers for OSINT work

To build manually:
```bash
docker build -t kasm-threat-hunting -f kasm-images/threat-hunting.Dockerfile .
```

### Malware Analysis Workspace

Secure environment for malware analysis:
- Ghidra, Radare2, and Cutter
- Python analysis frameworks
- Isolated environment for samples
- Analysis scripts and automation
- VirusTotal integration

To build manually:
```bash
docker build -t kasm-malware-analysis -f kasm-images/malware-analysis.Dockerfile .
```

### OSINT Investigation Workspace

Optimized for open source intelligence gathering:
- Multiple specialized search tools
- People & company research tools
- Domain/IP investigation capabilities
- Email and username trackers
- Social media investigation tools

To build manually:
```bash
docker build -t kasm-osint -f kasm-images/osint.Dockerfile .
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
   - Run the health check script: `./cti-manage.sh health`

2. **Integration issues between components**:
   - Check if containers are on the same network: `docker network inspect cti-network`
   - Verify API keys are correct in the secrets directory
   - Check the integration-api container status: `docker logs cti-integration-api`

3. **Container healthcheck failures**:
   - Check container logs: `docker logs [container_name]`
   - Verify container environment variables and secrets paths
   - Check resource constraints: `docker stats`
   - Look for configuration file issues

4. **TheHive/Cortex connectivity issues**:
   - Verify Elasticsearch is running: `curl http://localhost:9200/_cluster/health`
   - Check Cassandra status: `docker exec -it cassandra nodetool status`
   - Verify the cortex_api_key is correctly set in secrets

5. **MISP issues**:
   - Check MySQL connectivity: `docker exec -it misp-db mysqladmin ping`
   - Verify Redis is functioning: `docker exec -it redis redis-cli ping`
   - Check MISP logs: `docker logs misp-core`

6. **Kasm Workspaces issues**:
   - Verify Docker images were built correctly
   - Check configuration of browser shortcuts
   - Verify desktop environment is functioning
   - Check file permissions on shared resources

### Using the Management Script

```bash
# Show component status
./cti-manage.sh status

# View logs for a specific component
./cti-manage.sh logs thehive

# Run health checks 
./cti-manage.sh health

# Restart components
./cti-manage.sh restart

# Create a backup
./cti-manage.sh backup

# Restore from a backup
./cti-manage.sh restore [backup_file]
```

### Support Resources

- Each component has its own documentation and community:
  - GRR: https://grr-doc.readthedocs.io/
  - TheHive: https://docs.thehive-project.org/
  - Cortex: https://github.com/TheHive-Project/CortexDocs
  - MISP: https://www.misp-project.org/documentation/
  - Kasm: https://kasmweb.com/docs/latest/index.html

## Maintenance

### Backup Strategy

Use the management script for regular backups:

```bash
# Create a backup
./cti-manage.sh backup

# View available backups
ls -la backups/

# Restore from a backup
./cti-manage.sh restore backups/cti_backup_20250401_120000.tar.gz
```

### Updating Components

To update the infrastructure to the latest versions:

```bash
# Update all components
./cti-manage.sh update

# View current component versions
./cti-manage.sh config
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
