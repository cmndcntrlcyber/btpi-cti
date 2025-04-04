# CTI Platform Administrator Guide

This guide provides detailed information for administrators of the CTI (Cyber Threat Intelligence) platform.

## Architecture Overview

The CTI platform consists of several containerized components running on Docker:

- **TheHive**: Security incident response platform
- **Cortex**: Observable analysis engine
- **MISP**: Threat intelligence platform
- **GRR**: Live forensics and incident response framework
- **Kasm Workspaces**: Browser isolation and virtual desktop environment
- **Portainer**: Container management interface

All components are connected via a Docker network and can communicate with each other.

## System Administration

### Managing Containers

You can manage the CTI platform containers using Docker Compose:

```bash
# Start all containers
docker-compose up -d

# Stop all containers
docker-compose down

# Restart a specific container
docker-compose restart <container_name>

# View container logs
docker-compose logs <container_name>

# View all container status
docker-compose ps
```

You can also use Portainer for a web-based interface to manage containers.

### Managing Storage

The CTI platform uses Docker volumes to persist data. You can manage these volumes using Docker commands:

```bash
# List all volumes
docker volume ls

# Inspect a volume
docker volume inspect <volume_name>

# Remove a volume (caution: this will delete all data in the volume)
docker volume rm <volume_name>
```

### Backup and Restore

The CTI platform includes scripts for backup and restore operations:

```bash
# Create a backup
sudo ./scripts/backup.sh

# Restore from a backup
sudo ./scripts/restore.sh /path/to/backup/file.tar.gz
```

The backup script creates a compressed archive containing:
- Docker volumes data
- Configuration files
- Docker Compose file
- Environment files

### Health Monitoring

The health-check.sh script monitors the health of all CTI platform components:

```bash
# Run a health check
sudo ./scripts/health-check.sh
```

The script checks:
- Container status
- Service availability
- Resource usage (CPU, memory, disk)

You can configure the script to send alerts via email or Slack by editing the configuration section at the top of the script.

### Updating the Platform

The update.sh script updates all CTI platform components:

```bash
# Update all components
sudo ./scripts/update.sh

# Update a specific component
sudo ./scripts/update.sh -c <component_name>

# Update without creating a backup
sudo ./scripts/update.sh -n

# Update without restarting services
sudo ./scripts/update.sh -r
```

## Component Administration

### TheHive Administration

#### User Management

1. Log in to TheHive as an administrator
2. Go to "Admin" > "Users"
3. Click "Create User" to add a new user
4. Set the user's details and permissions
5. Click "Create" to create the user

#### Organization Management

1. Go to "Admin" > "Organizations"
2. Click "Create Organization" to add a new organization
3. Set the organization details
4. Click "Create" to create the organization

#### Configuration

TheHive configuration files are located in the `configs/thehive/` directory. The main configuration file is `application.conf`.

### Cortex Administration

#### User Management

1. Log in to Cortex as an administrator
2. Go to "Users"
3. Click "Create User" to add a new user
4. Set the user's details and permissions
5. Click "Create" to create the user

#### Organization Management

1. Go to "Organizations"
2. Click "Create Organization" to add a new organization
3. Set the organization details
4. Click "Create" to create the organization

#### Analyzer Configuration

1. Go to "Analyzers"
2. Click on an analyzer to configure it
3. Enter the required API keys and configuration
4. Click "Save" to save the configuration

#### Configuration

Cortex configuration files are located in the `configs/cortex/` directory. The main configuration file is `application.conf`.

### MISP Administration

#### User Management

1. Log in to MISP as an administrator
2. Go to "Administration" > "Add User"
3. Fill in the user details
4. Set the user's role and permissions
5. Click "Submit" to create the user

#### Organization Management

1. Go to "Administration" > "Add Organization"
2. Fill in the organization details
3. Click "Submit" to create the organization

#### Sharing Configuration

1. Go to "Administration" > "Server Settings" > "MISP Settings"
2. Configure the sharing settings
3. Click "Submit" to save the settings

#### Configuration

MISP configuration files are located in the `configs/misp/` directory.

### GRR Administration

#### User Management

1. Log in to GRR as an administrator
2. Go to "Settings" > "Users"
3. Click "Add User" to add a new user
4. Set the user's details and permissions
5. Click "Add" to create the user

#### Client Deployment

1. Go to "Manage Binaries"
2. Download the appropriate client installer
3. Deploy the client to endpoints using your preferred method (e.g., GPO, MDM, script)

#### Configuration

GRR configuration files are located in the `configs/grr/` directory.

### Kasm Workspaces Administration

#### User Management

1. Log in to Kasm as an administrator
2. Go to "Users"
3. Click "Create User" to add a new user
4. Set the user's details and permissions
5. Click "Create" to create the user

#### Workspace Management

1. Go to "Workspaces"
2. Click "Add Workspace" to add a new workspace
3. Select "Custom (Docker Registry)"
4. Enter the workspace details and Docker image
5. Click "Create" to create the workspace

#### Custom Image Management

You can build and register custom Kasm workspace images using the kasm-image-builder.sh script:

```bash
# Build a custom image
./kasm-scripts/kasm-image-builder.sh --build <image_name>

# Register a custom image with Kasm
./kasm-scripts/kasm-image-builder.sh --register <image_name>
```

#### Configuration

Kasm configuration is managed through the web interface and the installation script.

## Integration Management

The CTI platform includes integrations between components:

### TheHive and Cortex Integration

The integration between TheHive and Cortex allows TheHive to use Cortex for analyzing observables.

To configure the integration:

```bash
# Run the integration setup script
sudo ./scripts/setup-integration.sh
```

Select option 1 to set up TheHive and Cortex integration.

### MISP and TheHive Integration

The integration between MISP and TheHive allows:
- Importing MISP events into TheHive as cases or alerts
- Exporting TheHive cases to MISP as events

To configure the integration:

```bash
# Run the integration setup script
sudo ./scripts/setup-integration.sh
```

Select option 2 to set up MISP and TheHive integration.

### GRR and TheHive Integration

The integration between GRR and TheHive allows forwarding GRR findings to TheHive as alerts.

To configure the integration:

```bash
# Run the integration setup script
sudo ./scripts/setup-integration.sh
```

Select option 3 to set up GRR and TheHive integration.

## Security Hardening

### Network Security

- Deploy the CTI platform behind a VPN or in an isolated network
- Use a reverse proxy with HTTPS for external access
- Configure firewall rules to restrict access to the platform

### Access Control

- Implement strong password policies
- Use multi-factor authentication where available
- Implement proper user access controls for each tool
- Regularly audit user accounts and permissions

### Data Protection

- Encrypt sensitive data at rest
- Implement secure backup procedures
- Regularly test restore procedures

### Container Security

- Keep all containers updated to the latest versions
- Scan container images for vulnerabilities
- Monitor container logs for suspicious activity

## Troubleshooting

For common issues and their solutions, refer to the [Troubleshooting Guide](troubleshooting.md).

### Common Issues

#### Container Fails to Start

Check the container logs:

```bash
docker-compose logs <container_name>
```

Verify resource availability:

```bash
# Check memory usage
free -m

# Check disk usage
df -h

# Check if ports are in use
netstat -tulpn
```

#### Integration Issues

Verify all containers are on the same network:

```bash
docker network inspect cti-network
```

Check API keys are correctly configured in the integration scripts.

#### Performance Issues

Monitor resource usage:

```bash
# Monitor CPU and memory usage
top

# Monitor disk I/O
iostat

# Monitor Docker resource usage
docker stats
```

Adjust resource limits in the docker-compose.yml file if needed.

## Advanced Configuration

### Custom Analyzers for Cortex

You can add custom analyzers to Cortex:

1. Create a new analyzer in the appropriate format
2. Add the analyzer to the Cortex container
3. Restart Cortex
4. Enable the analyzer in the Cortex web interface

### Custom Workspaces for Kasm

You can create custom Kasm workspaces:

1. Create a new Dockerfile in the kasm-images directory
2. Build the image using the kasm-image-builder.sh script
3. Register the image with Kasm

### External Integrations

The CTI platform can be integrated with external systems:

- SIEM systems
- EDR and NDR systems
- Ticketing systems
- Custom API integrations

Refer to the [API Examples](api-examples.md) guide for more information.

## Performance Tuning

### Container Resource Allocation

You can adjust the resource allocation for containers in the docker-compose.yml file:

```yaml
services:
  thehive:
    # other settings...
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
```

### Database Optimization

For TheHive and Cortex, you can optimize the Elasticsearch database:

1. Edit the Elasticsearch configuration in the configs directory
2. Adjust the JVM heap size and other settings
3. Restart the containers

### Monitoring and Alerting

Set up monitoring and alerting for the CTI platform:

1. Configure the health-check.sh script to send alerts
2. Set up a cron job to run the script regularly
3. Monitor resource usage and performance

## Maintenance Procedures

### Regular Maintenance Tasks

- Update all components regularly using the update.sh script
- Backup data regularly using the backup.sh script
- Monitor disk usage and clean up old data if needed
- Audit user accounts and permissions
- Review logs for errors and issues

### Disaster Recovery

1. Maintain regular backups using the backup.sh script
2. Store backups in a secure, off-site location
3. Document the restore procedure
4. Regularly test the restore procedure
5. Maintain a list of all configuration settings and customizations
