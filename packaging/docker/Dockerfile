# BTPI-CTI Dockerfile
# This Dockerfile builds a container image for the Blue Team Portable Infrastructure - Cyber Threat Intelligence

FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    python3 \
    python3-pip \
    docker.io \
    docker-compose \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directory structure
RUN mkdir -p /opt/btpi-cti \
    && mkdir -p /opt/btpi-cti/configs \
    && mkdir -p /opt/btpi-cti/scripts \
    && mkdir -p /opt/btpi-cti/kasm-images \
    && mkdir -p /opt/btpi-cti/kasm-scripts \
    && mkdir -p /opt/btpi-cti/integrations \
    && mkdir -p /opt/btpi-cti/docs

# Set working directory
WORKDIR /opt/btpi-cti

# Copy files
COPY . /opt/btpi-cti/

# Make scripts executable
RUN chmod +x /opt/btpi-cti/deploy.sh \
    && chmod +x /opt/btpi-cti/cti-manage.sh \
    && chmod +x /opt/btpi-cti/scripts/*.sh \
    && chmod +x /opt/btpi-cti/kasm-scripts/*.sh

# Create symlinks
RUN ln -sf /opt/btpi-cti/deploy.sh /usr/local/bin/deploy-cti \
    && ln -sf /opt/btpi-cti/cti-manage.sh /usr/local/bin/cti-manage \
    && ln -sf /opt/btpi-cti/scripts/backup.sh /usr/local/bin/cti-backup \
    && ln -sf /opt/btpi-cti/scripts/restore.sh /usr/local/bin/cti-restore \
    && ln -sf /opt/btpi-cti/scripts/health-check.sh /usr/local/bin/cti-health-check \
    && ln -sf /opt/btpi-cti/scripts/update.sh /usr/local/bin/cti-update

# Expose ports
EXPOSE 9000 9001 8080 8000 8001 443

# Set entrypoint
ENTRYPOINT ["/opt/btpi-cti/deploy.sh"]

# Set default command
CMD ["--help"]
