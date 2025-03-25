# Asian Blockchain Solution Installation Guide

## Introduction

This installation guide provides step-by-step instructions for setting up the Asian Blockchain Solution platform. The solution is designed for deployment across Southeast Asian markets, supporting real estate transactions, supply chain management, legal contracts, insurance, and bill payments with smart contracts.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Prerequisites](#prerequisites)
3. [Installation Options](#installation-options)
4. [Docker Installation](#docker-installation)
5. [Manual Installation](#manual-installation)
6. [Configuration](#configuration)
7. [Blockchain Network Setup](#blockchain-network-setup)
8. [Database Setup](#database-setup)
9. [API Server Setup](#api-server-setup)
10. [Web Interface Setup](#web-interface-setup)
11. [Mobile App Setup](#mobile-app-setup)
12. [Testing the Installation](#testing-the-installation)
13. [Troubleshooting](#troubleshooting)

## System Requirements

### Minimum Hardware Requirements

- **CPU**: 4 cores
- **RAM**: 8 GB
- **Storage**: 100 GB SSD
- **Network**: 100 Mbps internet connection

### Recommended Hardware Requirements

- **CPU**: 8+ cores
- **RAM**: 16+ GB
- **Storage**: 500+ GB SSD
- **Network**: 1 Gbps internet connection

### Software Requirements

- **Operating System**: Ubuntu 20.04 LTS or later, CentOS 8+, or Debian 11+
- **Docker**: Version 20.10 or later (for Docker installation)
- **Node.js**: Version 16.x or later
- **Go**: Version 1.18 or later
- **PostgreSQL**: Version 13 or later
- **Redis**: Version 6 or later
- **IPFS**: Version 0.12 or later (for decentralized storage)

## Prerequisites

Before installation, ensure you have the following:

1. **Domain Name**: A registered domain name for your installation
2. **SSL Certificate**: Valid SSL certificate for secure communications
3. **Cloud Provider Account**: If deploying to cloud (AWS, Azure, GCP, or regional providers)
4. **Blockchain Node Access**: Access to Ethereum, Binance Smart Chain, or other supported blockchain networks
5. **Payment Gateway Credentials**: API keys for supported payment providers

## Installation Options

The Asian Blockchain Solution can be installed using two methods:

1. **Docker Installation**: Recommended for most users, provides containerized deployment
2. **Manual Installation**: For advanced users who need customized setup

## Docker Installation

### Step 1: Install Docker and Docker Compose

```bash
# Update package index
sudo apt update

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.6.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add your user to the docker group
sudo usermod -aG docker $USER

# Apply changes
newgrp docker
```

### Step 2: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/asianblockchain/solution.git
cd solution

# Checkout the latest stable release
git checkout v1.0.0
```

### Step 3: Configure Environment Variables

```bash
# Copy example environment file
cp .env.example .env

# Edit the environment file with your configuration
nano .env
```

Update the following variables in the `.env` file:

```
# General Configuration
NODE_ENV=production
PORT=3000
API_URL=https://api.yourdomain.com
WEB_URL=https://yourdomain.com

# Database Configuration
DB_HOST=postgres
DB_PORT=5432
DB_NAME=asianblockchain
DB_USER=dbuser
DB_PASSWORD=your_secure_password

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# Blockchain Configuration
BLOCKCHAIN_PROVIDER_URL=https://your-blockchain-provider.com
BLOCKCHAIN_NETWORK_ID=1
CONTRACT_OWNER_PRIVATE_KEY=your_private_key

# Payment Gateway Configuration
PAYMENT_GATEWAY_API_KEY=your_api_key
PAYMENT_GATEWAY_SECRET=your_secret

# JWT Configuration
JWT_SECRET=your_jwt_secret
JWT_EXPIRATION=86400

# IPFS Configuration
IPFS_HOST=ipfs
IPFS_PORT=5001
IPFS_PROTOCOL=http
```

### Step 4: Start the Services

```bash
# Build and start the containers
docker-compose up -d

# Check the status of the containers
docker-compose ps
```

### Step 5: Initialize the Database

```bash
# Run database migrations
docker-compose exec api npm run migrate

# Seed initial data
docker-compose exec api npm run seed
```

### Step 6: Deploy Smart Contracts

```bash
# Deploy smart contracts to the blockchain
docker-compose exec blockchain npm run deploy
```

## Manual Installation

### Step 1: Install System Dependencies

```bash
# Update package index
sudo apt update

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

# Install Go
wget https://go.dev/dl/go1.18.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.18.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
source ~/.profile

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install Redis
sudo apt install -y redis-server

# Install IPFS
wget https://dist.ipfs.io/go-ipfs/v0.12.0/go-ipfs_v0.12.0_linux-amd64.tar.gz
tar -xvzf go-ipfs_v0.12.0_linux-amd64.tar.gz
cd go-ipfs
sudo bash install.sh
cd ..
```

### Step 2: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/asianblockchain/solution.git
cd solution

# Checkout the latest stable release
git checkout v1.0.0
```

### Step 3: Set Up the Database

```bash
# Connect to PostgreSQL
sudo -u postgres psql

# Create database and user
CREATE DATABASE asianblockchain;
CREATE USER dbuser WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE asianblockchain TO dbuser;
\q

# Configure PostgreSQL to allow connections
sudo nano /etc/postgresql/13/main/pg_hba.conf
```

Add the following line to `pg_hba.conf`:
```
host    asianblockchain    dbuser    127.0.0.1/32    md5
```

Restart PostgreSQL:
```bash
sudo systemctl restart postgresql
```

### Step 4: Configure Environment Variables

```bash
# Copy example environment file
cp .env.example .env

# Edit the environment file with your configuration
nano .env
```

Update the environment variables as shown in the Docker installation section.

### Step 5: Install Dependencies and Build

```bash
# Install dependencies for API server
cd api
npm install
npm run build
cd ..

# Install dependencies for blockchain module
cd blockchain
npm install
npm run build
cd ..

# Install dependencies for web interface
cd web
npm install
npm run build
cd ..
```

### Step 6: Set Up Services

```bash
# Set up systemd service for API server
sudo nano /etc/systemd/system/asianblockchain-api.service
```

Add the following content:
```
[Unit]
Description=Asian Blockchain Solution API Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/path/to/solution/api
ExecStart=/usr/bin/npm start
Restart=on-failure
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

```bash
# Set up systemd service for blockchain module
sudo nano /etc/systemd/system/asianblockchain-blockchain.service
```

Add the following content:
```
[Unit]
Description=Asian Blockchain Solution Blockchain Module
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/path/to/solution/blockchain
ExecStart=/usr/bin/npm start
Restart=on-failure
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start the services
sudo systemctl enable asianblockchain-api
sudo systemctl start asianblockchain-api
sudo systemctl enable asianblockchain-blockchain
sudo systemctl start asianblockchain-blockchain
```

### Step 7: Set Up Web Server

```bash
# Install Nginx
sudo apt install -y nginx

# Configure Nginx
sudo nano /etc/nginx/sites-available/asianblockchain
```

Add the following content:
```
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name yourdomain.com;

    ssl_certificate /path/to/ssl/certificate.crt;
    ssl_certificate_key /path/to/ssl/private.key;

    location / {
        root /path/to/solution/web/build;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Enable the site and restart Nginx
sudo ln -s /etc/nginx/sites-available/asianblockchain /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Step 8: Deploy Smart Contracts

```bash
# Deploy smart contracts to the blockchain
cd blockchain
npm run deploy
cd ..
```

## Configuration

### Blockchain Network Configuration

The solution supports multiple blockchain networks. Configure your preferred network in the `.env` file:

```
# Ethereum Mainnet
BLOCKCHAIN_PROVIDER_URL=https://mainnet.infura.io/v3/your-project-id
BLOCKCHAIN_NETWORK_ID=1

# Binance Smart Chain
# BLOCKCHAIN_PROVIDER_URL=https://bsc-dataseed.binance.org/
# BLOCKCHAIN_NETWORK_ID=56

# Polygon
# BLOCKCHAIN_PROVIDER_URL=https://polygon-rpc.com/
# BLOCKCHAIN_NETWORK_ID=137
```

### Jurisdiction-Specific Configuration

Configure jurisdiction-specific settings in the `config/jurisdictions.json` file:

```json
{
  "jurisdictions": [
    {
      "id": 0,
      "code": "MALAYSIA",
      "name": "Malaysia",
      "currencyCode": "MYR",
      "languageCode": "en-MY",
      "paymentProviders": ["MayBank", "CIMB Clicks", "Touch 'n Go", "Boost"],
      "regulatoryAuthorities": ["Securities Commission Malaysia", "Bank Negara Malaysia"],
      "complianceRules": "config/compliance/malaysia.json"
    },
    {
      "id": 1,
      "code": "SINGAPORE",
      "name": "Singapore",
      "currencyCode": "SGD",
      "languageCode": "en-SG",
      "paymentProviders": ["PayNow", "NETS", "GrabPay", "DBS PayLah!"],
      "regulatoryAuthorities": ["Monetary Authority of Singapore", "Singapore Land Authority"],
      "complianceRules": "config/compliance/singapore.json"
    },
    // Additional jurisdictions...
  ]
}
```

### Payment Gateway Configuration

Configure payment gateways in the `config/payment.json` file:

```json
{
  "traditional": {
    "providers": [
      {
        "id": "stripe",
        "name": "Stripe",
        "supportedJurisdictions": [0, 1, 2, 3, 4, 5, 6, 7],
        "apiEndpoint": "https://api.stripe.com/v1",
        "webhookEndpoint": "/webhooks/stripe"
      },
      // Additional providers...
    ]
  },
  "crypto": {
    "providers": [
      {
        "id": "ethereum",
        "name": "Ethereum",
        "blockchain": "ETH",
        "supportedJurisdictions": [0, 1, 2, 3, 4, 5, 6, 7],
        "contractAddress": "0x1234567890123456789012345678901234567890"
      },
      // Additional providers...
    ]
  }
}
```

## Blockchain Network Setup

### Setting Up a Private Blockchain Network

For testing or private deployments, you can set up a private blockchain network:

```bash
# Create a directory for the private network
mkdir -p ~/private-blockchain
cd ~/private-blockchain

# Create a genesis.json file
cat > genesis.json << EOF
{
  "config": {
    "chainId": 12345,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "berlinBlock": 0
  },
  "alloc": {},
  "coinbase": "0x0000000000000000000000000000000000000000",
  "difficulty": "0x400",
  "extraData": "",
  "gasLimit": "0x2fefd8",
  "nonce": "0x0000000000000042",
  "mixhash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "timestamp": "0x00"
}
EOF

# Initialize the blockchain
geth --datadir ./data init genesis.json

# Create an account
geth --datadir ./data account new

# Start the blockchain node
geth --datadir ./data --networkid 12345 --http --http.addr "0.0.0.0" --http.port 8545 --http.corsdomain "*" --http.api "eth,net,web3,personal,miner,admin" --allow-insecure-unlock --mine --miner.threads 1
```

Update your `.env` file to use the private network:

```
BLOCKCHAIN_PROVIDER_URL=http://localhost:8545
BLOCKCHAIN_NETWORK_ID=12345
```

### Connecting to Public Blockchain Networks

For production deployments, connect to public blockchain networks:

1. **Create an account with a blockchain provider** (Infura, Alchemy, etc.)
2. **Get your API key and endpoint URL**
3. **Update your `.env` file** with the provider URL and network ID
4. **Fund your wallet** with the native cryptocurrency for the selected network

## Database Setup

### Database Schema Migration

```bash
# Run database migrations
cd api
npm run migrate

# Seed initial data
npm run seed
```

### Database Backup and Restore

```bash
# Backup the database
pg_dump -U dbuser -d asianblockchain -F c -b -v -f backup.dump

# Restore the database
pg_restore -U dbuser -d asianblockchain -v backup.dump
```

## API Server Setup

### API Server Configuration

Configure the API server in the `api/config/config.js` file:

```javascript
module.exports = {
  server: {
    port: process.env.PORT || 3000,
    cors: {
      origin: process.env.WEB_URL || '*',
      methods: ['GET', 'POST', 'PUT', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization']
    }
  },
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    name: process.env.DB_NAME || 'asianblockchain',
    user: process.env.DB_USER || 'dbuser',
    password: process.env.DB_PASSWORD || 'password'
  },
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || ''
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'default_secret',
    expiresIn: process.env.JWT_EXPIRATION || 86400
  },
  blockchain: {
    providerUrl: process.env.BLOCKCHAIN_PROVIDER_URL,
    networkId: process.env.BLOCKCHAIN_NETWORK_ID,
    contractOwnerPrivateKey: process.env.CONTRACT_OWNER_PRIVATE_KEY
  }
};
```

### API Server Scaling

For high-traffic deployments, set up load balancing:

```bash
# Install PM2 for process management
npm install -g pm2

# Start multiple API server instances
cd api
pm2 start npm --name "api" -i max -- start

# Save the PM2 configuration
pm2 save

# Set up PM2 to start on system boot
pm2 startup
```

## Web Interface Setup

### Web Interface Configuration

Configure the web interface in the `web/.env` file:

```
REACT_APP_API_URL=https://api.yourdomain.com
REACT_APP_BLOCKCHAIN_PROVIDER_URL=https://your-blockchain-provider.com
REACT_APP_IPFS_GATEWAY=https://ipfs.io/ipfs/
```

### Building for Production

```bash
# Build the web interface for production
cd web
npm run build

# The build files will be in the build directory
```

## Mobile App Setup

### Prerequisites

- Node.js 16.x or later
- React Native CLI
- Android Studio (for Android builds)
- Xcode (for iOS builds, macOS only)

### Building the Mobile App

```bash
# Install dependencies
cd mobile
npm install

# For Android
npm run android

# For iOS (macOS only)
npm run ios
```

### Building for Production

```bash
# For Android
cd android
./gradlew assembleRelease

# For iOS (macOS only)
cd ios
xcodebuild -workspace AsianBlockchain.xcworkspace -scheme AsianBlockchain -configuration Release
```

## Testing the Installation

### API Server Test

```bash
# Test the API server
curl -X GET https://api.yourdomain.com/health
```

Expected response:
```json
{
  "status": "ok",
  "version": "1.0.0",
  "timestamp": "2025-03-24T17:00:00Z"
}
```

### Smart Contract Test

```bash
# Test smart contract deployment
cd blockchain
npm run test
```

### Web Interface Test

Open your web browser and navigate to `https://yourdomain.com`. You should see the login page of the Asian Blockchain Solution.

## Troubleshooting

### Common Issues and Solutions

#### Database Connection Issues

**Issue**: Unable to connect to the database

**Solution**:
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Check database logs
sudo tail -f /var/log/postgresql/postgresql-13-main.log

# Ensure the database user has proper permissions
sudo -u postgres psql -c "ALTER USER dbuser WITH PASSWORD 'your_secure_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE asianblockchain TO dbuser;"
```

#### Blockchain Connection Issues

**Issue**: Unable to connect to the blockchain network

**Solution**:
```bash
# Check if the blockchain provider URL is correct
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' https://your-blockchain-provider.com

# Ensure your account has sufficient funds for gas
cd blockchain
node scripts/check-balance.js
```

#### API Server Issues

**Issue**: API server not starting

**Solution**:
```bash
# Check API server logs
sudo journalctl -u asianblockchain-api

# Check if the port is already in use
sudo netstat -tulpn | grep 3000

# Restart the API server
sudo systemctl restart asianblockchain-api
```

#### Web Interface Issues

**Issue**: Web interface not loading

**Solution**:
```bash
# Check Nginx logs
sudo tail -f /var/log/nginx/error.log

# Ensure the build files are in the correct location
ls -la /path/to/solution/web/build

# Check if Nginx is running
sudo systemctl status nginx

# Restart Nginx
sudo systemctl restart nginx
```

### Getting Help

If you encounter issues not covered in this guide, please:

1. Check the [official documentation](https://docs.asianblockchain.example.com)
2. Search the [knowledge base](https://support.asianblockchain.example.com)
3. Contact support at support@asianblockchain.example.com
4. Join the [community forum](https://community.asianblockchain.example.com)
5. Open an issue on the [GitHub repository](https://github.com/asianblockchain/solution/issues)
