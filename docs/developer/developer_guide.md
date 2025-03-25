# Asian Blockchain Solution Developer Guide

## Introduction

This developer guide provides comprehensive information for developers who want to extend, customize, or integrate with the Asian Blockchain Solution platform. The solution is designed for Southeast Asian markets, supporting real estate transactions, supply chain management, legal contracts, insurance, and bill payments with smart contracts.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Development Environment Setup](#development-environment-setup)
3. [Core Components](#core-components)
4. [Smart Contract Development](#smart-contract-development)
5. [API Development](#api-development)
6. [Frontend Development](#frontend-development)
7. [Mobile App Development](#mobile-app-development)
8. [Testing Framework](#testing-framework)
9. [Deployment Pipeline](#deployment-pipeline)
10. [Extending the Platform](#extending-the-platform)
11. [Integration Guidelines](#integration-guidelines)
12. [Security Best Practices](#security-best-practices)
13. [Compliance Integration](#compliance-integration)
14. [Contributing Guidelines](#contributing-guidelines)

## Architecture Overview

The Asian Blockchain Solution follows a modular, layered architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                      Client Applications                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Web App    │  │ Mobile App  │  │ Third-party Systems │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                         API Layer                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  REST API   │  │ GraphQL API │  │     Webhooks        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                      Service Layer                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Real Estate │  │Supply Chain │  │  Legal Contracts    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Insurance  │  │Bill Payments│  │  Payment Processing │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                      Core Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Compliance  │  │   Asset     │  │    Transaction      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Document   │  │  Payment    │  │    Identity         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                   Infrastructure Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Blockchain  │  │  Database   │  │       Cache         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │    IPFS     │  │   Message   │  │     Monitoring      │  │
│  │             │  │   Queue     │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

1. **Client Applications**: Web app, mobile app, and third-party integrations
2. **API Layer**: REST API, GraphQL API, and webhooks for external integrations
3. **Service Layer**: Application-specific business logic modules
4. **Core Layer**: Shared core functionality used across all applications
5. **Infrastructure Layer**: Blockchain, database, cache, IPFS, message queue, and monitoring

### Technology Stack

- **Blockchain**: Ethereum, Binance Smart Chain, Polygon
- **Smart Contracts**: Solidity
- **Backend**: Node.js, Express
- **Database**: PostgreSQL
- **Cache**: Redis
- **Storage**: IPFS
- **Frontend**: React, Material-UI
- **Mobile**: React Native
- **API**: REST, GraphQL
- **Message Queue**: RabbitMQ
- **Monitoring**: Prometheus, Grafana

## Development Environment Setup

### Prerequisites

- Node.js 16.x or later
- npm 8.x or later
- Docker and Docker Compose
- Git
- Solidity compiler 0.8.x
- Truffle or Hardhat
- PostgreSQL 13 or later
- Redis 6 or later

### Setting Up the Development Environment

1. **Clone the repository**

```bash
git clone https://github.com/asianblockchain/solution.git
cd solution
```

2. **Install dependencies**

```bash
# Install root dependencies
npm install

# Install API dependencies
cd api
npm install
cd ..

# Install blockchain module dependencies
cd blockchain
npm install
cd ..

# Install web app dependencies
cd web
npm install
cd ..

# Install mobile app dependencies
cd mobile
npm install
cd ..
```

3. **Set up environment variables**

```bash
# Copy example environment files
cp .env.example .env
cp api/.env.example api/.env
cp blockchain/.env.example blockchain/.env
cp web/.env.example web/.env
cp mobile/.env.example mobile/.env
```

Edit each `.env` file to configure your development environment.

4. **Start development services with Docker**

```bash
docker-compose -f docker-compose.dev.yml up -d
```

5. **Run database migrations**

```bash
cd api
npm run migrate:dev
npm run seed:dev
cd ..
```

6. **Start development servers**

```bash
# Start API server
cd api
npm run dev
cd ..

# Start blockchain development
cd blockchain
npm run dev
cd ..

# Start web app
cd web
npm start
cd ..

# Start mobile app
cd mobile
npm start
cd ..
```

### Development Tools

- **VS Code Extensions**:
  - Solidity
  - ESLint
  - Prettier
  - Docker
  - PostgreSQL

- **Browser Extensions**:
  - MetaMask
  - React Developer Tools
  - Redux DevTools

- **Testing Tools**:
  - Mocha
  - Chai
  - Jest
  - Cypress
  - Truffle/Hardhat Test

## Core Components

### Compliance Module

The Compliance module ensures all operations comply with the legal requirements of each jurisdiction.

**Key Files**:
- `blockchain/contracts/core/interfaces/ICompliance.sol`
- `blockchain/contracts/core/contracts/ComplianceRegistry.sol`
- `api/src/services/compliance.service.js`

**Usage Example**:

```javascript
// Check if an operation is compliant
const complianceService = require('../services/compliance.service');

const isCompliant = await complianceService.checkCompliance({
  jurisdiction: 'SINGAPORE',
  operationType: 'REAL_ESTATE_TRANSFER',
  operationData: {
    propertyId: 'prop123',
    buyerId: 'user456',
    sellerId: 'user789',
    amount: 1000000,
    currency: 'SGD'
  }
});

if (isCompliant.status) {
  // Proceed with the operation
} else {
  // Handle compliance failure
  console.error(`Compliance check failed: ${isCompliant.reason}`);
}
```

### Asset Registry

The Asset Registry manages all assets in the system, including real estate properties, supply chain items, and documents.

**Key Files**:
- `blockchain/contracts/core/interfaces/IAsset.sol`
- `blockchain/contracts/core/contracts/AssetRegistry.sol`
- `api/src/services/asset.service.js`

**Usage Example**:

```javascript
// Register a new asset
const assetService = require('../services/asset.service');

const asset = await assetService.registerAsset({
  assetType: 'REAL_ESTATE',
  owner: 'user123',
  assetData: {
    title: 'Luxury Condo',
    location: 'Singapore',
    size: 120,
    bedrooms: 3,
    bathrooms: 2
  },
  jurisdiction: 'SINGAPORE'
});

console.log(`Asset registered with ID: ${asset.id}`);
```

### Transaction Manager

The Transaction Manager handles all transactions in the system, ensuring they are properly recorded and executed.

**Key Files**:
- `blockchain/contracts/core/interfaces/ITransaction.sol`
- `blockchain/contracts/core/contracts/TransactionManager.sol`
- `api/src/services/transaction.service.js`

**Usage Example**:

```javascript
// Create a new transaction
const transactionService = require('../services/transaction.service');

const transaction = await transactionService.createTransaction({
  from: 'user123',
  to: 'user456',
  assetId: 'asset789',
  amount: 1000000,
  currency: 'SGD',
  transactionData: {
    type: 'REAL_ESTATE_PURCHASE',
    paymentMethod: 'BANK_TRANSFER',
    description: 'Purchase of Luxury Condo'
  },
  jurisdiction: 'SINGAPORE'
});

console.log(`Transaction created with ID: ${transaction.id}`);
```

### Document Registry

The Document Registry manages all documents in the system, including contracts, certificates, and invoices.

**Key Files**:
- `blockchain/contracts/core/interfaces/IDocument.sol`
- `blockchain/contracts/core/contracts/DocumentRegistry.sol`
- `api/src/services/document.service.js`

**Usage Example**:

```javascript
// Create a new document
const documentService = require('../services/document.service');

const document = await documentService.createDocument({
  documentType: 'CONTRACT',
  documentURI: 'ipfs://QmXgm5QVTy8pRtKrTPmoMALxK3A7H3FQzJSkpdyNNRYJnf',
  documentHash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
  signatories: ['user123', 'user456'],
  documentData: {
    title: 'Service Agreement',
    description: 'IT services agreement',
    effectiveDate: '2025-04-01T00:00:00Z',
    expirationDate: '2026-03-31T23:59:59Z'
  },
  jurisdiction: 'SINGAPORE'
});

console.log(`Document created with ID: ${document.id}`);
```

### Payment Processor

The Payment Processor handles all payment operations, supporting both traditional and cryptocurrency payments.

**Key Files**:
- `blockchain/contracts/core/interfaces/IPayment.sol`
- `blockchain/contracts/core/contracts/PaymentProcessor.sol`
- `api/src/services/payment.service.js`

**Usage Example**:

```javascript
// Process a payment
const paymentService = require('../services/payment.service');

const payment = await paymentService.processPayment({
  payer: 'user123',
  payee: 'user456',
  amount: 1000,
  currency: 'SGD',
  paymentMethod: {
    type: 'TRADITIONAL',
    provider: 'CREDIT_CARD',
    data: {
      cardNumber: '4111111111111111',
      expiryMonth: '12',
      expiryYear: '2027',
      cvv: '123'
    }
  },
  description: 'Payment for services',
  metadata: {
    orderId: 'order123',
    invoiceNumber: 'INV-2025-001'
  }
});

console.log(`Payment processed with ID: ${payment.id}`);
```

## Smart Contract Development

### Smart Contract Structure

The smart contracts are organized into the following directories:

- `contracts/core/interfaces`: Core interfaces
- `contracts/core/contracts`: Core contract implementations
- `contracts/core/libraries`: Shared libraries
- `contracts/applications`: Application-specific contracts
- `contracts/payment`: Payment-related contracts

### Creating a New Smart Contract

1. **Create the interface**

```solidity
// contracts/core/interfaces/IMyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMyContract {
    function myFunction(uint256 param1, string calldata param2) external returns (bool);
    function myViewFunction(uint256 param) external view returns (string memory);
}
```

2. **Implement the contract**

```solidity
// contracts/core/contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IMyContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyContract is IMyContract, Ownable {
    mapping(uint256 => string) private _data;
    
    function myFunction(uint256 param1, string calldata param2) external override returns (bool) {
        _data[param1] = param2;
        return true;
    }
    
    function myViewFunction(uint256 param) external view override returns (string memory) {
        return _data[param];
    }
}
```

3. **Create a migration script**

```javascript
// migrations/X_deploy_my_contract.js
const MyContract = artifacts.require("MyContract");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(MyContract);
};
```

4. **Create tests**

```javascript
// test/MyContract.test.js
const MyContract = artifacts.require("MyContract");

contract("MyContract", accounts => {
  let myContract;
  
  beforeEach(async () => {
    myContract = await MyContract.new();
  });
  
  it("should store and retrieve data", async () => {
    const param1 = 123;
    const param2 = "test data";
    
    await myContract.myFunction(param1, param2);
    const result = await myContract.myViewFunction(param1);
    
    assert.equal(result, param2, "Data was not stored correctly");
  });
});
```

### Smart Contract Best Practices

1. **Security**
   - Use OpenZeppelin contracts for standard functionality
   - Follow the Checks-Effects-Interactions pattern
   - Avoid reentrancy vulnerabilities
   - Use SafeMath for arithmetic operations
   - Implement proper access control

2. **Gas Optimization**
   - Minimize on-chain storage
   - Use events for logging
   - Batch operations when possible
   - Use view and pure functions when appropriate
   - Optimize data types (uint256 is more efficient than uint8)

3. **Maintainability**
   - Use modular design
   - Implement upgradeable contracts when needed
   - Document code with NatSpec comments
   - Use consistent naming conventions
   - Write comprehensive tests

## API Development

### API Structure

The API follows a modular structure:

- `src/controllers`: Request handlers
- `src/services`: Business logic
- `src/models`: Data models
- `src/middlewares`: Request/response middlewares
- `src/routes`: API route definitions
- `src/utils`: Utility functions
- `src/config`: Configuration files

### Creating a New API Endpoint

1. **Create a model**

```javascript
// src/models/myModel.js
const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const MyModel = sequelize.define('MyModel', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM('active', 'inactive'),
    defaultValue: 'active'
  },
  createdAt: {
    type: DataTypes.DATE,
    allowNull: false
  },
  updatedAt: {
    type: DataTypes.DATE,
    allowNull: false
  }
});

module.exports = MyModel;
```

2. **Create a service**

```javascript
// src/services/myService.js
const MyModel = require('../models/myModel');
const { NotFoundError, ValidationError } = require('../utils/errors');

class MyService {
  async create(data) {
    return await MyModel.create(data);
  }
  
  async findAll(options = {}) {
    return await MyModel.findAll(options);
  }
  
  async findById(id) {
    const item = await MyModel.findByPk(id);
    if (!item) {
      throw new NotFoundError(`Item with ID ${id} not found`);
    }
    return item;
  }
  
  async update(id, data) {
    const item = await this.findById(id);
    return await item.update(data);
  }
  
  async delete(id) {
    const item = await this.findById(id);
    await item.destroy();
    return { success: true };
  }
}

module.exports = new MyService();
```

3. **Create a controller**

```javascript
// src/controllers/myController.js
const myService = require('../services/myService');
const { asyncHandler } = require('../middlewares/asyncHandler');

exports.create = asyncHandler(async (req, res) => {
  const item = await myService.create(req.body);
  res.status(201).json({
    success: true,
    data: item
  });
});

exports.getAll = asyncHandler(async (req, res) => {
  const items = await myService.findAll();
  res.status(200).json({
    success: true,
    data: items
  });
});

exports.getById = asyncHandler(async (req, res) => {
  const item = await myService.findById(req.params.id);
  res.status(200).json({
    success: true,
    data: item
  });
});

exports.update = asyncHandler(async (req, res) => {
  const item = await myService.update(req.params.id, req.body);
  res.status(200).json({
    success: true,
    data: item
  });
});

exports.delete = asyncHandler(async (req, res) => {
  const result = await myService.delete(req.params.id);
  res.status(200).json({
    success: true,
    data: result
  });
});
```

4. **Create routes**

```javascript
// src/routes/myRoutes.js
const express = require('express');
const router = express.Router();
const myController = require('../controllers/myController');
const { authenticate } = require('../middlewares/auth');
const { validate } = require('../middlewares/validate');
const { myValidationSchema } = require('../validations/myValidation');

router.post('/', authenticate, validate(myValidationSchema), myController.create);
router.get('/', authenticate, myController.getAll);
router.get('/:id', authenticate, myController.getById);
router.put('/:id', authenticate, validate(myValidationSchema), myController.update);
router.delete('/:id', authenticate, myController.delete);

module.exports = router;
```

5. **Register the routes**

```javascript
// src/routes/index.js
const express = require('express');
const router = express.Router();
const myRoutes = require('./myRoutes');

router.use('/api/my-resource', myRoutes);

module.exports = router;
```

### API Best Practices

1. **Security**
   - Use authentication and authorization
   - Validate and sanitize all inputs
   - Implement rate limiting
   - Use HTTPS
   - Set proper CORS headers

2. **Performance**
   - Use caching
   - Paginate large result sets
   - Optimize database queries
   - Use connection pooling
   - Implement request timeout handling

3. **Documentation**
   - Use OpenAPI/Swagger for API documentation
   - Document all endpoints, parameters, and responses
   - Include examples
   - Document error codes and messages

## Frontend Development

### Web App Structure

The web app follows a modular structure:

- `src/components`: Reusable UI components
- `src/pages`: Page components
- `src/services`: API service clients
- `src/hooks`: Custom React hooks
- `src/context`: React context providers
- `src/utils`: Utility functions
- `src/assets`: Static assets
- `src/styles`: Global styles

### Creating a New Page

1. **Create a new page component**

```jsx
// src/pages/MyPage/index.jsx
import React, { useState, useEffect } from 'react';
import { Container, Typography, Button, Grid } from '@mui/material';
import { MyService } from '../../services/myService';
import { MyComponent } from '../../components/MyComponent';
import { useAuth } from '../../hooks/useAuth';
import './styles.css';

const MyPage = () => {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const { user } = useAuth();
  
  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const response = await MyService.getAll();
        setItems(response.data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    
    fetchData();
  }, []);
  
  const handleAddItem = async () => {
    // Implementation
  };
  
  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;
  
  return (
    <Container className="my-page">
      <Typography variant="h4" component="h1">My Page</Typography>
      <Button variant="contained" color="primary" onClick={handleAddItem}>
        Add Item
      </Button>
      <Grid container spacing={3}>
        {items.map(item => (
          <Grid item xs={12} sm={6} md={4} key={item.id}>
            <MyComponent item={item} />
          </Grid>
        ))}
      </Grid>
    </Container>
  );
};

export default MyPage;
```

2. **Create a service for API calls**

```javascript
// src/services/myService.js
import api from './api';

export const MyService = {
  getAll: () => api.get('/api/my-resource'),
  getById: (id) => api.get(`/api/my-resource/${id}`),
  create: (data) => api.post('/api/my-resource', data),
  update: (id, data) => api.put(`/api/my-resource/${id}`, data),
  delete: (id) => api.delete(`/api/my-resource/${id}`)
};
```

3. **Add the page to the router**

```jsx
// src/App.jsx
import React from 'react';
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import PrivateRoute from './components/PrivateRoute';
import Layout from './components/Layout';
import HomePage from './pages/HomePage';
import LoginPage from './pages/LoginPage';
import MyPage from './pages/MyPage';

const App = () => {
  return (
    <AuthProvider>
      <Router>
        <Layout>
          <Switch>
            <Route exact path="/" component={HomePage} />
            <Route path="/login" component={LoginPage} />
            <PrivateRoute path="/my-page" component={MyPage} />
          </Switch>
        </Layout>
      </Router>
    </AuthProvider>
  );
};

export default App;
```

### Frontend Best Practices

1. **Performance**
   - Use code splitting
   - Implement lazy loading
   - Optimize images and assets
   - Minimize bundle size
   - Use memoization for expensive calculations

2. **User Experience**
   - Implement responsive design
   - Add loading indicators
   - Handle errors gracefully
   - Use consistent UI patterns
   - Implement accessibility features

3. **State Management**
   - Use React Context for global state
   - Use local state for component-specific state
   - Consider Redux for complex state management
   - Implement optimistic UI updates
   - Use proper form state management

## Mobile App Development

### Mobile App Structure

The mobile app follows a similar structure to the web app:

- `src/components`: Reusable UI components
- `src/screens`: Screen components
- `src/services`: API service clients
- `src/hooks`: Custom React hooks
- `src/context`: React context providers
- `src/utils`: Utility functions
- `src/assets`: Static assets
- `src/styles`: Global styles

### Creating a New Screen

1. **Create a new screen component**

```jsx
// src/screens/MyScreen/index.jsx
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity } from 'react-native';
import { MyService } from '../../services/myService';
import { MyComponent } from '../../components/MyComponent';
import { useAuth } from '../../hooks/useAuth';

const MyScreen = ({ navigation }) => {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const { user } = useAuth();
  
  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const response = await MyService.getAll();
        setItems(response.data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    
    fetchData();
  }, []);
  
  const handleAddItem = () => {
    navigation.navigate('AddItem');
  };
  
  if (loading) return <View style={styles.center}><Text>Loading...</Text></View>;
  if (error) return <View style={styles.center}><Text>Error: {error}</Text></View>;
  
  return (
    <View style={styles.container}>
      <Text style={styles.title}>My Screen</Text>
      <TouchableOpacity style={styles.button} onPress={handleAddItem}>
        <Text style={styles.buttonText}>Add Item</Text>
      </TouchableOpacity>
      <FlatList
        data={items}
        keyExtractor={item => item.id}
        renderItem={({ item }) => <MyComponent item={item} />}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center'
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 16
  },
  button: {
    backgroundColor: '#2196F3',
    padding: 12,
    borderRadius: 4,
    marginBottom: 16
  },
  buttonText: {
    color: 'white',
    textAlign: 'center',
    fontWeight: 'bold'
  }
});

export default MyScreen;
```

2. **Add the screen to the navigator**

```jsx
// src/navigation/AppNavigator.jsx
import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { NavigationContainer } from '@react-navigation/native';
import { AuthProvider } from '../context/AuthContext';
import { useAuth } from '../hooks/useAuth';
import HomeScreen from '../screens/HomeScreen';
import LoginScreen from '../screens/LoginScreen';
import MyScreen from '../screens/MyScreen';
import AddItemScreen from '../screens/AddItemScreen';

const Stack = createStackNavigator();
const Tab = createBottomTabNavigator();

const MainNavigator = () => {
  return (
    <Tab.Navigator>
      <Tab.Screen name="Home" component={HomeScreen} />
      <Tab.Screen name="MyScreen" component={MyScreen} />
    </Tab.Navigator>
  );
};

const AppNavigator = () => {
  const { user, loading } = useAuth();
  
  if (loading) {
    return <LoadingScreen />;
  }
  
  return (
    <NavigationContainer>
      <Stack.Navigator>
        {user ? (
          <>
            <Stack.Screen name="Main" component={MainNavigator} options={{ headerShown: false }} />
            <Stack.Screen name="AddItem" component={AddItemScreen} />
          </>
        ) : (
          <Stack.Screen name="Login" component={LoginScreen} options={{ headerShown: false }} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default () => (
  <AuthProvider>
    <AppNavigator />
  </AuthProvider>
);
```

### Mobile App Best Practices

1. **Performance**
   - Minimize re-renders
   - Use FlatList for long lists
   - Implement lazy loading
   - Optimize images
   - Use native modules for intensive tasks

2. **User Experience**
   - Follow platform-specific design guidelines
   - Implement smooth animations
   - Handle different screen sizes
   - Support offline mode
   - Implement deep linking

3. **State Management**
   - Use React Context for global state
   - Consider Redux for complex state management
   - Use AsyncStorage for persistent storage
   - Implement proper form state management
   - Handle app state changes

## Testing Framework

### Unit Testing

Unit tests focus on testing individual components or functions in isolation.

**Example Unit Test for a Service**:

```javascript
// test/unit/services/myService.test.js
const { expect } = require('chai');
const sinon = require('sinon');
const MyModel = require('../../../src/models/myModel');
const myService = require('../../../src/services/myService');

describe('MyService', () => {
  let sandbox;
  
  beforeEach(() => {
    sandbox = sinon.createSandbox();
  });
  
  afterEach(() => {
    sandbox.restore();
  });
  
  describe('create', () => {
    it('should create a new item', async () => {
      const mockData = { name: 'Test Item', description: 'Test Description' };
      const mockResult = { id: '123', ...mockData };
      
      sandbox.stub(MyModel, 'create').resolves(mockResult);
      
      const result = await myService.create(mockData);
      
      expect(result).to.deep.equal(mockResult);
      expect(MyModel.create.calledOnceWith(mockData)).to.be.true;
    });
  });
  
  describe('findById', () => {
    it('should return an item when found', async () => {
      const mockId = '123';
      const mockResult = { id: mockId, name: 'Test Item' };
      
      sandbox.stub(MyModel, 'findByPk').resolves(mockResult);
      
      const result = await myService.findById(mockId);
      
      expect(result).to.deep.equal(mockResult);
      expect(MyModel.findByPk.calledOnceWith(mockId)).to.be.true;
    });
    
    it('should throw NotFoundError when item not found', async () => {
      const mockId = '123';
      
      sandbox.stub(MyModel, 'findByPk').resolves(null);
      
      try {
        await myService.findById(mockId);
        expect.fail('Should have thrown an error');
      } catch (error) {
        expect(error.name).to.equal('NotFoundError');
        expect(error.message).to.include(mockId);
      }
    });
  });
});
```

### Integration Testing

Integration tests focus on testing the interaction between different components.

**Example Integration Test for an API Endpoint**:

```javascript
// test/integration/api/myResource.test.js
const request = require('supertest');
const { expect } = require('chai');
const app = require('../../../src/app');
const MyModel = require('../../../src/models/myModel');
const { generateToken } = require('../../helpers/auth');

describe('My Resource API', () => {
  let token;
  let testItem;
  
  before(async () => {
    // Create a test user and generate a token
    token = generateToken({ id: 'user123', role: 'admin' });
    
    // Create a test item
    testItem = await MyModel.create({
      name: 'Test Item',
      description: 'Test Description',
      status: 'active'
    });
  });
  
  after(async () => {
    // Clean up
    await MyModel.destroy({ where: {} });
  });
  
  describe('GET /api/my-resource', () => {
    it('should return all items', async () => {
      const response = await request(app)
        .get('/api/my-resource')
        .set('Authorization', `Bearer ${token}`);
      
      expect(response.status).to.equal(200);
      expect(response.body.success).to.be.true;
      expect(response.body.data).to.be.an('array');
      expect(response.body.data.length).to.be.at.least(1);
    });
    
    it('should return 401 if not authenticated', async () => {
      const response = await request(app)
        .get('/api/my-resource');
      
      expect(response.status).to.equal(401);
    });
  });
  
  describe('GET /api/my-resource/:id', () => {
    it('should return a single item', async () => {
      const response = await request(app)
        .get(`/api/my-resource/${testItem.id}`)
        .set('Authorization', `Bearer ${token}`);
      
      expect(response.status).to.equal(200);
      expect(response.body.success).to.be.true;
      expect(response.body.data.id).to.equal(testItem.id);
      expect(response.body.data.name).to.equal(testItem.name);
    });
    
    it('should return 404 for non-existent item', async () => {
      const response = await request(app)
        .get('/api/my-resource/non-existent-id')
        .set('Authorization', `Bearer ${token}`);
      
      expect(response.status).to.equal(404);
    });
  });
});
```

### Smart Contract Testing

Smart contract tests focus on testing the functionality and security of smart contracts.

**Example Smart Contract Test**:

```javascript
// test/RealEstateToken.test.js
const RealEstateToken = artifacts.require("RealEstateToken");
const ComplianceRegistry = artifacts.require("ComplianceRegistry");
const { expectRevert } = require('@openzeppelin/test-helpers');

contract("RealEstateToken", accounts => {
  const [owner, user1, user2] = accounts;
  let realEstateToken;
  let complianceRegistry;
  
  beforeEach(async () => {
    complianceRegistry = await ComplianceRegistry.new();
    realEstateToken = await RealEstateToken.new(complianceRegistry.address);
  });
  
  describe("tokenizeProperty", () => {
    it("should tokenize a property", async () => {
      const propertyData = web3.eth.abi.encodeParameter(
        'tuple(string,string,tuple(string,string,string,tuple(string,string)),tuple(uint256,string,uint256,uint256,uint256))',
        [
          "Luxury Condo",
          "Beautiful condo with sea view",
          [
            "123 Beach Road",
            "Singapore",
            "Singapore",
            ["1.3036", "103.8318"]
          ],
          [120, "sqm", 3, 2, 2020]
        ]
      );
      
      const jurisdiction = 1; // SINGAPORE
      
      const tx = await realEstateToken.tokenizeProperty(user1, propertyData, jurisdiction, { from: owner });
      
      // Check event was emitted
      const event = tx.logs.find(log => log.event === 'PropertyTokenized');
      assert.exists(event, "PropertyTokenized event should be emitted");
      
      const tokenId = event.args.tokenId;
      
      // Check token ownership
      const tokenOwner = await realEstateToken.ownerOf(tokenId);
      assert.equal(tokenOwner, user1, "Token should be owned by user1");
      
      // Check property data
      const property = await realEstateToken.getProperty(tokenId);
      assert.equal(property.jurisdiction, jurisdiction, "Property jurisdiction should match");
    });
    
    it("should fail if caller is not authorized", async () => {
      const propertyData = web3.eth.abi.encodeParameter(
        'tuple(string,string,tuple(string,string,string,tuple(string,string)),tuple(uint256,string,uint256,uint256,uint256))',
        [
          "Luxury Condo",
          "Beautiful condo with sea view",
          [
            "123 Beach Road",
            "Singapore",
            "Singapore",
            ["1.3036", "103.8318"]
          ],
          [120, "sqm", 3, 2, 2020]
        ]
      );
      
      const jurisdiction = 1; // SINGAPORE
      
      await expectRevert(
        realEstateToken.tokenizeProperty(user1, propertyData, jurisdiction, { from: user2 }),
        "Caller is not authorized"
      );
    });
  });
});
```

### End-to-End Testing

End-to-end tests focus on testing the entire application flow from the user's perspective.

**Example E2E Test for Web App**:

```javascript
// cypress/integration/myPage.spec.js
describe('My Page', () => {
  beforeEach(() => {
    // Log in
    cy.login('testuser@example.com', 'password123');
    
    // Visit the page
    cy.visit('/my-page');
  });
  
  it('should display items', () => {
    // Check if the page title is displayed
    cy.contains('h1', 'My Page').should('be.visible');
    
    // Check if items are loaded
    cy.get('.item-card').should('have.length.at.least', 1);
  });
  
  it('should add a new item', () => {
    // Click the add button
    cy.contains('button', 'Add Item').click();
    
    // Fill the form
    cy.get('input[name="name"]').type('New Test Item');
    cy.get('textarea[name="description"]').type('This is a test item');
    cy.get('select[name="status"]').select('active');
    
    // Submit the form
    cy.contains('button', 'Save').click();
    
    // Check if the new item is added
    cy.contains('.item-card', 'New Test Item').should('be.visible');
  });
});
```

## Deployment Pipeline

### Continuous Integration

The project uses GitHub Actions for continuous integration:

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:6
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '16'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Lint
      run: npm run lint
    
    - name: Test
      run: npm test
      env:
        NODE_ENV: test
        DB_HOST: localhost
        DB_PORT: 5432
        DB_NAME: test_db
        DB_USER: postgres
        DB_PASSWORD: postgres
        REDIS_HOST: localhost
        REDIS_PORT: 6379
    
    - name: Build
      run: npm run build
```

### Continuous Deployment

The project uses GitHub Actions for continuous deployment:

```yaml
# .github/workflows/cd.yml
name: CD

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '16'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Build
      run: npm run build
    
    - name: Deploy to staging
      if: github.ref == 'refs/heads/develop'
      run: |
        echo "${{ secrets.STAGING_SSH_KEY }}" > deploy_key
        chmod 600 deploy_key
        rsync -avz -e "ssh -i deploy_key -o StrictHostKeyChecking=no" \
          --exclude node_modules --exclude .git \
          ./ ${{ secrets.STAGING_SSH_USER }}@${{ secrets.STAGING_SSH_HOST }}:${{ secrets.STAGING_PATH }}
    
    - name: Deploy to production
      if: github.ref == 'refs/heads/main'
      run: |
        echo "${{ secrets.PRODUCTION_SSH_KEY }}" > deploy_key
        chmod 600 deploy_key
        rsync -avz -e "ssh -i deploy_key -o StrictHostKeyChecking=no" \
          --exclude node_modules --exclude .git \
          ./ ${{ secrets.PRODUCTION_SSH_USER }}@${{ secrets.PRODUCTION_SSH_HOST }}:${{ secrets.PRODUCTION_PATH }}
    
    - name: Restart services
      if: github.ref == 'refs/heads/main'
      run: |
        ssh -i deploy_key -o StrictHostKeyChecking=no \
          ${{ secrets.PRODUCTION_SSH_USER }}@${{ secrets.PRODUCTION_SSH_HOST }} \
          "cd ${{ secrets.PRODUCTION_PATH }} && npm ci && pm2 restart all"
```

## Extending the Platform

### Adding a New Application Module

To add a new application module:

1. **Define the interfaces**

```solidity
// contracts/core/interfaces/INewModule.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INewModule {
    // Define interface methods
}
```

2. **Implement the smart contracts**

```solidity
// contracts/applications/new_module/NewModule.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../core/interfaces/INewModule.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IAsset.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NewModule is INewModule, Ownable {
    ICompliance private _complianceRegistry;
    IAsset private _assetRegistry;
    
    constructor(address complianceRegistry, address assetRegistry) {
        _complianceRegistry = ICompliance(complianceRegistry);
        _assetRegistry = IAsset(assetRegistry);
    }
    
    // Implement interface methods
}
```

3. **Create API endpoints**

```javascript
// src/services/newModuleService.js
const NewModuleModel = require('../models/newModuleModel');
const { NotFoundError } = require('../utils/errors');

class NewModuleService {
  // Implement service methods
}

module.exports = new NewModuleService();
```

```javascript
// src/controllers/newModuleController.js
const newModuleService = require('../services/newModuleService');
const { asyncHandler } = require('../middlewares/asyncHandler');

// Implement controller methods

module.exports = {
  // Export controller methods
};
```

```javascript
// src/routes/newModuleRoutes.js
const express = require('express');
const router = express.Router();
const newModuleController = require('../controllers/newModuleController');
const { authenticate } = require('../middlewares/auth');

// Define routes

module.exports = router;
```

4. **Update the API routes**

```javascript
// src/routes/index.js
const express = require('express');
const router = express.Router();
const newModuleRoutes = require('./newModuleRoutes');

router.use('/api/new-module', newModuleRoutes);

module.exports = router;
```

5. **Create frontend components**

```jsx
// src/pages/NewModulePage/index.jsx
import React from 'react';
// Implement page component
```

6. **Update the navigation**

```jsx
// src/App.jsx
import NewModulePage from './pages/NewModulePage';

// Add the new page to the router
```

### Adding a New Payment Provider

To add a new payment provider:

1. **Update the payment configuration**

```json
// config/payment.json
{
  "traditional": {
    "providers": [
      {
        "id": "new-provider",
        "name": "New Payment Provider",
        "supportedJurisdictions": [0, 1, 2],
        "apiEndpoint": "https://api.newprovider.com/v1",
        "webhookEndpoint": "/webhooks/new-provider"
      }
    ]
  }
}
```

2. **Implement the payment provider adapter**

```javascript
// src/services/payment/providers/newProvider.js
const axios = require('axios');
const config = require('../../../config/config');

class NewProviderAdapter {
  constructor() {
    this.apiKey = config.payment.newProvider.apiKey;
    this.apiSecret = config.payment.newProvider.apiSecret;
    this.apiEndpoint = config.payment.newProvider.apiEndpoint;
  }
  
  async processPayment(paymentData) {
    try {
      const response = await axios.post(`${this.apiEndpoint}/payments`, {
        amount: paymentData.amount,
        currency: paymentData.currency,
        description: paymentData.description,
        metadata: paymentData.metadata,
        payment_method: paymentData.paymentMethod.data
      }, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json'
        }
      });
      
      return {
        success: true,
        transactionId: response.data.id,
        status: response.data.status,
        receiptUrl: response.data.receipt_url
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.error || error.message
      };
    }
  }
  
  async getPaymentStatus(transactionId) {
    try {
      const response = await axios.get(`${this.apiEndpoint}/payments/${transactionId}`, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`
        }
      });
      
      return {
        success: true,
        status: response.data.status,
        details: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.error || error.message
      };
    }
  }
  
  async refundPayment(transactionId, amount) {
    try {
      const response = await axios.post(`${this.apiEndpoint}/refunds`, {
        payment_id: transactionId,
        amount: amount
      }, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json'
        }
      });
      
      return {
        success: true,
        refundId: response.data.id,
        status: response.data.status
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.error || error.message
      };
    }
  }
}

module.exports = NewProviderAdapter;
```

3. **Register the provider in the payment service**

```javascript
// src/services/payment/paymentService.js
const NewProviderAdapter = require('./providers/newProvider');

class PaymentService {
  constructor() {
    this.providers = {
      traditional: {
        'new-provider': new NewProviderAdapter()
      }
    };
  }
  
  // Rest of the service implementation
}
```

4. **Implement the webhook handler**

```javascript
// src/controllers/webhooks/newProviderWebhook.js
const { asyncHandler } = require('../../middlewares/asyncHandler');
const paymentService = require('../../services/payment/paymentService');

exports.handleWebhook = asyncHandler(async (req, res) => {
  const signature = req.headers['x-new-provider-signature'];
  const payload = req.body;
  
  // Verify webhook signature
  const isValid = paymentService.verifyWebhookSignature('new-provider', signature, payload);
  
  if (!isValid) {
    return res.status(400).json({
      success: false,
      error: 'Invalid webhook signature'
    });
  }
  
  // Process the webhook event
  switch (payload.type) {
    case 'payment.succeeded':
      await paymentService.updatePaymentStatus(payload.data.id, 'completed');
      break;
    case 'payment.failed':
      await paymentService.updatePaymentStatus(payload.data.id, 'failed');
      break;
    // Handle other event types
  }
  
  res.status(200).json({ received: true });
});
```

5. **Register the webhook route**

```javascript
// src/routes/webhookRoutes.js
const express = require('express');
const router = express.Router();
const newProviderWebhook = require('../controllers/webhooks/newProviderWebhook');

router.post('/new-provider', newProviderWebhook.handleWebhook);

module.exports = router;
```

## Integration Guidelines

### Integrating with External Systems

To integrate with external systems:

1. **Create an integration service**

```javascript
// src/services/integrations/externalSystemService.js
const axios = require('axios');
const config = require('../../config/config');

class ExternalSystemService {
  constructor() {
    this.apiKey = config.integrations.externalSystem.apiKey;
    this.apiEndpoint = config.integrations.externalSystem.apiEndpoint;
  }
  
  async getData(params) {
    try {
      const response = await axios.get(`${this.apiEndpoint}/data`, {
        params,
        headers: {
          'Authorization': `Bearer ${this.apiKey}`
        }
      });
      
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.error || error.message
      };
    }
  }
  
  async sendData(data) {
    try {
      const response = await axios.post(`${this.apiEndpoint}/data`, data, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json'
        }
      });
      
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.error || error.message
      };
    }
  }
}

module.exports = new ExternalSystemService();
```

2. **Create an integration controller**

```javascript
// src/controllers/integrations/externalSystemController.js
const externalSystemService = require('../../services/integrations/externalSystemService');
const { asyncHandler } = require('../../middlewares/asyncHandler');

exports.getData = asyncHandler(async (req, res) => {
  const result = await externalSystemService.getData(req.query);
  
  if (!result.success) {
    return res.status(400).json({
      success: false,
      error: result.error
    });
  }
  
  res.status(200).json({
    success: true,
    data: result.data
  });
});

exports.sendData = asyncHandler(async (req, res) => {
  const result = await externalSystemService.sendData(req.body);
  
  if (!result.success) {
    return res.status(400).json({
      success: false,
      error: result.error
    });
  }
  
  res.status(200).json({
    success: true,
    data: result.data
  });
});
```

3. **Create integration routes**

```javascript
// src/routes/integrations/externalSystemRoutes.js
const express = require('express');
const router = express.Router();
const externalSystemController = require('../../controllers/integrations/externalSystemController');
const { authenticate } = require('../../middlewares/auth');

router.get('/data', authenticate, externalSystemController.getData);
router.post('/data', authenticate, externalSystemController.sendData);

module.exports = router;
```

4. **Register the integration routes**

```javascript
// src/routes/index.js
const express = require('express');
const router = express.Router();
const externalSystemRoutes = require('./integrations/externalSystemRoutes');

router.use('/api/integrations/external-system', externalSystemRoutes);

module.exports = router;
```

### Creating a Webhook Provider

To create a webhook provider for external systems to integrate with your platform:

1. **Create a webhook model**

```javascript
// src/models/webhook.js
const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Webhook = sequelize.define('Webhook', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  url: {
    type: DataTypes.STRING,
    allowNull: false
  },
  events: {
    type: DataTypes.ARRAY(DataTypes.STRING),
    allowNull: false
  },
  secret: {
    type: DataTypes.STRING,
    allowNull: false
  },
  active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false
  },
  createdAt: {
    type: DataTypes.DATE,
    allowNull: false
  },
  updatedAt: {
    type: DataTypes.DATE,
    allowNull: false
  }
});

module.exports = Webhook;
```

2. **Create a webhook service**

```javascript
// src/services/webhookService.js
const Webhook = require('../models/webhook');
const crypto = require('crypto');
const axios = require('axios');
const { NotFoundError } = require('../utils/errors');

class WebhookService {
  async create(data) {
    return await Webhook.create(data);
  }
  
  async findAll(userId) {
    return await Webhook.findAll({
      where: { userId }
    });
  }
  
  async findById(id, userId) {
    const webhook = await Webhook.findOne({
      where: { id, userId }
    });
    
    if (!webhook) {
      throw new NotFoundError(`Webhook with ID ${id} not found`);
    }
    
    return webhook;
  }
  
  async update(id, userId, data) {
    const webhook = await this.findById(id, userId);
    return await webhook.update(data);
  }
  
  async delete(id, userId) {
    const webhook = await this.findById(id, userId);
    await webhook.destroy();
    return { success: true };
  }
  
  async trigger(event, payload) {
    const webhooks = await Webhook.findAll({
      where: {
        events: { [Op.contains]: [event] },
        active: true
      }
    });
    
    const results = [];
    
    for (const webhook of webhooks) {
      try {
        // Generate signature
        const timestamp = Math.floor(Date.now() / 1000);
        const signedPayload = `${timestamp}.${JSON.stringify(payload)}`;
        const signature = crypto
          .createHmac('sha256', webhook.secret)
          .update(signedPayload)
          .digest('hex');
        
        // Send webhook
        const response = await axios.post(webhook.url, payload, {
          headers: {
            'Content-Type': 'application/json',
            'X-Signature': `t=${timestamp},v1=${signature}`
          }
        });
        
        results.push({
          webhookId: webhook.id,
          success: true,
          statusCode: response.status
        });
      } catch (error) {
        results.push({
          webhookId: webhook.id,
          success: false,
          error: error.message
        });
      }
    }
    
    return results;
  }
}

module.exports = new WebhookService();
```

3. **Create a webhook controller**

```javascript
// src/controllers/webhookController.js
const webhookService = require('../services/webhookService');
const { asyncHandler } = require('../middlewares/asyncHandler');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');

exports.create = asyncHandler(async (req, res) => {
  const { url, events } = req.body;
  const userId = req.user.id;
  
  // Generate a random secret
  const secret = crypto.randomBytes(32).toString('hex');
  
  const webhook = await webhookService.create({
    url,
    events,
    secret,
    userId
  });
  
  res.status(201).json({
    success: true,
    data: {
      id: webhook.id,
      url: webhook.url,
      events: webhook.events,
      secret,
      createdAt: webhook.createdAt
    }
  });
});

exports.getAll = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const webhooks = await webhookService.findAll(userId);
  
  res.status(200).json({
    success: true,
    data: webhooks.map(webhook => ({
      id: webhook.id,
      url: webhook.url,
      events: webhook.events,
      active: webhook.active,
      createdAt: webhook.createdAt
    }))
  });
});

exports.getById = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const webhook = await webhookService.findById(req.params.id, userId);
  
  res.status(200).json({
    success: true,
    data: {
      id: webhook.id,
      url: webhook.url,
      events: webhook.events,
      active: webhook.active,
      createdAt: webhook.createdAt,
      updatedAt: webhook.updatedAt
    }
  });
});

exports.update = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { url, events, active } = req.body;
  
  const webhook = await webhookService.update(req.params.id, userId, {
    url,
    events,
    active
  });
  
  res.status(200).json({
    success: true,
    data: {
      id: webhook.id,
      url: webhook.url,
      events: webhook.events,
      active: webhook.active,
      updatedAt: webhook.updatedAt
    }
  });
});

exports.delete = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  await webhookService.delete(req.params.id, userId);
  
  res.status(200).json({
    success: true,
    data: {
      message: 'Webhook deleted successfully'
    }
  });
});
```

4. **Create webhook routes**

```javascript
// src/routes/webhookRoutes.js
const express = require('express');
const router = express.Router();
const webhookController = require('../controllers/webhookController');
const { authenticate } = require('../middlewares/auth');

router.post('/', authenticate, webhookController.create);
router.get('/', authenticate, webhookController.getAll);
router.get('/:id', authenticate, webhookController.getById);
router.put('/:id', authenticate, webhookController.update);
router.delete('/:id', authenticate, webhookController.delete);

module.exports = router;
```

5. **Register the webhook routes**

```javascript
// src/routes/index.js
const express = require('express');
const router = express.Router();
const webhookRoutes = require('./webhookRoutes');

router.use('/api/webhooks', webhookRoutes);

module.exports = router;
```

## Security Best Practices

### Smart Contract Security

1. **Use Audited Libraries**
   - Use OpenZeppelin contracts for standard functionality
   - Keep dependencies up to date
   - Review audit reports for all dependencies

2. **Access Control**
   - Implement proper access control using modifiers
   - Use role-based access control for complex permissions
   - Validate all inputs

3. **Avoid Common Vulnerabilities**
   - Reentrancy: Use the Checks-Effects-Interactions pattern
   - Integer Overflow/Underflow: Use SafeMath or Solidity 0.8.x
   - Timestamp Dependence: Don't rely on block.timestamp for critical logic
   - Front-Running: Use commit-reveal schemes or transaction ordering protection

4. **Gas Optimization**
   - Minimize on-chain storage
   - Use events for logging
   - Batch operations when possible

### API Security

1. **Authentication and Authorization**
   - Use JWT for authentication
   - Implement role-based access control
   - Use short-lived tokens with refresh tokens
   - Store tokens securely (HttpOnly cookies, secure storage)

2. **Input Validation**
   - Validate all inputs on the server side
   - Use schema validation libraries (Joi, Yup)
   - Sanitize inputs to prevent injection attacks

3. **Rate Limiting**
   - Implement rate limiting for all endpoints
   - Use different limits for different endpoints
   - Add retry-after headers

4. **HTTPS**
   - Use HTTPS for all communications
   - Configure proper SSL/TLS settings
   - Use HSTS headers

5. **CORS**
   - Configure proper CORS headers
   - Limit allowed origins to trusted domains
   - Use specific methods and headers

### Frontend Security

1. **XSS Prevention**
   - Use React's built-in XSS protection
   - Sanitize any HTML content
   - Use Content Security Policy (CSP)

2. **CSRF Protection**
   - Use anti-CSRF tokens
   - Implement SameSite cookie attributes
   - Validate the origin of requests

3. **Secure Storage**
   - Don't store sensitive data in localStorage
   - Use HttpOnly cookies for sensitive data
   - Use secure storage for mobile apps

4. **Dependency Management**
   - Keep dependencies up to date
   - Use npm audit to check for vulnerabilities
   - Use lockfiles to pin dependency versions

## Compliance Integration

### Implementing Jurisdiction-Specific Compliance

1. **Define Compliance Rules**

```json
// config/compliance/singapore.json
{
  "real_estate": {
    "transfer": {
      "rules": [
        {
          "id": "sg_re_001",
          "name": "Stamp Duty Check",
          "description": "Verify that stamp duty has been paid",
          "validator": "stampDutyValidator"
        },
        {
          "id": "sg_re_002",
          "name": "Foreign Ownership Restriction",
          "description": "Check if the buyer is eligible to own the property",
          "validator": "foreignOwnershipValidator"
        }
      ]
    }
  },
  "legal_contracts": {
    "execution": {
      "rules": [
        {
          "id": "sg_lc_001",
          "name": "Electronic Signature Validation",
          "description": "Verify that the electronic signature meets Singapore requirements",
          "validator": "electronicSignatureValidator"
        }
      ]
    }
  }
}
```

2. **Implement Validators**

```javascript
// src/services/compliance/validators/singapore.js
const stampDutyValidator = async (data) => {
  // Check if stamp duty has been paid
  const { propertyValue, stampDutyPaid } = data;
  
  // Calculate expected stamp duty
  let expectedDuty = 0;
  if (propertyValue <= 180000) {
    expectedDuty = propertyValue * 0.01;
  } else if (propertyValue <= 360000) {
    expectedDuty = 1800 + (propertyValue - 180000) * 0.02;
  } else {
    expectedDuty = 5400 + (propertyValue - 360000) * 0.03;
  }
  
  // Add additional buyer's stamp duty if applicable
  if (data.buyerType === 'foreign') {
    expectedDuty += propertyValue * 0.2; // 20% ABSD for foreigners
  } else if (data.buyerType === 'permanent_resident') {
    expectedDuty += propertyValue * 0.05; // 5% ABSD for PRs
  }
  
  // Check if paid amount is sufficient
  if (stampDutyPaid < expectedDuty) {
    return {
      isCompliant: false,
      reason: `Insufficient stamp duty paid. Expected: ${expectedDuty}, Paid: ${stampDutyPaid}`
    };
  }
  
  return {
    isCompliant: true
  };
};

const foreignOwnershipValidator = async (data) => {
  // Check if the buyer is eligible to own the property
  const { buyerNationality, propertyType } = data;
  
  // Restricted properties for foreigners
  if (buyerNationality !== 'singapore' && propertyType === 'landed') {
    return {
      isCompliant: false,
      reason: 'Foreigners are not allowed to purchase landed properties without approval'
    };
  }
  
  // HDB restrictions
  if (propertyType === 'hdb' && buyerNationality !== 'singapore' && data.buyerStatus !== 'permanent_resident') {
    return {
      isCompliant: false,
      reason: 'Only Singapore citizens and permanent residents can purchase HDB flats'
    };
  }
  
  return {
    isCompliant: true
  };
};

const electronicSignatureValidator = async (data) => {
  // Check if the electronic signature meets Singapore requirements
  const { signatureType, signatureData, signatoryIdentityVerified } = data;
  
  // Check if identity was verified
  if (!signatoryIdentityVerified) {
    return {
      isCompliant: false,
      reason: 'Signatory identity must be verified for electronic signatures'
    };
  }
  
  // Check signature type
  if (signatureType !== 'secure_electronic_signature' && signatureType !== 'digital_signature') {
    return {
      isCompliant: false,
      reason: 'Only secure electronic signatures or digital signatures are accepted'
    };
  }
  
  return {
    isCompliant: true
  };
};

module.exports = {
  stampDutyValidator,
  foreignOwnershipValidator,
  electronicSignatureValidator
};
```

3. **Create a Compliance Service**

```javascript
// src/services/compliance/complianceService.js
const fs = require('fs');
const path = require('path');

class ComplianceService {
  constructor() {
    this.rules = {};
    this.validators = {};
    
    // Load all compliance rules
    this.loadRules();
    
    // Load all validators
    this.loadValidators();
  }
  
  loadRules() {
    const jurisdictions = ['malaysia', 'singapore', 'indonesia', 'brunei', 'thailand', 'cambodia', 'vietnam', 'laos'];
    
    jurisdictions.forEach(jurisdiction => {
      const rulesPath = path.join(__dirname, `../../config/compliance/${jurisdiction}.json`);
      if (fs.existsSync(rulesPath)) {
        this.rules[jurisdiction] = JSON.parse(fs.readFileSync(rulesPath, 'utf8'));
      }
    });
  }
  
  loadValidators() {
    const jurisdictions = ['malaysia', 'singapore', 'indonesia', 'brunei', 'thailand', 'cambodia', 'vietnam', 'laos'];
    
    jurisdictions.forEach(jurisdiction => {
      try {
        this.validators[jurisdiction] = require(`./validators/${jurisdiction}`);
      } catch (error) {
        console.warn(`No validators found for jurisdiction: ${jurisdiction}`);
      }
    });
  }
  
  async checkCompliance(params) {
    const { jurisdiction, operationType, operationData } = params;
    
    // Convert jurisdiction enum to string
    const jurisdictionStr = this.getJurisdictionString(jurisdiction);
    
    // Parse operation type (e.g., "real_estate.transfer")
    const [category, action] = operationType.toLowerCase().split('_');
    
    // Get rules for this operation
    const rules = this.getRules(jurisdictionStr, category, action);
    
    if (!rules || rules.length === 0) {
      // No specific rules, operation is compliant by default
      return {
        status: true,
        checks: []
      };
    }
    
    // Run all validators
    const checks = [];
    let isCompliant = true;
    
    for (const rule of rules) {
      const validator = this.getValidator(jurisdictionStr, rule.validator);
      
      if (!validator) {
        console.warn(`Validator not found: ${rule.validator}`);
        continue;
      }
      
      const result = await validator(operationData);
      
      checks.push({
        ruleId: rule.id,
        ruleName: rule.name,
        isCompliant: result.isCompliant,
        reason: result.reason || null
      });
      
      if (!result.isCompliant) {
        isCompliant = false;
      }
    }
    
    return {
      status: isCompliant,
      checks
    };
  }
  
  getJurisdictionString(jurisdiction) {
    // Convert jurisdiction enum to string
    const jurisdictions = ['malaysia', 'singapore', 'indonesia', 'brunei', 'thailand', 'cambodia', 'vietnam', 'laos'];
    
    if (typeof jurisdiction === 'number') {
      return jurisdictions[jurisdiction];
    }
    
    return jurisdiction.toLowerCase();
  }
  
  getRules(jurisdiction, category, action) {
    try {
      return this.rules[jurisdiction][category][action].rules;
    } catch (error) {
      return [];
    }
  }
  
  getValidator(jurisdiction, validatorName) {
    try {
      return this.validators[jurisdiction][validatorName];
    } catch (error) {
      return null;
    }
  }
}

module.exports = new ComplianceService();
```

4. **Use the Compliance Service**

```javascript
// src/services/realEstate/realEstateService.js
const complianceService = require('../compliance/complianceService');

class RealEstateService {
  async transferProperty(data) {
    // Check compliance
    const complianceResult = await complianceService.checkCompliance({
      jurisdiction: data.jurisdiction,
      operationType: 'REAL_ESTATE_TRANSFER',
      operationData: {
        propertyValue: data.price,
        stampDutyPaid: data.stampDutyPaid,
        buyerType: data.buyerType,
        buyerNationality: data.buyerNationality,
        propertyType: data.propertyType
      }
    });
    
    if (!complianceResult.status) {
      return {
        success: false,
        error: 'Compliance check failed',
        complianceChecks: complianceResult.checks
      };
    }
    
    // Proceed with property transfer
    // ...
    
    return {
      success: true,
      data: {
        // Transfer result
      },
      complianceChecks: complianceResult.checks
    };
  }
}
```

## Contributing Guidelines

### Code Style

- **JavaScript/TypeScript**: Follow the Airbnb JavaScript Style Guide
- **Solidity**: Follow the Solidity Style Guide
- **React**: Follow the React Style Guide

### Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`npm test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Commit Message Format

Follow the Conventional Commits specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools

Example:
```
feat(real-estate): add property tokenization feature

- Add RealEstateToken contract
- Implement property tokenization logic
- Add API endpoints for property tokenization

Closes #123
```

### Code Review Guidelines

- Review for functionality
- Review for security vulnerabilities
- Review for code quality and style
- Review for test coverage
- Review for documentation

### Testing Requirements

- All new features must include tests
- All bug fixes must include tests that reproduce the bug
- Maintain or improve test coverage
- Tests must pass before merging
