# CTI Platform Troubleshooting Guide

This guide provides solutions for common issues that may arise when using the CTI platform.

## Table of Contents

- [General Troubleshooting](#general-troubleshooting)
- [Docker and Container Issues](#docker-and-container-issues)
- [TheHive Issues](#thehive-issues)
- [Cortex Issues](#cortex-issues)
- [MISP Issues](#misp-issues)
- [GRR Issues](#grr-issues)
- [Kasm Workspaces Issues](#kasm-workspaces-issues)
- [Integration Issues](#integration-issues)
- [Performance Issues](#performance-issues)
- [Backup and Restore Issues](#backup-and-restore-issues)
- [Logging and Monitoring](#logging-and-monitoring)

## General Troubleshooting

### Platform Not Starting

**Symptoms:**
- Docker containers fail to start
- Services are not accessible

**Possible Causes:**
- Docker daemon not running
- Port conflicts
- Insufficient resources
- Configuration errors

**Solutions:**
1. Check if Docker is running:
   ```bash
   systemctl status docker
   ```
   If not running, start it:
   ```bash
   systemctl start docker
   ```

2. Check for port conflicts:
   ```bash
   netstat -tulpn | grep <port_number>
   ```
   If a port is in use, either stop the conflicting service or modify the docker-compose.yml file to use a different port.

3. Check system resources:
   ```bash
   free -m
   df -h
   ```
   Ensure you have sufficient memory, CPU, and disk space.

4. Verify configuration files:
   ```bash
   docker-compose config
   ```
   This will validate your docker-compose.yml file.

### Health Check Failures

**Symptoms:**
- Health check script reports errors
- Services are running but not responding

**Solutions:**
1. Run the health check script with verbose output:
   ```bash
   sudo ./scripts/health-check.sh -v
   ```

2. Check individual service status:
   ```bash
   docker-compose ps
   ```

3. Check service logs:
   ```bash
   docker-compose logs <service_name>
   ```

## Docker and Container Issues

### Container Fails to Start

**Symptoms:**
- Container shows status as "Exited" or "Created" but not "Running"
- Error messages in container logs

**Solutions:**
1. Check container logs:
   ```bash
   docker-compose logs <container_name>
   ```

2. Check for resource constraints:
   ```bash
   docker stats
   ```

3. Try recreating the container:
   ```bash
   docker-compose up -d --force-recreate <container_name>
   ```

4. Check if volumes are properly mounted:
   ```bash
   docker volume ls
   docker volume inspect <volume_name>
   ```

### Network Issues

**Symptoms:**
- Containers cannot communicate with each other
- "Connection refused" errors

**Solutions:**
1. Check if containers are on the same network:
   ```bash
   docker network ls
   docker network inspect cti-network
   ```

2. Verify container IP addresses:
   ```bash
   docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container_name>
   ```

3. Test connectivity between containers:
   ```bash
   docker exec <container_name> ping <other_container_name>
   ```

4. Recreate the network:
   ```bash
   docker-compose down
   docker network prune
   docker-compose up -d
   ```

### Volume Issues

**Symptoms:**
- Data not persisting after container restart
- Permission errors in container logs

**Solutions:**
1. Check volume mounts:
   ```bash
   docker inspect <container_name> | grep -A 10 Mounts
   ```

2. Check volume permissions:
   ```bash
   ls -la /var/lib/docker/volumes/
   ```

3. Fix permissions:
   ```bash
   sudo chown -R 1000:1000 /path/to/volume/data
   ```

4. Recreate the volume (caution: this will delete all data in the volume):
   ```bash
   docker-compose down
   docker volume rm <volume_name>
   docker-compose up -d
   ```

## TheHive Issues

### TheHive Not Starting

**Symptoms:**
- TheHive container exits shortly after starting
- Error messages in logs about Elasticsearch or database

**Solutions:**
1. Check TheHive logs:
   ```bash
   docker-compose logs thehive
   ```

2. Check Elasticsearch status:
   ```bash
   curl -X GET "localhost:9200/_cluster/health?pretty"
   ```

3. Check Elasticsearch logs:
   ```bash
   docker-compose logs elasticsearch
   ```

4. Increase Elasticsearch memory limits in docker-compose.yml:
   ```yaml
   elasticsearch:
     environment:
       - "ES_JAVA_OPTS=-Xms2g -Xmx2g"
   ```

5. Reset TheHive database (caution: this will delete all data):
   ```bash
   docker-compose down
   docker volume rm cti_thehive_data
   docker-compose up -d
   ```

### Authentication Issues

**Symptoms:**
- Cannot log in to TheHive
- "Invalid credentials" error

**Solutions:**
1. Reset admin password:
   ```bash
   docker exec -it thehive thehive update-user --user admin@thehive.local --password <new_password>
   ```

2. Check if the database is corrupted:
   ```bash
   docker exec -it elasticsearch curl -X GET "localhost:9200/_cat/indices?v"
   ```

3. If necessary, recreate the user:
   ```bash
   docker exec -it thehive thehive create-user --user admin@thehive.local --password <password> --role admin
   ```

### API Issues

**Symptoms:**
- API calls return errors
- Integrations with other components fail

**Solutions:**
1. Check API key validity:
   ```bash
   curl -H "Authorization: Bearer <api_key>" http://localhost:9000/api/case
   ```

2. Generate a new API key for the user through the web interface.

3. Check TheHive configuration for API settings:
   ```bash
   docker exec -it thehive cat /etc/thehive/application.conf | grep api
   ```

## Cortex Issues

### Cortex Not Starting

**Symptoms:**
- Cortex container exits shortly after starting
- Error messages in logs about Elasticsearch or database

**Solutions:**
1. Check Cortex logs:
   ```bash
   docker-compose logs cortex
   ```

2. Check Elasticsearch status:
   ```bash
   curl -X GET "localhost:9200/_cluster/health?pretty"
   ```

3. Reset Cortex database (caution: this will delete all data):
   ```bash
   docker-compose down
   docker volume rm cti_cortex_data
   docker-compose up -d
   ```

### Analyzer Issues

**Symptoms:**
- Analyzers fail to run
- "Job failed" errors

**Solutions:**
1. Check if the analyzer is properly configured:
   ```bash
   curl -H "Authorization: Bearer <api_key>" http://localhost:9001/api/analyzer
   ```

2. Check analyzer logs:
   ```bash
   docker-compose logs cortex | grep <analyzer_name>
   ```

3. Verify API keys for external services (e.g., VirusTotal, OTX) in the analyzer configuration.

4. Restart the analyzer:
   ```bash
   curl -H "Authorization: Bearer <api_key>" -X POST http://localhost:9001/api/analyzer/<analyzer_id>/restart
   ```

## MISP Issues

### MISP Not Starting

**Symptoms:**
- MISP container exits shortly after starting
- Error messages in logs about database or configuration

**Solutions:**
1. Check MISP logs:
   ```bash
   docker-compose logs misp
   ```

2. Check MySQL status:
   ```bash
   docker-compose logs mysql
   ```

3. Reset MISP database (caution: this will delete all data):
   ```bash
   docker-compose down
   docker volume rm cti_misp_db
   docker-compose up -d
   ```

### Synchronization Issues

**Symptoms:**
- Events not synchronizing between MISP instances
- Error messages about synchronization

**Solutions:**
1. Check synchronization settings in MISP:
   - Go to "Synchronisation" > "List Servers"
   - Verify server settings and credentials

2. Check if the remote server is accessible:
   ```bash
   curl -I <remote_misp_url>
   ```

3. Check MISP logs for synchronization errors:
   ```bash
   docker-compose logs misp | grep -i sync
   ```

## GRR Issues

### GRR Server Not Starting

**Symptoms:**
- GRR container exits shortly after starting
- Error messages in logs about database or configuration

**Solutions:**
1. Check GRR logs:
   ```bash
   docker-compose logs grr
   ```

2. Check MySQL status:
   ```bash
   docker-compose logs mysql
   ```

3. Reset GRR database (caution: this will delete all data):
   ```bash
   docker-compose down
   docker volume rm cti_grr_db
   docker-compose up -d
   ```

### Client Communication Issues

**Symptoms:**
- Clients not showing up in the GRR console
- Clients showing as "Last seen: long time ago"

**Solutions:**
1. Check if the GRR server is accessible from client machines:
   ```bash
   telnet <grr_server_ip> 8080
   ```

2. Check client logs on the endpoint:
   - Windows: Event Viewer > Applications and Services Logs > GRR
   - Linux: /var/log/grr.log

3. Reinstall the client with correct server settings:
   ```bash
   # Download client installer from GRR console
   # Run installer with correct parameters
   ```

4. Check firewall settings to ensure the GRR client can communicate with the server.

## Kasm Workspaces Issues

### Kasm Not Starting

**Symptoms:**
- Kasm containers exit shortly after starting
- Web interface not accessible

**Solutions:**
1. Check Kasm logs:
   ```bash
   docker-compose logs kasm
   ```

2. Check if required ports are open:
   ```bash
   netstat -tulpn | grep 443
   ```

3. Verify SSL certificates:
   ```bash
   ls -la /opt/kasm/certs/
   ```

4. Reinstall Kasm:
   ```bash
   sudo ./kasm-scripts/install_kasm.sh
   ```

### Workspace Issues

**Symptoms:**
- Workspaces fail to launch
- Black screen or connection errors

**Solutions:**
1. Check workspace logs:
   ```bash
   docker logs <workspace_container_id>
   ```

2. Check if the workspace image exists:
   ```bash
   docker images | grep kasm
   ```

3. Rebuild the workspace image:
   ```bash
   ./kasm-scripts/kasm-image-builder.sh --build <image_name> --force
   ```

4. Check browser compatibility and WebRTC settings.

## Integration Issues

### TheHive-Cortex Integration Issues

**Symptoms:**
- Cannot run analyzers from TheHive
- "Analyzer not found" or "Authentication failed" errors

**Solutions:**
1. Check if Cortex API key is correctly configured in TheHive:
   ```bash
   docker exec -it thehive cat /etc/thehive/application.conf | grep cortex
   ```

2. Verify Cortex API key:
   ```bash
   curl -H "Authorization: Bearer <cortex_api_key>" http://localhost:9001/api/analyzer
   ```

3. Run the integration setup script:
   ```bash
   sudo ./scripts/setup-integration.sh
   ```
   Select option 1 to set up TheHive and Cortex integration.

### MISP-TheHive Integration Issues

**Symptoms:**
- Cannot import MISP events into TheHive
- Cannot export TheHive cases to MISP

**Solutions:**
1. Check if MISP API key is correctly configured in TheHive:
   ```bash
   docker exec -it thehive cat /etc/thehive/application.conf | grep misp
   ```

2. Verify MISP API key:
   ```bash
   curl -H "Authorization: <misp_api_key>" http://localhost:8080/events/index
   ```

3. Check if TheHive API key is correctly configured in MISP:
   ```bash
   docker exec -it misp cat /var/www/MISP/app/Config/config.php | grep thehive
   ```

4. Run the integration setup script:
   ```bash
   sudo ./scripts/setup-integration.sh
   ```
   Select option 2 to set up MISP and TheHive integration.

### GRR-TheHive Integration Issues

**Symptoms:**
- Cannot send GRR findings to TheHive
- Integration script fails

**Solutions:**
1. Check if TheHive API key is correctly configured in the integration script:
   ```bash
   cat ./integrations/grr-thehive/grr2thehive.py | grep THEHIVE_API_KEY
   ```

2. Verify GRR API token:
   ```bash
   curl -H "Authorization: Bearer <grr_api_token>" http://localhost:8000/api/clients
   ```

3. Run the integration setup script:
   ```bash
   sudo ./scripts/setup-integration.sh
   ```
   Select option 3 to set up GRR and TheHive integration.

## Performance Issues

### Slow Web Interface

**Symptoms:**
- Web interfaces load slowly
- Operations take a long time to complete

**Solutions:**
1. Check system resources:
   ```bash
   top
   free -m
   df -h
   ```

2. Check container resource usage:
   ```bash
   docker stats
   ```

3. Increase container resource limits in docker-compose.yml:
   ```yaml
   services:
     thehive:
       deploy:
         resources:
           limits:
             cpus: '2'
             memory: 4G
   ```

4. Optimize Elasticsearch:
   ```bash
   # Increase JVM heap size
   docker exec -it elasticsearch elasticsearch-setup-jvm -Xms4g -Xmx4g
   
   # Restart Elasticsearch
   docker-compose restart elasticsearch
   ```

### Database Performance

**Symptoms:**
- Slow queries
- Timeout errors

**Solutions:**
1. Check Elasticsearch indices:
   ```bash
   docker exec -it elasticsearch curl -X GET "localhost:9200/_cat/indices?v"
   ```

2. Optimize Elasticsearch indices:
   ```bash
   docker exec -it elasticsearch curl -X POST "localhost:9200/_all/_forcemerge?max_num_segments=1"
   ```

3. Clean up old data:
   ```bash
   # For TheHive, delete old cases
   curl -H "Authorization: Bearer <api_key>" -X POST http://localhost:9000/api/case/_search -d '{"query": {"range": {"_createdAt": {"lt": "now-90d"}}}}' | jq -r '.[]._id' | xargs -I {} curl -H "Authorization: Bearer <api_key>" -X DELETE http://localhost:9000/api/case/{}
   
   # For MISP, delete old events through the web interface
   ```

## Backup and Restore Issues

### Backup Failures

**Symptoms:**
- Backup script fails
- Incomplete backups

**Solutions:**
1. Check backup logs:
   ```bash
   cat /opt/cti-backups/backup-*.log
   ```

2. Ensure sufficient disk space:
   ```bash
   df -h
   ```

3. Check if Docker volumes are accessible:
   ```bash
   docker volume ls
   ```

4. Run backup with verbose output:
   ```bash
   sudo ./scripts/backup.sh -v
   ```

### Restore Failures

**Symptoms:**
- Restore script fails
- Services don't start after restore

**Solutions:**
1. Check restore logs:
   ```bash
   cat /var/log/cti-restore-*.log
   ```

2. Verify backup file integrity:
   ```bash
   tar -tvf <backup_file.tar.gz>
   ```

3. Ensure Docker is running:
   ```bash
   systemctl status docker
   ```

4. Try restoring specific components:
   ```bash
   # Extract backup to a temporary directory
   mkdir -p /tmp/restore
   tar -xzf <backup_file.tar.gz> -C /tmp/restore
   
   # Restore specific volumes
   docker run --rm -v <volume_name>:/volume -v /tmp/restore/volumes/<volume_name>:/backup alpine sh -c "rm -rf /volume/* && cp -a /backup/. /volume/"
   ```

## Logging and Monitoring

### Log Collection Issues

**Symptoms:**
- Missing logs
- Incomplete log information

**Solutions:**
1. Check Docker logging driver:
   ```bash
   docker info | grep "Logging Driver"
   ```

2. Configure Docker to use a different logging driver:
   ```bash
   # Edit /etc/docker/daemon.json
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "3"
     }
   }
   
   # Restart Docker
   systemctl restart docker
   ```

3. Use a log aggregation tool like ELK stack or Graylog.

### Monitoring Issues

**Symptoms:**
- No alerts for system issues
- Missed notifications

**Solutions:**
1. Configure email alerts in the health check script:
   ```bash
   # Edit scripts/health-check.sh
   EMAIL_ALERTS=true
   EMAIL_RECIPIENT="admin@example.com"
   ```

2. Configure Slack alerts in the health check script:
   ```bash
   # Edit scripts/health-check.sh
   SLACK_ALERTS=true
   SLACK_WEBHOOK="https://hooks.slack.com/services/XXX/YYY/ZZZ"
   ```

3. Set up a cron job to run the health check regularly:
   ```bash
   # Add to crontab
   0 * * * * /path/to/scripts/health-check.sh
   ```

4. Consider using a monitoring system like Prometheus and Grafana.

## Additional Resources

If you encounter issues not covered in this guide, refer to the following resources:

- [TheHive Documentation](https://github.com/TheHive-Project/TheHiveDocs)
- [Cortex Documentation](https://github.com/TheHive-Project/CortexDocs)
- [MISP Documentation](https://www.misp-project.org/documentation/)
- [GRR Documentation](https://grr-doc.readthedocs.io/)
- [Kasm Workspaces Documentation](https://kasmweb.com/docs/latest/index.html)
- [Docker Documentation](https://docs.docker.com/)

For further assistance, contact the CTI platform support team or open an issue on the GitHub repository.
