# API Interface Design for Southeast Asian Blockchain Solution

## 1. Introduction

This document outlines the API interface design for our blockchain solution targeting Southeast Asian markets. The API architecture provides secure, scalable, and compliant interfaces for interacting with the blockchain system across Malaysia, Singapore, Indonesia, Brunei, Thailand, Cambodia, Vietnam, and Laos.

## 2. API Architecture Overview

The API architecture follows a layered approach with the following components:

1. **API Gateway**: Entry point for all API requests with authentication, rate limiting, and routing
2. **Core API Services**: Primary business logic and blockchain interaction
3. **Compliance Services**: Country-specific regulatory compliance checks
4. **Integration Services**: Connections to external systems and traditional infrastructure
5. **Utility Services**: Common functionality used across multiple services

## 3. API Design Principles

### 3.1 General Principles

- **RESTful Design**: Follow REST principles for resource-oriented APIs
- **GraphQL Support**: Provide GraphQL endpoints for complex data queries
- **Versioning**: Clear versioning strategy for API evolution
- **Documentation**: Comprehensive OpenAPI/Swagger documentation
- **Consistency**: Uniform patterns and conventions across all endpoints
- **Security**: Multi-layered security approach with defense in depth
- **Compliance**: Built-in regulatory compliance checks
- **Performance**: Optimized for low latency and high throughput
- **Monitoring**: Comprehensive logging and monitoring capabilities

### 3.2 Authentication and Authorization

- **OAuth 2.0/OpenID Connect**: Industry standard authentication
- **JWT Tokens**: Secure, stateless authentication tokens
- **Role-Based Access Control**: Granular permission system
- **Multi-factor Authentication**: Additional security for sensitive operations
- **API Keys**: For service-to-service authentication
- **Jurisdiction-Based Permissions**: Access control based on regulatory jurisdiction

## 4. Core API Services

### 4.1 User Management API

#### 4.1.1 User Registration
```
POST /api/v1/users
Content-Type: application/json
{
  "email": "string",
  "password": "string",
  "full_name": "string",
  "phone_number": "string",
  "country": "string",
  "accept_terms": boolean
}

Response:
{
  "user_id": "string",
  "blockchain_address": "string",
  "verification_status": "string",
  "next_steps": [
    {
      "step": "string",
      "description": "string",
      "url": "string"
    }
  ]
}
```

#### 4.1.2 User Authentication
```
POST /api/v1/auth/login
Content-Type: application/json
{
  "email": "string",
  "password": "string",
  "two_factor_code": "string" (optional)
}

Response:
{
  "access_token": "string",
  "refresh_token": "string",
  "token_type": "Bearer",
  "expires_in": number,
  "user": {
    "user_id": "string",
    "blockchain_address": "string",
    "roles": ["string"],
    "permissions": ["string"]
  }
}
```

#### 4.1.3 User Profile Management
```
GET /api/v1/users/me
Authorization: Bearer {token}

Response:
{
  "user_id": "string",
  "blockchain_address": "string",
  "email": "string",
  "full_name": "string",
  "phone_number": "string",
  "country": "string",
  "verification_status": {
    "email_verified": boolean,
    "phone_verified": boolean,
    "identity_verified": boolean,
    "address_verified": boolean
  },
  "roles": ["string"],
  "created_at": "string",
  "updated_at": "string"
}
```

#### 4.1.4 KYC Verification
```
POST /api/v1/users/me/kyc
Authorization: Bearer {token}
Content-Type: multipart/form-data

Form fields:
- id_document_type: "string" (passport, national_id, driver_license)
- id_document_number: "string"
- id_document_country: "string"
- date_of_birth: "string" (YYYY-MM-DD)
- nationality: "string"
- residential_address: "string"
- id_document_front: file
- id_document_back: file
- selfie: file

Response:
{
  "verification_id": "string",
  "status": "pending",
  "estimated_completion_time": "string",
  "next_steps": [
    {
      "step": "string",
      "description": "string"
    }
  ]
}
```

### 4.2 Asset Management API

#### 4.2.1 Create Asset
```
POST /api/v1/assets
Authorization: Bearer {token}
Content-Type: application/json
{
  "asset_type": "string" (real_estate, supply_chain_item, legal_contract, insurance_policy, payment),
  "title": "string",
  "description": "string",
  "jurisdiction": "string",
  "metadata": {
    // Asset type specific fields
  },
  "documents": [
    {
      "document_type": "string",
      "title": "string",
      "file": "base64_encoded_string"
    }
  ]
}

Response:
{
  "asset_id": "string",
  "blockchain_tx_id": "string",
  "status": "string",
  "owner": "string",
  "created_at": "string"
}
```

#### 4.2.2 Get Asset Details
```
GET /api/v1/assets/{asset_id}
Authorization: Bearer {token}

Response:
{
  "asset_id": "string",
  "asset_type": "string",
  "title": "string",
  "description": "string",
  "jurisdiction": "string",
  "status": "string",
  "owner": "string",
  "metadata": {
    // Asset type specific fields
  },
  "documents": [
    {
      "document_id": "string",
      "document_type": "string",
      "title": "string",
      "ipfs_hash": "string",
      "created_at": "string"
    }
  ],
  "history": [
    {
      "action": "string",
      "timestamp": "string",
      "actor": "string",
      "details": {}
    }
  ],
  "created_at": "string",
  "updated_at": "string"
}
```

#### 4.2.3 List Assets
```
GET /api/v1/assets
Authorization: Bearer {token}
Query parameters:
- asset_type: "string"
- jurisdiction: "string"
- status: "string"
- page: number
- limit: number
- sort: "string"
- order: "asc" or "desc"

Response:
{
  "total": number,
  "page": number,
  "limit": number,
  "assets": [
    {
      "asset_id": "string",
      "asset_type": "string",
      "title": "string",
      "jurisdiction": "string",
      "status": "string",
      "owner": "string",
      "created_at": "string"
    }
  ]
}
```

#### 4.2.4 Transfer Asset
```
POST /api/v1/assets/{asset_id}/transfer
Authorization: Bearer {token}
Content-Type: application/json
{
  "recipient_address": "string",
  "transfer_reason": "string",
  "price": {
    "amount": number,
    "currency": "string"
  },
  "terms": {
    // Transfer-specific terms
  }
}

Response:
{
  "transfer_id": "string",
  "blockchain_tx_id": "string",
  "status": "string",
  "next_steps": [
    {
      "step": "string",
      "description": "string",
      "url": "string"
    }
  ]
}
```

### 4.3 Transaction API

#### 4.3.1 Create Transaction
```
POST /api/v1/transactions
Authorization: Bearer {token}
Content-Type: application/json
{
  "transaction_type": "string",
  "jurisdiction": "string",
  "parties": [
    {
      "address": "string",
      "role": "string"
    }
  ],
  "assets": ["string"],
  "metadata": {
    // Transaction-specific metadata
  },
  "documents": [
    {
      "document_type": "string",
      "title": "string",
      "file": "base64_encoded_string"
    }
  ]
}

Response:
{
  "transaction_id": "string",
  "blockchain_tx_id": "string",
  "status": "string",
  "next_steps": [
    {
      "step": "string",
      "description": "string",
      "url": "string"
    }
  ]
}
```

#### 4.3.2 Get Transaction Details
```
GET /api/v1/transactions/{transaction_id}
Authorization: Bearer {token}

Response:
{
  "transaction_id": "string",
  "blockchain_tx_id": "string",
  "transaction_type": "string",
  "jurisdiction": "string",
  "status": "string",
  "parties": [
    {
      "address": "string",
      "role": "string",
      "signature_status": "string"
    }
  ],
  "assets": [
    {
      "asset_id": "string",
      "asset_type": "string",
      "title": "string"
    }
  ],
  "timeline": [
    {
      "stage": "string",
      "timestamp": "string",
      "actor": "string",
      "action": "string",
      "status": "string"
    }
  ],
  "documents": [
    {
      "document_id": "string",
      "document_type": "string",
      "title": "string",
      "ipfs_hash": "string"
    }
  ],
  "compliance_checks": [
    {
      "check_type": "string",
      "result": "string",
      "timestamp": "string"
    }
  ],
  "created_at": "string",
  "updated_at": "string"
}
```

#### 4.3.3 List Transactions
```
GET /api/v1/transactions
Authorization: Bearer {token}
Query parameters:
- transaction_type: "string"
- jurisdiction: "string"
- status: "string"
- asset_id: "string"
- page: number
- limit: number
- sort: "string"
- order: "asc" or "desc"

Response:
{
  "total": number,
  "page": number,
  "limit": number,
  "transactions": [
    {
      "transaction_id": "string",
      "transaction_type": "string",
      "jurisdiction": "string",
      "status": "string",
      "created_at": "string"
    }
  ]
}
```

#### 4.3.4 Sign Transaction
```
POST /api/v1/transactions/{transaction_id}/sign
Authorization: Bearer {token}
Content-Type: application/json
{
  "signature_method": "string",
  "signature_data": "string"
}

Response:
{
  "transaction_id": "string",
  "signature_status": "string",
  "blockchain_tx_id": "string",
  "next_steps": [
    {
      "step": "string",
      "description": "string"
    }
  ]
}
```

### 4.4 Document API

#### 4.4.1 Upload Document
```
POST /api/v1/documents
Authorization: Bearer {token}
Content-Type: multipart/form-data

Form fields:
- document_type: "string"
- title: "string"
- description: "string"
- jurisdiction: "string"
- language: "string"
- related_entity_type: "string" (optional)
- related_entity_id: "string" (optional)
- file: file

Response:
{
  "document_id": "string",
  "ipfs_hash": "string",
  "content_hash": "string",
  "status": "string",
  "created_at": "string"
}
```

#### 4.4.2 Get Document
```
GET /api/v1/documents/{document_id}
Authorization: Bearer {token}

Response:
{
  "document_id": "string",
  "document_type": "string",
  "title": "string",
  "description": "string",
  "ipfs_hash": "string",
  "content_hash": "string",
  "file_size": number,
  "file_type": "string",
  "jurisdiction": "string",
  "language": "string",
  "related_entities": [
    {
      "entity_type": "string",
      "entity_id": "string"
    }
  ],
  "created_by": "string",
  "created_at": "string",
  "updated_at": "string"
}
```

#### 4.4.3 Verify Document
```
POST /api/v1/documents/verify
Authorization: Bearer {token}
Content-Type: multipart/form-data

Form fields:
- file: file

Response:
{
  "verified": boolean,
  "document_id": "string",
  "ipfs_hash": "string",
  "content_hash": "string",
  "created_at": "string",
  "verification_details": {
    "original_filename": "string",
    "file_size": number,
    "file_type": "string",
    "blockchain_verification": {
      "verified": boolean,
      "blockchain_tx_id": "string",
      "block_number": number,
      "timestamp": "string"
    }
  }
}
```

## 5. Application-Specific APIs

### 5.1 Real Estate API

#### 5.1.1 Register Property
```
POST /api/v1/real-estate/properties
Authorization: Bearer {token}
Content-Type: application/json
{
  "property_address": "string",
  "property_type": "string",
  "size": number,
  "size_unit": "string",
  "price": {
    "amount": number,
    "currency": "string"
  },
  "jurisdiction": "string",
  "registry_id": "string",
  "features": ["string"],
  "location": {
    "latitude": number,
    "longitude": number
  },
  "documents": [
    {
      "document_type": "string",
      "title": "string",
      "file": "base64_encoded_string"
    }
  ]
}

Response:
{
  "asset_id": "string",
  "property_id": "string",
  "blockchain_tx_id": "string",
  "status": "string",
  "compliance_status": {
    "jurisdiction": "string",
    "requirements": [
      {
        "requirement": "string",
        "status": "string"
      }
    ]
  },
  "next_steps": [
    {
      "step": "string",
      "description": "string",
      "url": "string"
    }
  ]
}
```

#### 5.1.2 Initiate Property Transfer
```
POST /api/v1/real-estate/properties/{property_id}/transfer
Authorization: Bearer {token}
Content-Type: application/json
{
  "buyer_address": "string",
  "price": {
    "amount": number,
    "currency": "string"
  },
  "payment_method": "string",
  "transfer_terms": {
    "closing_date": "string",
    "conditions": ["string"]
  }
}

Response:
{
  "transfer_id": "string",
  "transaction_id": "string",
  "blockchain_tx_id": "string",
  "status": "string",
  "cooling_period_ends": "string",
  "transfer_tax": {
    "amount": number,
    "currency": "string",
    "rate": number
  },
  "next_steps": [
    {
      "step": "string",
      "description": "string",
      "url": "string"
    }
  ]
}
```

### 5.2 Supply Chain API

#### 5.2.1 Register Supply Chain Item
```
POST /api/v1/supply-chain/items
Authorization: Bearer {token}
Content-Type: application/json
{
  "product_id": "string",
  "product_name": "string",
  "manufacturer": "string",
  "manufacturing_date": "string",
  "batch_number": "string",
  "jurisdiction": "string",
  "certifications": ["string"],
  "metadata": {
    // Product-specific metadata
  },
  "documents": [
    {
      "document_type": "string",
      "title": "string",
      "file": "base64_encoded_string"
    }
  ]
}

Response:
{
  "asset_id": "string",
  "item_id": "string",
  "blockchain_tx_id": "string",
  "tracking_id": "string",
  "status": "string",
  "next_steps": [
    {
      "step": "string",
      "description": "string",
      "url": "string"
    }
  ]
}
```

#### 5.2.2 Record Supply Chain Event
```
POST /api/v1/supply-chain/items/{item_id}/events
Authorization: Bearer {token}
Content-Type: application/json
{
  "event_type": "string",
  "location": {
    "latitude": number,
    "longitude": number,
    "address": "string",
    "country": "string"
  },
  "custodian": "string",
  "timestamp": "string",
  "metadata": {
    // Event-specific metadata
  },
  "documents": [
    {
      "document_type": "string",
      "title": "string",
      "file": "base64_encoded_string"
    }
  ]
}

Response:
{
  "event_id": "string",
  "blockchain_tx_id": "string",
  "status": "string",
  "compliance_status": {
    "jurisdiction": "string",
    "requirements": [
      {
        "requirement": "string",
        "status": "string"
      }
    ]
  }
}
```

### 5.3 Legal Contract API

#### 5.3.1 Create Legal Contract
```
POST /api/v1/legal/contracts
Authorization: Bearer {token}
Content-Type: application/json
{
  "contract_type": "string",
  "title": "string",
  "description": "string",
  "jurisdiction": "string",
  "governing_law": "string",
  "parties": [
    {
      "address": "string",
      "role": "string",
      "name": "string"
    }
  ],
  "effective_date": "string",
  "expiration_date": "string",
  "terms": {
    // Contract-specific terms
  },
  "dispute_resolution": "string",
  "documents": [
    {
      "document_type": "string",
      "title": "string",
      "file": "base64_encoded_string"
    }
  ]
}

Response:
{
  "asset_id": "string",
  "contract_id": "string",
  "blockchain_tx_id": "string",
  "status": "string",
  "compliance_status": {
    "jurisdiction": "string",
    "requirements": [
      {
        "requirement": "string",
        "status": "string"
      }
    ]
  },
  "next_steps": [
    {
      "step": "string",
      "description": "string",
      "url": "string"
    }
  ]
}
```

#### 5.3.2 Execute Contract Action
```
POST /api/v1/legal/contracts/{contract_id}/actions
Authorization: Bearer {token}
Content-Type: application/json
{
  "action_type": "string",
  "parameters": {
    // Action-specific parameters
  },
  "documents": [
    {
      "document_type": "string",
      "title": "string",
      "file": "base64_encoded_string"
    }
  ]
}

Response:
{
  "action_id": "string",
  "blockchain_tx_id": "string",
  "status": "string",
  "result": {
    // Action-specific result
  }
}
```

### 5.4 Insurance API

#### 5.4.1 Create Insurance Policy
```
POST /api/v1/insurance/policies
Authorization: Bearer {token}
Content-Type: application/json
{
  "policy_type": "string",
  "insurer": "string",
  "insured": {
    "address": "string",
    "name": "string",
    "identification": "string"
  },
  "jurisdiction": "string",
  "coverage": {
    "amount": number,
    "currency": "string",
    "details": {}
  },
  "premium": {
    "amount": number,
    "currency": "string",
    "payment_frequency": "string"
  },
  "start_date": "string",
  "end_date": "string",
  "terms": {
    // Policy-specific terms
  },
  "documents": [
    {
      "document_type": "string",
      "title": "string",
      "file": "base64_encoded_string"
    }
  ]
}

Response:
{
  "asset_id": "string",
  "policy_id": "string",
  "blockchain_tx_id": "string",
  "status": "string",
  "compliance_status": {
    "jurisdiction": "string",
    "requirements": [
      {
        "requirement": "string",
        "status": "string"
      }
    ]
  },
  "next_steps": [
    {
      "step": "string",
      "description": "string",
      "url": "string"
    }
  ]
}
```

#### 5.4.2 File Insurance Claim
```
POST /api/v1/insurance/policies/{policy_id}/claims
Authorization: Bearer {token}
Content-Type: application/json
{
  "claim_type": "string",
  "incident_date": "string",
  "description": "string",
  "amount": {
    "amount": number,
    "currency": "string"
  },
  "details": {
    // Claim-specific details
  },
  "documents": [
    {
      "document_type": "string",
      "title": "string",
      "file": "base64_encoded_string"
    }
  ]
}

Response:
{
  "claim_id": "string",
  "blockchain_tx_id": "string",
  "status": "string",
  "next_steps": [
    {
      "step": "string",
      "description": "string",
      "url": "string"
    }
  ]
}
```

### 5.5 Payment API

#### 5.5.1 Create Payment
```
POST /api/v1/payments
Authorization: Bearer {token}
Content-Type: application/json
{
  "payment_type": "string",
  "payer": "string",
  "payee": "string",
  "amount": {
    "amount": number,
    "currency": "string"
  },
  "payment_method": "string",
  "payment_details": {
    // Method-specific details
  },
  "purpose": "string",
  "reference": "string",
  "scheduled_date": "string",
  "recurring": {
    "frequency": "string",
    "start_date": "string",
    "end_date": "string",
    "max_payments": number
  }
}

Response:
{
  "payment_id": "string",
  "blockchain_tx_id": "string",
  "status": "string",
  "payment_url": "string",
  "next_steps": [
    {
      "step": "string",
      "description": "string",
      "url": "string"
    }
  ]
}
```

#### 5.5.2 Get Payment Status
```
GET /api/v1/payments/{payment_id}
Authorization: Bearer {token}

Response:
{
  "payment_id": "string",
  "blockchain_tx_id": "string",
  "payment_type": "string",
  "payer": "string",
  "payee": "string",
  "amount": {
    "amount": number,
    "currency": "string"
  },
  "payment_method": "string",
  "status": "string",
  "transaction_date": "string",
  "receipt": {
    "receipt_id": "string",
    "receipt_url": "string"
  },
  "compliance_status": {
    "jurisdiction": "string",
    "requirements": [
      {
        "requirement": "string",
        "status": "string"
      }
    ]
  }
}
```

## 6. Compliance API

### 6.1 Compliance Check
```
POST /api/v1/compliance/check
Authorization: Bearer {token}
Content-Type: application/json
{
  "entity_type": "string",
  "entity_id": "string",
  "jurisdiction": "string",
  "check_types": ["string"]
}

Response:
{
  "check_id": "string",
  "status": "string",
  "results": [
    {
      "check_type": "string",
      "result": "string",
      "details": {}
    }
  ],
  "overall_compliance": "string"
}
```

### 6.2 Regulatory Requirements
```
GET /api/v1/compliance/requirements
Authorization: Bearer {token}
Query parameters:
- entity_type: "string"
- jurisdiction: "string"

Response:
{
  "jurisdiction": "string",
  "entity_type": "string",
  "requirements": [
    {
      "requirement_id": "string",
      "description": "string",
      "category": "string",
      "mandatory": boolean,
      "documentation_url": "string"
    }
  ],
  "updated_at": "string"
}
```

## 7. Integration API

### 7.1 External System Webhooks
```
POST /api/v1/webhooks/register
Authorization: Bearer {token}
Content-Type: application/json
{
  "event_types": ["string"],
  "url": "string",
  "secret": "string",
  "description": "string",
  "active": boolean
}

Response:
{
  "webhook_id": "string",
  "status": "string",
  "created_at": "string"
}
```

### 7.2 Land Registry Integration
```
POST /api/v1/integrations/land-registry/verify
Authorization: Bearer {token}
Content-Type: application/json
{
  "property_id": "string",
  "registry_id": "string",
  "jurisdiction": "string",
  "verification_type": "string"
}

Response:
{
  "verification_id": "string",
  "status": "string",
  "registry_data": {
    // Registry-specific data
  },
  "verification_result": "string"
}
```

## 8. GraphQL API

### 8.1 GraphQL Endpoint
```
POST /api/v1/graphql
Authorization: Bearer {token}
Content-Type: application/json
{
  "query": "string",
  "variables": {}
}

Example query:
{
  user(id: "123") {
    id
    blockchain_address
    assets {
      id
      title
      asset_type
      status
    }
    transactions {
      id
      status
      created_at
    }
  }
}

Response:
{
  "data": {
    "user": {
      "id": "123",
      "blockchain_address": "0x...",
      "assets": [
        {
          "id": "asset1",
          "title": "Property A",
          "asset_type": "real_estate",
          "status": "active"
        }
      ],
      "transactions": [
        {
          "id": "tx1",
          "status": "completed",
          "created_at": "2025-03-01T12:00:00Z"
        }
      ]
    }
  }
}
```

## 9. API Security

### 9.1 Authentication Methods

- **OAuth 2.0**: Standard token-based authentication
- **JWT**: JSON Web Tokens for stateless authentication
- **API Keys**: For service-to-service authentication
- **Multi-factor Authentication**: For sensitive operations

### 9.2 Security Measures

- **TLS/SSL**: All API endpoints require HTTPS
- **Rate Limiting**: Prevent abuse and DoS attacks
- **Input Validation**: Strict validation of all inputs
- **Output Encoding**: Prevent injection attacks
- **CORS Policy**: Restrict cross-origin requests
- **Content Security Policy**: Prevent XSS attacks
- **IP Filtering**: Optional IP-based access control

### 9.3 Compliance Considerations

- **Data Localization**: Country-specific endpoints for data localization requirements
- **Audit Logging**: Comprehensive logging of all API access
- **Regulatory Reporting**: Built-in reporting capabilities
- **Privacy Controls**: Data minimization and access controls

## 10. API Versioning and Evolution

### 10.1 Versioning Strategy

- **URI Versioning**: /api/v1/, /api/v2/, etc.
- **Semantic Versioning**: Major.Minor.Patch
- **Deprecation Policy**: Minimum 6-month notice before removing APIs
- **Backwards Compatibility**: Maintained within major versions

### 10.2 Documentation

- **OpenAPI/Swagger**: Interactive API documentation
- **API Reference**: Detailed endpoint documentation
- **Code Samples**: Examples in multiple languages
- **Tutorials**: Step-by-step integration guides
- **Postman Collections**: Ready-to-use API collections

## 11. Implementation Considerations

### 11.1 Technology Stack

- **API Gateway**: Kong or AWS API Gateway
- **Authentication**: Keycloak or Auth0
- **Documentation**: Swagger UI and ReDoc
- **Monitoring**: Prometheus and Grafana
- **Testing**: Postman, Newman, and JMeter

### 11.2 Performance Optimization

- **Caching**: Redis for high-performance caching
- **Connection Pooling**: Efficient database connections
- **Asynchronous Processing**: Background processing for long-running operations
- **Content Compression**: GZIP/Brotli compression
- **CDN Integration**: For static content delivery

### 11.3 Deployment Strategy

- **Containerization**: Docker containers for consistent deployment
- **Orchestration**: Kubernetes for container management
- **CI/CD Pipeline**: Automated testing and deployment
- **Blue-Green Deployment**: Zero-downtime updates
- **Regional Deployment**: Country-specific deployments for compliance

## 12. Conclusion

This API interface design provides a comprehensive framework for interacting with our Southeast Asian blockchain solution. The design addresses both technical requirements and regulatory compliance needs across all target countries.

The API architecture is designed to be flexible, scalable, and secure, with built-in compliance checks and integration capabilities. The consistent design patterns and comprehensive documentation will facilitate adoption by developers and integration with existing systems.
