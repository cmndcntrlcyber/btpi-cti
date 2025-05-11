#!/bin/bash

# Create directories
mkdir -p ./openbas/data
mkdir -p ./openbas/logs
mkdir -p ./openbas/conf

# Create the Docker Compose file
cat > ./openbas/docker-compose.yml << 'EOL'
version: '3'
services:
  redis:
    image: redis:7.0.12
    restart: always
    volumes:
      - redisdata:/data
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.9.1
    volumes:
      - esdata:/usr/share/elasticsearch/data
    environment:
      - discovery.type=single-node
      - xpack.ml.enabled=false
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms4g -Xmx4g"
    restart: always
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
  minio:
    image: minio/minio:RELEASE.2023-07-21T21-12-44Z
    volumes:
      - s3data:/data
    ports:
      - "9000:9000"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
    command: server /data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3
    restart: always
  rabbitmq:
    image: rabbitmq:3.12-management
    environment:
      - RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER}
      - RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS}
    volumes:
      - amqpdata:/var/lib/rabbitmq
    restart: always
  openbas:
    image: filigran/openbas:1.0.0
    environment:
      - NODE_OPTIONS=--max-old-space-size=8096
      - APP__PORT=8080
      - APP__BASE_URL=${OPENBAS_BASE_URL}
      - APP__ADMIN__EMAIL=${OPENBAS_ADMIN_EMAIL}
      - APP__ADMIN__PASSWORD=${OPENBAS_ADMIN_PASSWORD}
      - APP__ADMIN__TOKEN=${OPENBAS_ADMIN_TOKEN}
      - APP__APP_LOGS__LOGS_LEVEL=error
      - REDIS__HOSTNAME=redis
      - REDIS__PORT=6379
      - ELASTICSEARCH__URL=http://elasticsearch:9200
      - MINIO__ENDPOINT=minio
      - MINIO__PORT=9000
      - MINIO__USE_SSL=false
      - MINIO__ACCESS_KEY=${MINIO_ROOT_USER}
      - MINIO__SECRET_KEY=${MINIO_ROOT_PASSWORD}
      - RABBITMQ__HOSTNAME=rabbitmq
      - RABBITMQ__PORT=5672
      - RABBITMQ__USERNAME=${RABBITMQ_DEFAULT_USER}
      - RABBITMQ__PASSWORD=${RABBITMQ_DEFAULT_PASS}
      - SMTP__HOSTNAME=${SMTP_HOSTNAME}
      - SMTP__PORT=25
      - PROVIDERS__LOCAL__STRATEGY=LocalStrategy
    ports:
      - "8080:8080"
    depends_on:
      - redis
      - elasticsearch
      - minio
      - rabbitmq
    restart: always
  worker:
    image: filigran/openbas-worker:1.0.0
    environment:
      - OPENBAS_URL=http://openbas:8080
      - OPENBAS_TOKEN=${OPENBAS_ADMIN_TOKEN}
      - WORKER_LOG_LEVEL=error
    depends_on:
      - openbas
    deploy:
      mode: replicated
      replicas: 3
    restart: always
volumes:
  esdata:
  s3data:
  redisdata:
  amqpdata:
EOL

# Create the .env file with default values
cat > ./openbas/.env << 'EOL'
OPENBAS_ADMIN_EMAIL=admin@openbas.io
OPENBAS_ADMIN_PASSWORD=changeme
OPENBAS_ADMIN_TOKEN=$(openssl rand -hex 32)
OPENBAS_BASE_URL=http://localhost:8080
MINIO_ROOT_USER=$(openssl rand -hex 16)
MINIO_ROOT_PASSWORD=$(openssl rand -hex 32)
RABBITMQ_DEFAULT_USER=openbas
RABBITMQ_DEFAULT_PASS=$(openssl rand -hex 32)
SMTP_HOSTNAME=localhost
EOL

echo "OpenBAS installation files created. To start OpenBAS:"
echo "1. Review and modify the .env file in the ./openbas directory if needed"
echo "2. Run 'cd ./openbas && docker-compose up -d'"
echo "3. Access the OpenBAS platform at http://localhost:8080"
echo "4. Login with the credentials specified in the .env file"