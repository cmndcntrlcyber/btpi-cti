# BTPI-CTI: Container Threat Intelligence Platform

BTPI-CTI is a containerized cyber threat intelligence platform combining multiple powerful security tools:

- GRR (Rapid Response)
- TheHive (Case Management)
- Cortex (Security Orchestration)
- MISP (Threat Intelligence Platform)
- Integration API (Web interface for integration documentation)

## Optimized Container Architecture

This updated architecture resolves several key issues with container builds, port management, and dependency coordination:

### 1. Centralized Environment Configuration
- Global `.env` file contains all port configurations, memory limits, and build parameters
- Dynamic port allocation via `scripts/allocate_ports.sh` to prevent conflicts
- Shared variable space for multiple services

### 2. Profile-Based Deployment System
- Selective deployment using Docker Compose profiles
- Start only what you need: frontends, backends, or specific service groups
- Simplified testing and development workflows

### 3. Standardized Container Naming & Networking
- Automatic prefixing of container names
- Shared network configuration
- Improved service discovery

## Quick Start

```bash
# Deploy everything (all services)
sudo ./deploy.sh

# Deploy only frontend services (UIs)
sudo ./deploy.sh --frontends

# Deploy only TheHive and its dependencies
sudo ./deploy.sh --thehive

# Deploy with clean volumes (fresh install)
sudo ./deploy.sh --clean
```

## Port Management

The system now manages ports dynamically:

1. Default ports are defined in `.env`
2. The `allocate_ports.sh` script can find available ports automatically
3. All port references use environment variables

## Deployment Profiles

Available profiles for selective deployment:

| Profile | Description |
|---------|-------------|
| `all` | All services |
| `frontends` | User interfaces (TheHive, GRR UI, etc.) |
| `backends` | Background services and workers |
| `databases` | Database services only |
| `management` | Management tools (Portainer) |
| `thehive-frontend` | TheHive & Cortex UIs |
| `thehive-backend` | TheHive databases and dependencies |
| `grr-frontend` | GRR Admin UI |
| `grr-backend` | GRR backend services |
| `misp-frontend` | MISP frontend |
| `misp-backend` | MISP databases and dependencies |

## Development Mode

For development, a `docker-compose.override.yml` file provides development-specific settings that are automatically applied when running `docker-compose up`:

- Live reloading
- Debug settings
- Volume mounts to edit files directly

## Troubleshooting

If you encounter port conflicts:

```bash
# Reallocate ports
./scripts/allocate_ports.sh

# Restart with new port allocation
sudo ./deploy.sh
```

## Architecture Diagram

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   FRONTENDS     │     │    BACKENDS     │     │    DATABASES    │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│  - GRR Admin UI │     │ - GRR Workers   │     │ - MySQL (GRR)   │
│  - TheHive      │◄───►│ - Fleetspeak    │◄───►│ - Cassandra     │
│  - Cortex       │     │ - MISP Modules  │     │ - Elasticsearch │
│  - MISP         │     │                 │     │ - Redis         │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         ▲                      ▲                       ▲
         │                      │                       │
         └──────────────────────┼───────────────────────┘
                                │
                     ┌──────────▼─────────┐
                     │    MANAGEMENT      │
                     ├────────────────────┤
                     │  - Portainer       │
                     │  - Network Manager │
                     └────────────────────┘
```

## Service Management

```bash
# List running containers with profiles
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check logs for a specific service
docker logs btpi_cti_thehive

# Stop all services
docker-compose down

# Stop only specific profiles
docker-compose --profile frontends down
