#!/bin/bash

# Script for setting up fresh BTPI CTI environment including Vault

# Print section headers
print_header() {
    echo
    echo "===== $1 ====="
    echo
}

print_header "Updating system packages"
apt-get update
apt upgrade -y

print_header "Installing base dependencies"
apt-get install -y jython
apt-get install -y python3-pip
apt-get install -y python-is-python3
apt-get install -y python3-virtualenv
apt-get install -y git
apt-get install -y containerd
apt-get install -y ca-certificates
apt-get install -y certbot
apt-get install -y curl
apt-get install -y gnupg
apt-get install -y lsb-release
apt-get install -y snapd
apt-get install -y npm
apt-get install -y default-jdk
apt-get install -y gccgo-go
apt-get install -y golang-go
apt-get install -y jq
apt-get install -y unzip

# Install HashiCorp Vault dependencies
print_header "Installing HashiCorp Vault dependencies"
apt-get install -y gpg

# Install Python packages including hvac (HashiCorp Vault client)
print_header "Installing Python packages"
pip install hvac
pip install python-dotenv
pip install requests

print_header "Removing conflicting Docker packages"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
done

print_header "Adding Docker's official GPG key"
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

print_header "Adding the repository to Apt sources"
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y

print_header "Installing the latest Docker version"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install HashiCorp Vault
print_header "Installing HashiCorp Vault"
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y vault

# Setup Vault development server for local development
print_header "Setting up Vault development environment"
mkdir -p ~/vault
cat > ~/vault/docker-compose.yml << EOF
version: '3.8'
services:
  vault:
    image: hashicorp/vault:latest
    container_name: vault-dev
    ports:
      - "8200:8200"
    environment:
      - VAULT_DEV_ROOT_TOKEN_ID=dev-only-token
      - VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200
    cap_add:
      - IPC_LOCK
    command: server -dev
EOF

print_header "BTPI-CTI setup with Vault integration complete"
echo "To start Vault development server:"
echo "  cd ~/vault && docker-compose up -d"
echo "To access Vault UI:"
echo "  http://localhost:8200"
echo "  Root Token: dev-only-token"
echo "To initialize with Python:"
echo "  import hvac"
echo "  client = hvac.Client(url='http://localhost:8200', token='dev-only-token')"
