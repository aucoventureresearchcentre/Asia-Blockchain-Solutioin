#!/bin/bash

# AsianBlockchainSolution Setup Script
# This script sets up the development environment for the AsianBlockchainSolution project

echo "Setting up AsianBlockchainSolution development environment..."

# Install Node.js dependencies
echo "Installing Node.js dependencies..."
npm install --save truffle @openzeppelin/contracts @openzeppelin/test-helpers web3 solc ganache-cli

# Install Solidity compiler
echo "Installing Solidity compiler..."
npm install -g solc

# Install Truffle framework
echo "Installing Truffle framework..."
npm install -g truffle

# Initialize Truffle project if not already initialized
if [ ! -f "truffle-config.js" ]; then
  echo "Initializing Truffle project..."
  truffle init
fi

# Copy contract files to Truffle contracts directory
echo "Copying contract files to Truffle contracts directory..."
mkdir -p ./truffle/contracts
cp -r ./code/core/contracts/* ./truffle/contracts/
cp -r ./code/core/interfaces/* ./truffle/contracts/
cp -r ./code/applications/* ./truffle/contracts/
cp -r ./code/payment/* ./truffle/contracts/

# Copy test files to Truffle test directory
echo "Copying test files to Truffle test directory..."
mkdir -p ./truffle/test
cp -r ./tests/* ./truffle/test/

# Create migrations
echo "Creating migration files..."
mkdir -p ./truffle/migrations
cat > ./truffle/migrations/1_initial_migration.js << 'EOL'
const Migrations = artifacts.require("Migrations");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
EOL

cat > ./truffle/migrations/2_deploy_core_contracts.js << 'EOL'
const ComplianceRegistry = artifacts.require("ComplianceRegistry");
const AssetRegistry = artifacts.require("AssetRegistry");
const TransactionManager = artifacts.require("TransactionManager");
const DocumentRegistry = artifacts.require("DocumentRegistry");
const PaymentProcessor = artifacts.require("PaymentProcessor");
const JurisdictionRegistry = artifacts.require("JurisdictionRegistry");
const IdentityManager = artifacts.require("IdentityManager");

module.exports = function(deployer) {
  deployer.deploy(ComplianceRegistry)
    .then(() => deployer.deploy(JurisdictionRegistry, ComplianceRegistry.address))
    .then(() => deployer.deploy(AssetRegistry, ComplianceRegistry.address))
    .then(() => deployer.deploy(DocumentRegistry, ComplianceRegistry.address))
    .then(() => deployer.deploy(PaymentProcessor, ComplianceRegistry.address))
    .then(() => deployer.deploy(IdentityManager, ComplianceRegistry.address))
    .then(() => deployer.deploy(TransactionManager, 
      ComplianceRegistry.address,
      AssetRegistry.address,
      DocumentRegistry.address,
      PaymentProcessor.address
    ));
};
EOL

cat > ./truffle/migrations/3_deploy_application_contracts.js << 'EOL'
const ComplianceRegistry = artifacts.require("ComplianceRegistry");
const AssetRegistry = artifacts.require("AssetRegistry");
const DocumentRegistry = artifacts.require("DocumentRegistry");
const PaymentProcessor = artifacts.require("PaymentProcessor");
const TransactionManager = artifacts.require("TransactionManager");

// Real Estate
const RealEstateToken = artifacts.require("RealEstateToken");
const RealEstateTransaction = artifacts.require("RealEstateTransaction");

// Supply Chain
const SupplyChainItem = artifacts.require("SupplyChainItem");
const SupplyChainTracker = artifacts.require("SupplyChainTracker");

// Legal Contracts
const LegalContractTemplate = artifacts.require("LegalContractTemplate");
const LegalContractExecution = artifacts.require("LegalContractExecution");

// Insurance
const InsurancePolicy = artifacts.require("InsurancePolicy");
const InsuranceClaims = artifacts.require("InsuranceClaims");

// Bill Payments
const BillPayment = artifacts.require("BillPayment");
const RecurringPayment = artifacts.require("RecurringPayment");

module.exports = function(deployer) {
  // Deploy Real Estate contracts
  deployer.deploy(RealEstateToken, ComplianceRegistry.address, AssetRegistry.address)
    .then(() => deployer.deploy(RealEstateTransaction, 
      ComplianceRegistry.address,
      AssetRegistry.address,
      DocumentRegistry.address,
      PaymentProcessor.address,
      RealEstateToken.address
    ))
    
    // Deploy Supply Chain contracts
    .then(() => deployer.deploy(SupplyChainItem, ComplianceRegistry.address, AssetRegistry.address))
    .then(() => deployer.deploy(SupplyChainTracker,
      ComplianceRegistry.address,
      AssetRegistry.address,
      DocumentRegistry.address,
      SupplyChainItem.address
    ))
    
    // Deploy Legal Contract contracts
    .then(() => deployer.deploy(LegalContractTemplate, ComplianceRegistry.address, DocumentRegistry.address))
    .then(() => deployer.deploy(LegalContractExecution,
      ComplianceRegistry.address,
      DocumentRegistry.address,
      PaymentProcessor.address,
      LegalContractTemplate.address
    ))
    
    // Deploy Insurance contracts
    .then(() => deployer.deploy(InsurancePolicy, ComplianceRegistry.address, AssetRegistry.address))
    .then(() => deployer.deploy(InsuranceClaims,
      ComplianceRegistry.address,
      AssetRegistry.address,
      InsurancePolicy.address
    ))
    
    // Deploy Bill Payment contracts
    .then(() => deployer.deploy(BillPayment, ComplianceRegistry.address, PaymentProcessor.address))
    .then(() => deployer.deploy(RecurringPayment,
      ComplianceRegistry.address,
      PaymentProcessor.address,
      BillPayment.address
    ));
};
EOL

cat > ./truffle/migrations/4_deploy_payment_contracts.js << 'EOL'
const ComplianceRegistry = artifacts.require("ComplianceRegistry");
const PaymentProcessor = artifacts.require("PaymentProcessor");
const TraditionalPaymentProcessor = artifacts.require("TraditionalPaymentProcessor");
const CryptoPaymentProcessor = artifacts.require("CryptoPaymentProcessor");
const PaymentGateway = artifacts.require("PaymentGateway");

module.exports = function(deployer) {
  deployer.deploy(TraditionalPaymentProcessor, ComplianceRegistry.address, PaymentProcessor.address)
    .then(() => deployer.deploy(CryptoPaymentProcessor, ComplianceRegistry.address, PaymentProcessor.address))
    .then(() => deployer.deploy(PaymentGateway,
      ComplianceRegistry.address,
      PaymentProcessor.address,
      TraditionalPaymentProcessor.address,
      CryptoPaymentProcessor.address
    ));
};
EOL

# Update truffle-config.js
cat > ./truffle-config.js << 'EOL'
module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    }
  },
  compilers: {
    solc: {
      version: "0.8.17",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
};
EOL

echo "Creating database setup script..."
cat > ./scripts/setup_database.js << 'EOL'
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');

// Load database schema from schema file
const schemaPath = path.join(__dirname, '../docs/technical/database_schema.md');
const schemaContent = fs.readFileSync(schemaPath, 'utf8');

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/asianblockchain', {
  useNewUrlParser: true,
  useUnifiedTopology: true
}).then(() => {
  console.log('Connected to MongoDB');
  
  // Create collections based on schema
  console.log('Creating database collections...');
  
  // Parse schema content and create collections
  // This is a simplified implementation - in production, you would parse the schema file
  // and create the appropriate MongoDB schemas and models
  
  console.log('Database setup complete');
  mongoose.disconnect();
}).catch(err => {
  console.error('Error connecting to MongoDB:', err);
});
EOL

echo "Creating API server setup script..."
cat > ./scripts/setup_api_server.js << 'EOL'
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

// Load API documentation
const apiDocsPath = path.join(__dirname, '../docs/api/api_documentation.md');
const apiDocs = fs.readFileSync(apiDocsPath, 'utf8');

// Create Express app
const app = express();
app.use(cors());
app.use(bodyParser.json());

// API routes would be defined here based on the API documentation
// This is a simplified implementation - in production, you would parse the API docs
// and create the appropriate routes and handlers

// Documentation endpoint
app.get('/api/docs', (req, res) => {
  res.send(apiDocs);
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`API server running on port ${PORT}`);
});
EOL

echo "Creating deployment script..."
cat > ./scripts/deploy.sh << 'EOL'
#!/bin/bash

# AsianBlockchainSolution Deployment Script
# This script deploys the AsianBlockchainSolution to a production environment

echo "Deploying AsianBlockchainSolution..."

# Check if environment is specified
if [ -z "$1" ]; then
  echo "Usage: ./deploy.sh [environment]"
  echo "Available environments: development, staging, production"
  exit 1
fi

ENVIRONMENT=$1

# Load environment-specific configuration
if [ -f "./config/${ENVIRONMENT}.json" ]; then
  echo "Loading ${ENVIRONMENT} configuration..."
else
  echo "Error: Configuration file for ${ENVIRONMENT} not found"
  exit 1
fi

# Deploy smart contracts
echo "Deploying smart contracts to ${ENVIRONMENT} blockchain network..."
truffle migrate --network ${ENVIRONMENT}

# Deploy API server
echo "Deploying API server..."
if [ "${ENVIRONMENT}" == "production" ]; then
  # Production deployment steps
  pm2 start ./scripts/setup_api_server.js --name "asianblockchain-api"
else
  # Development/staging deployment steps
  node ./scripts/setup_api_server.js
fi

# Deploy frontend (if applicable)
if [ -d "./frontend" ]; then
  echo "Deploying frontend application..."
  if [ "${ENVIRONMENT}" == "production" ]; then
    # Production frontend deployment
    cd ./frontend && npm run build && cd ..
    # Copy build files to web server
  else
    # Development/staging frontend deployment
    cd ./frontend && npm start && cd ..
  fi
fi

echo "Deployment to ${ENVIRONMENT} completed successfully"
EOL

# Make scripts executable
chmod +x ./scripts/*.sh

echo "Setup complete! You can now run the following commands:"
echo "  - To compile contracts: truffle compile"
echo "  - To run tests: truffle test"
echo "  - To deploy contracts: truffle migrate"
echo "  - To deploy the full solution: ./scripts/deploy.sh [environment]"
