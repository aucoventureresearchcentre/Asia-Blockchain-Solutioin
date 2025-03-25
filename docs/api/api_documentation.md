# Asian Blockchain Solution API Documentation

## Introduction

This API documentation provides comprehensive details for developers integrating with the Asian Blockchain Solution. The platform offers both RESTful and GraphQL APIs to interact with all aspects of the system, including real estate transactions, supply chain management, legal contracts, insurance, and bill payments across Southeast Asian markets.

## Authentication

All API requests require authentication using JSON Web Tokens (JWT).

### Obtaining a Token

```
POST /api/auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600
}
```

### Using the Token

Include the token in the Authorization header for all API requests:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Refreshing a Token

```
POST /api/auth/refresh
```

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600
}
```

## RESTful API

### Base URL

```
https://api.asianblockchain.example.com/v1
```

### Response Format

All responses are returned in JSON format with the following structure:

```json
{
  "success": true,
  "data": {},
  "message": "Operation successful"
}
```

Or in case of an error:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error message"
  }
}
```

### Error Codes

| Code | Description |
|------|-------------|
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 409 | Conflict |
| 422 | Validation Error |
| 500 | Internal Server Error |

### Pagination

For endpoints that return multiple items, pagination is supported using the following query parameters:

- `page`: Page number (default: 1)
- `limit`: Number of items per page (default: 20, max: 100)
- `sort`: Field to sort by (default varies by endpoint)
- `order`: Sort order, either `asc` or `desc` (default: `asc`)

Example:
```
GET /api/real-estate/properties?page=2&limit=50&sort=createdAt&order=desc
```

Response includes pagination metadata:

```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "total": 120,
    "page": 2,
    "limit": 50,
    "pages": 3
  }
}
```

## User Management API

### Get Current User

```
GET /api/users/me
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "user123",
    "email": "user@example.com",
    "name": "John Doe",
    "jurisdiction": "SINGAPORE",
    "createdAt": "2025-01-15T08:30:00Z",
    "updatedAt": "2025-03-20T14:15:30Z"
  }
}
```

### Update User Profile

```
PUT /api/users/me
```

**Request Body:**
```json
{
  "name": "John Smith",
  "phone": "+6512345678",
  "address": {
    "street": "123 Orchard Road",
    "city": "Singapore",
    "postalCode": "238839",
    "country": "Singapore"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "user123",
    "email": "user@example.com",
    "name": "John Smith",
    "phone": "+6512345678",
    "address": {
      "street": "123 Orchard Road",
      "city": "Singapore",
      "postalCode": "238839",
      "country": "Singapore"
    },
    "jurisdiction": "SINGAPORE",
    "updatedAt": "2025-03-24T10:30:00Z"
  },
  "message": "Profile updated successfully"
}
```

## Real Estate API

### Get Properties

```
GET /api/real-estate/properties
```

**Query Parameters:**
- `status`: Filter by status (available, sold, pending)
- `type`: Filter by property type (residential, commercial, industrial)
- `minPrice`: Minimum price
- `maxPrice`: Maximum price
- `location`: Filter by location

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "prop123",
      "tokenId": "0x123abc...",
      "title": "Luxury Condo in Singapore",
      "description": "Beautiful 3-bedroom condo with city view",
      "type": "residential",
      "status": "available",
      "price": 1500000,
      "currency": "SGD",
      "location": {
        "address": "123 Orchard Road",
        "city": "Singapore",
        "country": "Singapore",
        "coordinates": {
          "latitude": 1.3036,
          "longitude": 103.8318
        }
      },
      "details": {
        "size": 120,
        "sizeUnit": "sqm",
        "bedrooms": 3,
        "bathrooms": 2,
        "yearBuilt": 2020
      },
      "owner": {
        "id": "user456",
        "name": "Property Holdings Ltd"
      },
      "jurisdiction": "SINGAPORE",
      "createdAt": "2025-02-10T09:00:00Z",
      "updatedAt": "2025-03-15T14:30:00Z"
    }
  ],
  "pagination": {
    "total": 45,
    "page": 1,
    "limit": 20,
    "pages": 3
  }
}
```

### Get Property by ID

```
GET /api/real-estate/properties/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "prop123",
    "tokenId": "0x123abc...",
    "title": "Luxury Condo in Singapore",
    "description": "Beautiful 3-bedroom condo with city view",
    "type": "residential",
    "status": "available",
    "price": 1500000,
    "currency": "SGD",
    "location": {
      "address": "123 Orchard Road",
      "city": "Singapore",
      "country": "Singapore",
      "coordinates": {
        "latitude": 1.3036,
        "longitude": 103.8318
      }
    },
    "details": {
      "size": 120,
      "sizeUnit": "sqm",
      "bedrooms": 3,
      "bathrooms": 2,
      "yearBuilt": 2020,
      "amenities": ["pool", "gym", "security"]
    },
    "documents": [
      {
        "id": "doc123",
        "type": "title_deed",
        "name": "Title Deed",
        "url": "https://api.asianblockchain.example.com/documents/doc123",
        "verified": true
      }
    ],
    "owner": {
      "id": "user456",
      "name": "Property Holdings Ltd"
    },
    "jurisdiction": "SINGAPORE",
    "complianceStatus": {
      "status": "compliant",
      "checks": [
        {
          "type": "ownership_verification",
          "status": "passed",
          "timestamp": "2025-02-10T09:30:00Z"
        },
        {
          "type": "regulatory_approval",
          "status": "passed",
          "timestamp": "2025-02-10T10:15:00Z"
        }
      ]
    },
    "createdAt": "2025-02-10T09:00:00Z",
    "updatedAt": "2025-03-15T14:30:00Z"
  }
}
```

### Create Property

```
POST /api/real-estate/properties
```

**Request Body:**
```json
{
  "title": "Luxury Condo in Singapore",
  "description": "Beautiful 3-bedroom condo with city view",
  "type": "residential",
  "price": 1500000,
  "currency": "SGD",
  "location": {
    "address": "123 Orchard Road",
    "city": "Singapore",
    "country": "Singapore",
    "coordinates": {
      "latitude": 1.3036,
      "longitude": 103.8318
    }
  },
  "details": {
    "size": 120,
    "sizeUnit": "sqm",
    "bedrooms": 3,
    "bathrooms": 2,
    "yearBuilt": 2020,
    "amenities": ["pool", "gym", "security"]
  },
  "documents": [
    {
      "type": "title_deed",
      "name": "Title Deed",
      "fileId": "file123"
    }
  ],
  "jurisdiction": "SINGAPORE"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "prop789",
    "tokenId": "0x789def...",
    "status": "pending",
    "createdAt": "2025-03-24T11:00:00Z",
    "message": "Property creation initiated. Tokenization in progress."
  }
}
```

### Create Property Transaction

```
POST /api/real-estate/transactions
```

**Request Body:**
```json
{
  "propertyId": "prop123",
  "buyerId": "user789",
  "price": 1450000,
  "currency": "SGD",
  "paymentMethod": {
    "type": "TRADITIONAL",
    "providerId": "provider123",
    "data": {
      "accountNumber": "xxxx-xxxx-xxxx-1234"
    }
  },
  "terms": {
    "depositAmount": 145000,
    "completionDate": "2025-04-30T00:00:00Z",
    "conditions": [
      "Subject to bank approval",
      "Subject to property inspection"
    ]
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "trans456",
    "propertyId": "prop123",
    "sellerId": "user456",
    "buyerId": "user789",
    "price": 1450000,
    "currency": "SGD",
    "status": "pending",
    "steps": [
      {
        "name": "deposit_payment",
        "status": "pending",
        "dueDate": "2025-04-02T00:00:00Z"
      },
      {
        "name": "document_verification",
        "status": "pending",
        "dueDate": "2025-04-15T00:00:00Z"
      },
      {
        "name": "final_payment",
        "status": "pending",
        "dueDate": "2025-04-30T00:00:00Z"
      },
      {
        "name": "ownership_transfer",
        "status": "pending",
        "dueDate": "2025-05-05T00:00:00Z"
      }
    ],
    "createdAt": "2025-03-24T11:30:00Z"
  }
}
```

## Supply Chain API

### Get Supply Chain Items

```
GET /api/supply-chain/items
```

**Query Parameters:**
- `status`: Filter by status (in_production, in_transit, delivered)
- `type`: Filter by item type
- `manufacturer`: Filter by manufacturer
- `origin`: Filter by country of origin

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "item123",
      "name": "Organic Coffee Beans",
      "description": "Premium Arabica coffee beans",
      "type": "agricultural",
      "status": "in_transit",
      "manufacturer": {
        "id": "manu123",
        "name": "Highland Coffee Co."
      },
      "origin": {
        "country": "Vietnam",
        "region": "Central Highlands"
      },
      "currentLocation": {
        "country": "Malaysia",
        "city": "Port Klang",
        "facility": "Customs Warehouse"
      },
      "destination": {
        "country": "Singapore",
        "city": "Singapore",
        "facility": "Distribution Center"
      },
      "trackingId": "TRK789012",
      "createdAt": "2025-03-10T08:00:00Z",
      "updatedAt": "2025-03-22T14:30:00Z"
    }
  ],
  "pagination": {
    "total": 67,
    "page": 1,
    "limit": 20,
    "pages": 4
  }
}
```

### Get Supply Chain Item by ID

```
GET /api/supply-chain/items/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "item123",
    "name": "Organic Coffee Beans",
    "description": "Premium Arabica coffee beans",
    "type": "agricultural",
    "status": "in_transit",
    "manufacturer": {
      "id": "manu123",
      "name": "Highland Coffee Co."
    },
    "origin": {
      "country": "Vietnam",
      "region": "Central Highlands"
    },
    "specifications": {
      "weight": 500,
      "weightUnit": "kg",
      "packaging": "Vacuum-sealed bags",
      "batchNumber": "VN-2025-03-001"
    },
    "certifications": [
      {
        "type": "organic",
        "issuer": "Vietnam Organic Association",
        "issuedDate": "2025-01-15T00:00:00Z",
        "expiryDate": "2026-01-14T23:59:59Z",
        "verified": true
      }
    ],
    "currentLocation": {
      "country": "Malaysia",
      "city": "Port Klang",
      "facility": "Customs Warehouse",
      "coordinates": {
        "latitude": 3.0011,
        "longitude": 101.4083
      },
      "timestamp": "2025-03-22T14:30:00Z"
    },
    "destination": {
      "country": "Singapore",
      "city": "Singapore",
      "facility": "Distribution Center"
    },
    "trackingId": "TRK789012",
    "trackingHistory": [
      {
        "location": {
          "country": "Vietnam",
          "city": "Ho Chi Minh City",
          "facility": "Processing Plant"
        },
        "status": "processed",
        "timestamp": "2025-03-15T10:00:00Z"
      },
      {
        "location": {
          "country": "Vietnam",
          "city": "Ho Chi Minh City",
          "facility": "Export Terminal"
        },
        "status": "shipped",
        "timestamp": "2025-03-18T08:30:00Z"
      },
      {
        "location": {
          "country": "Malaysia",
          "city": "Port Klang",
          "facility": "Customs Warehouse"
        },
        "status": "in_customs",
        "timestamp": "2025-03-22T14:30:00Z"
      }
    ],
    "documents": [
      {
        "id": "doc456",
        "type": "certificate_of_origin",
        "name": "Certificate of Origin",
        "url": "https://api.asianblockchain.example.com/documents/doc456",
        "verified": true
      },
      {
        "id": "doc457",
        "type": "phytosanitary_certificate",
        "name": "Phytosanitary Certificate",
        "url": "https://api.asianblockchain.example.com/documents/doc457",
        "verified": true
      }
    ],
    "createdAt": "2025-03-10T08:00:00Z",
    "updatedAt": "2025-03-22T14:30:00Z"
  }
}
```

### Create Supply Chain Item

```
POST /api/supply-chain/items
```

**Request Body:**
```json
{
  "name": "Organic Coffee Beans",
  "description": "Premium Arabica coffee beans",
  "type": "agricultural",
  "manufacturer": {
    "id": "manu123"
  },
  "origin": {
    "country": "Vietnam",
    "region": "Central Highlands"
  },
  "specifications": {
    "weight": 500,
    "weightUnit": "kg",
    "packaging": "Vacuum-sealed bags",
    "batchNumber": "VN-2025-03-001"
  },
  "certifications": [
    {
      "type": "organic",
      "issuer": "Vietnam Organic Association",
      "issuedDate": "2025-01-15T00:00:00Z",
      "expiryDate": "2026-01-14T23:59:59Z",
      "certificateId": "VOA-2025-123"
    }
  ],
  "destination": {
    "country": "Singapore",
    "city": "Singapore",
    "facility": "Distribution Center"
  },
  "documents": [
    {
      "type": "certificate_of_origin",
      "name": "Certificate of Origin",
      "fileId": "file456"
    },
    {
      "type": "phytosanitary_certificate",
      "name": "Phytosanitary Certificate",
      "fileId": "file457"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "item789",
    "trackingId": "TRK123456",
    "status": "created",
    "createdAt": "2025-03-24T12:00:00Z",
    "message": "Supply chain item created successfully."
  }
}
```

### Update Item Location

```
POST /api/supply-chain/items/:id/track
```

**Request Body:**
```json
{
  "location": {
    "country": "Singapore",
    "city": "Singapore",
    "facility": "Port of Singapore",
    "coordinates": {
      "latitude": 1.2655,
      "longitude": 103.8205
    }
  },
  "status": "arrived",
  "timestamp": "2025-03-25T09:30:00Z",
  "notes": "Arrived at destination port, awaiting customs clearance"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "item123",
    "trackingId": "TRK789012",
    "status": "arrived",
    "currentLocation": {
      "country": "Singapore",
      "city": "Singapore",
      "facility": "Port of Singapore",
      "coordinates": {
        "latitude": 1.2655,
        "longitude": 103.8205
      },
      "timestamp": "2025-03-25T09:30:00Z"
    },
    "updatedAt": "2025-03-25T09:30:00Z"
  },
  "message": "Item location updated successfully."
}
```

## Legal Contracts API

### Get Contracts

```
GET /api/legal-contracts
```

**Query Parameters:**
- `status`: Filter by status (draft, pending_signature, active, completed, terminated)
- `type`: Filter by contract type
- `party`: Filter by party involved (user ID)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "contract123",
      "title": "Service Agreement",
      "type": "service",
      "status": "active",
      "parties": [
        {
          "id": "user123",
          "name": "ABC Corporation",
          "role": "service_provider",
          "signatureStatus": "signed",
          "signedAt": "2025-03-01T10:30:00Z"
        },
        {
          "id": "user456",
          "name": "XYZ Ltd",
          "role": "client",
          "signatureStatus": "signed",
          "signedAt": "2025-03-02T14:15:00Z"
        }
      ],
      "jurisdiction": "SINGAPORE",
      "effectiveDate": "2025-03-15T00:00:00Z",
      "expirationDate": "2026-03-14T23:59:59Z",
      "createdAt": "2025-02-25T09:00:00Z",
      "updatedAt": "2025-03-02T14:15:00Z"
    }
  ],
  "pagination": {
    "total": 28,
    "page": 1,
    "limit": 20,
    "pages": 2
  }
}
```

### Get Contract by ID

```
GET /api/legal-contracts/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "contract123",
    "title": "Service Agreement",
    "description": "IT services agreement between ABC Corporation and XYZ Ltd",
    "type": "service",
    "status": "active",
    "parties": [
      {
        "id": "user123",
        "name": "ABC Corporation",
        "role": "service_provider",
        "signatureStatus": "signed",
        "signedAt": "2025-03-01T10:30:00Z"
      },
      {
        "id": "user456",
        "name": "XYZ Ltd",
        "role": "client",
        "signatureStatus": "signed",
        "signedAt": "2025-03-02T14:15:00Z"
      }
    ],
    "terms": [
      {
        "id": "term1",
        "title": "Services",
        "content": "The Service Provider agrees to provide IT support services...",
        "type": "text"
      },
      {
        "id": "term2",
        "title": "Payment Terms",
        "content": "The Client agrees to pay $5,000 per month...",
        "type": "payment",
        "paymentDetails": {
          "amount": 5000,
          "currency": "USD",
          "frequency": "monthly",
          "dueDay": 15
        }
      },
      {
        "id": "term3",
        "title": "Term and Termination",
        "content": "This Agreement shall be effective for one year...",
        "type": "text"
      }
    ],
    "obligations": [
      {
        "id": "obl1",
        "partyId": "user123",
        "description": "Provide 24/7 IT support",
        "status": "active",
        "dueDate": null
      },
      {
        "id": "obl2",
        "partyId": "user456",
        "description": "Monthly payment of $5,000",
        "status": "recurring",
        "dueDate": "2025-04-15T00:00:00Z"
      }
    ],
    "documents": [
      {
        "id": "doc789",
        "type": "contract_document",
        "name": "Service Agreement.pdf",
        "url": "https://api.asianblockchain.example.com/documents/doc789",
        "verified": true
      }
    ],
    "jurisdiction": "SINGAPORE",
    "governingLaw": "Laws of Singapore",
    "disputeResolution": "Arbitration in Singapore",
    "effectiveDate": "2025-03-15T00:00:00Z",
    "expirationDate": "2026-03-14T23:59:59Z",
    "executionHistory": [
      {
        "event": "contract_created",
        "timestamp": "2025-02-25T09:00:00Z",
        "actor": "user123"
      },
      {
        "event": "signature_requested",
        "timestamp": "2025-02-25T09:05:00Z",
        "actor": "user123"
      },
      {
        "event": "contract_signed",
        "timestamp": "2025-03-01T10:30:00Z",
        "actor": "user123"
      },
      {
        "event": "contract_signed",
        "timestamp": "2025-03-02T14:15:00Z",
        "actor": "user456"
      },
      {
        "event": "contract_activated",
        "timestamp": "2025-03-15T00:00:00Z",
        "actor": "system"
      }
    ],
    "createdAt": "2025-02-25T09:00:00Z",
    "updatedAt": "2025-03-15T00:00:00Z"
  }
}
```

### Create Contract

```
POST /api/legal-contracts
```

**Request Body:**
```json
{
  "title": "Service Agreement",
  "description": "IT services agreement between ABC Corporation and XYZ Ltd",
  "type": "service",
  "templateId": "template123",
  "parties": [
    {
      "id": "user123",
      "role": "service_provider"
    },
    {
      "id": "user456",
      "role": "client"
    }
  ],
  "terms": [
    {
      "title": "Services",
      "content": "The Service Provider agrees to provide IT support services...",
      "type": "text"
    },
    {
      "title": "Payment Terms",
      "content": "The Client agrees to pay $5,000 per month...",
      "type": "payment",
      "paymentDetails": {
        "amount": 5000,
        "currency": "USD",
        "frequency": "monthly",
        "dueDay": 15
      }
    },
    {
      "title": "Term and Termination",
      "content": "This Agreement shall be effective for one year...",
      "type": "text"
    }
  ],
  "jurisdiction": "SINGAPORE",
  "governingLaw": "Laws of Singapore",
  "disputeResolution": "Arbitration in Singapore",
  "effectiveDate": "2025-04-01T00:00:00Z",
  "expirationDate": "2026-03-31T23:59:59Z"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "contract789",
    "status": "draft",
    "createdAt": "2025-03-24T13:00:00Z",
    "message": "Contract created successfully."
  }
}
```

### Request Signatures

```
POST /api/legal-contracts/:id/request-signatures
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "contract789",
    "status": "pending_signature",
    "signatureRequests": [
      {
        "partyId": "user123",
        "email": "company@abc.com",
        "requestedAt": "2025-03-24T13:05:00Z",
        "expiresAt": "2025-04-07T13:05:00Z"
      },
      {
        "partyId": "user456",
        "email": "info@xyz.com",
        "requestedAt": "2025-03-24T13:05:00Z",
        "expiresAt": "2025-04-07T13:05:00Z"
      }
    ],
    "updatedAt": "2025-03-24T13:05:00Z"
  },
  "message": "Signature requests sent successfully."
}
```

### Sign Contract

```
POST /api/legal-contracts/:id/sign
```

**Request Body:**
```json
{
  "signatureType": "electronic",
  "signatureData": "base64-encoded-signature-data"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "contract789",
    "partyId": "user123",
    "signatureStatus": "signed",
    "signedAt": "2025-03-24T14:30:00Z",
    "contractStatus": "pending_signature",
    "updatedAt": "2025-03-24T14:30:00Z"
  },
  "message": "Contract signed successfully."
}
```

## Insurance API

### Get Policies

```
GET /api/insurance/policies
```

**Query Parameters:**
- `status`: Filter by status (active, expired, cancelled)
- `type`: Filter by policy type (property, health, vehicle, business, travel)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "policy123",
      "policyNumber": "POL-2025-001234",
      "type": "property",
      "status": "active",
      "policyholder": {
        "id": "user123",
        "name": "John Doe"
      },
      "insurer": {
        "id": "ins456",
        "name": "Southeast Asia Insurance Co."
      },
      "premium": {
        "amount": 1200,
        "currency": "SGD",
        "frequency": "annual"
      },
      "coverageAmount": 500000,
      "startDate": "2025-01-01T00:00:00Z",
      "endDate": "2025-12-31T23:59:59Z",
      "jurisdiction": "SINGAPORE",
      "createdAt": "2024-12-15T10:00:00Z",
      "updatedAt": "2025-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "total": 12,
    "page": 1,
    "limit": 20,
    "pages": 1
  }
}
```

### Get Policy by ID

```
GET /api/insurance/policies/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "policy123",
    "policyNumber": "POL-2025-001234",
    "type": "property",
    "status": "active",
    "policyholder": {
      "id": "user123",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+6512345678"
    },
    "insurer": {
      "id": "ins456",
      "name": "Southeast Asia Insurance Co."
    },
    "insuredProperty": {
      "id": "prop789",
      "type": "residential",
      "address": {
        "street": "123 Orchard Road",
        "city": "Singapore",
        "postalCode": "238839",
        "country": "Singapore"
      },
      "details": {
        "size": 120,
        "sizeUnit": "sqm",
        "yearBuilt": 2020,
        "construction": "Concrete",
        "securityFeatures": ["alarm", "cctv", "guard"]
      }
    },
    "coverage": [
      {
        "type": "building",
        "amount": 500000,
        "currency": "SGD",
        "deductible": 1000
      },
      {
        "type": "contents",
        "amount": 100000,
        "currency": "SGD",
        "deductible": 500
      },
      {
        "type": "liability",
        "amount": 200000,
        "currency": "SGD",
        "deductible": 0
      }
    ],
    "premium": {
      "amount": 1200,
      "currency": "SGD",
      "frequency": "annual",
      "nextDueDate": "2026-01-01T00:00:00Z",
      "paymentMethod": {
        "type": "TRADITIONAL",
        "providerId": "provider123",
        "last4": "1234"
      }
    },
    "exclusions": [
      "War and terrorism",
      "Nuclear hazards",
      "Intentional damage"
    ],
    "documents": [
      {
        "id": "doc123",
        "type": "policy_document",
        "name": "Property Insurance Policy.pdf",
        "url": "https://api.asianblockchain.example.com/documents/doc123",
        "verified": true
      }
    ],
    "claims": [
      {
        "id": "claim456",
        "claimNumber": "CLM-2025-005678",
        "status": "settled",
        "incidentDate": "2025-02-15T08:30:00Z",
        "filedDate": "2025-02-16T14:00:00Z",
        "description": "Water damage from burst pipe",
        "settlementAmount": 3500,
        "settlementDate": "2025-03-01T10:15:00Z"
      }
    ],
    "beneficiaries": [
      {
        "id": "ben123",
        "name": "Jane Doe",
        "relationship": "spouse",
        "percentage": 100
      }
    ],
    "startDate": "2025-01-01T00:00:00Z",
    "endDate": "2025-12-31T23:59:59Z",
    "jurisdiction": "SINGAPORE",
    "createdAt": "2024-12-15T10:00:00Z",
    "updatedAt": "2025-03-01T10:15:00Z"
  }
}
```

### Create Policy

```
POST /api/insurance/policies
```

**Request Body:**
```json
{
  "type": "property",
  "policyholder": {
    "id": "user123"
  },
  "insurer": {
    "id": "ins456"
  },
  "insuredProperty": {
    "type": "residential",
    "address": {
      "street": "123 Orchard Road",
      "city": "Singapore",
      "postalCode": "238839",
      "country": "Singapore"
    },
    "details": {
      "size": 120,
      "sizeUnit": "sqm",
      "yearBuilt": 2020,
      "construction": "Concrete",
      "securityFeatures": ["alarm", "cctv", "guard"]
    }
  },
  "coverage": [
    {
      "type": "building",
      "amount": 500000,
      "currency": "SGD",
      "deductible": 1000
    },
    {
      "type": "contents",
      "amount": 100000,
      "currency": "SGD",
      "deductible": 500
    },
    {
      "type": "liability",
      "amount": 200000,
      "currency": "SGD",
      "deductible": 0
    }
  ],
  "premium": {
    "frequency": "annual",
    "paymentMethod": {
      "type": "TRADITIONAL",
      "providerId": "provider123",
      "data": {
        "accountNumber": "xxxx-xxxx-xxxx-1234"
      }
    }
  },
  "beneficiaries": [
    {
      "name": "Jane Doe",
      "relationship": "spouse",
      "percentage": 100
    }
  ],
  "startDate": "2025-04-01T00:00:00Z",
  "endDate": "2026-03-31T23:59:59Z",
  "jurisdiction": "SINGAPORE"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "policy789",
    "policyNumber": "POL-2025-005678",
    "status": "pending_payment",
    "premium": {
      "amount": 1350,
      "currency": "SGD",
      "frequency": "annual",
      "dueDate": "2025-03-31T23:59:59Z"
    },
    "createdAt": "2025-03-24T15:00:00Z",
    "message": "Policy created successfully. Payment required to activate."
  }
}
```

### File Claim

```
POST /api/insurance/policies/:id/claims
```

**Request Body:**
```json
{
  "incidentDate": "2025-03-20T09:30:00Z",
  "description": "Storm damage to roof",
  "estimatedAmount": 5000,
  "currency": "SGD",
  "documents": [
    {
      "type": "damage_photo",
      "name": "Roof Damage Photo 1",
      "fileId": "file123"
    },
    {
      "type": "repair_estimate",
      "name": "Contractor Estimate",
      "fileId": "file124"
    }
  ],
  "contactInformation": {
    "name": "John Doe",
    "phone": "+6512345678",
    "email": "john@example.com"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "claim789",
    "claimNumber": "CLM-2025-007890",
    "status": "submitted",
    "policyId": "policy123",
    "incidentDate": "2025-03-20T09:30:00Z",
    "filedDate": "2025-03-24T15:30:00Z",
    "estimatedAmount": 5000,
    "currency": "SGD",
    "nextSteps": [
      {
        "step": "claim_review",
        "description": "Your claim is being reviewed by our claims department",
        "estimatedCompletion": "2025-03-27T00:00:00Z"
      },
      {
        "step": "adjuster_assignment",
        "description": "An adjuster will be assigned to assess the damage",
        "estimatedCompletion": "2025-03-29T00:00:00Z"
      }
    ],
    "createdAt": "2025-03-24T15:30:00Z",
    "message": "Claim filed successfully."
  }
}
```

## Bill Payments API

### Get Bills

```
GET /api/bill-payments/bills
```

**Query Parameters:**
- `status`: Filter by status (pending, paid, overdue)
- `type`: Filter by bill type (utility, subscription, loan, etc.)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "bill123",
      "billNumber": "INV-2025-001234",
      "type": "utility",
      "status": "pending",
      "biller": {
        "id": "biller123",
        "name": "Singapore Power Ltd"
      },
      "customer": {
        "id": "user456",
        "name": "John Doe"
      },
      "amount": 150.75,
      "currency": "SGD",
      "dueDate": "2025-04-15T23:59:59Z",
      "jurisdiction": "SINGAPORE",
      "createdAt": "2025-03-15T10:00:00Z",
      "updatedAt": "2025-03-15T10:00:00Z"
    }
  ],
  "pagination": {
    "total": 35,
    "page": 1,
    "limit": 20,
    "pages": 2
  }
}
```

### Get Bill by ID

```
GET /api/bill-payments/bills/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "bill123",
    "billNumber": "INV-2025-001234",
    "type": "utility",
    "status": "pending",
    "biller": {
      "id": "biller123",
      "name": "Singapore Power Ltd",
      "category": "electricity",
      "contactInformation": {
        "email": "billing@singaporepower.com",
        "phone": "+6567654321",
        "website": "https://www.singaporepower.com"
      }
    },
    "customer": {
      "id": "user456",
      "name": "John Doe",
      "accountNumber": "SP123456789"
    },
    "billingPeriod": {
      "startDate": "2025-02-01T00:00:00Z",
      "endDate": "2025-02-28T23:59:59Z"
    },
    "amount": 150.75,
    "currency": "SGD",
    "breakdown": [
      {
        "description": "Electricity consumption (350 kWh)",
        "amount": 120.75,
        "currency": "SGD"
      },
      {
        "description": "Service charge",
        "amount": 30.00,
        "currency": "SGD"
      }
    ],
    "dueDate": "2025-04-15T23:59:59Z",
    "lateFee": {
      "amount": 10.00,
      "currency": "SGD",
      "appliesAfter": "2025-04-15T23:59:59Z"
    },
    "paymentMethods": [
      {
        "type": "TRADITIONAL",
        "providerId": "provider123",
        "name": "Credit Card"
      },
      {
        "type": "TRADITIONAL",
        "providerId": "provider456",
        "name": "Bank Transfer"
      },
      {
        "type": "CRYPTO",
        "providerId": "provider789",
        "name": "Cryptocurrency"
      }
    ],
    "documents": [
      {
        "id": "doc123",
        "type": "invoice",
        "name": "February 2025 Electricity Bill.pdf",
        "url": "https://api.asianblockchain.example.com/documents/doc123",
        "verified": true
      }
    ],
    "jurisdiction": "SINGAPORE",
    "createdAt": "2025-03-15T10:00:00Z",
    "updatedAt": "2025-03-15T10:00:00Z"
  }
}
```

### Create Bill

```
POST /api/bill-payments/bills
```

**Request Body:**
```json
{
  "type": "utility",
  "biller": {
    "id": "biller123"
  },
  "customer": {
    "id": "user456",
    "accountNumber": "SP123456789"
  },
  "billingPeriod": {
    "startDate": "2025-03-01T00:00:00Z",
    "endDate": "2025-03-31T23:59:59Z"
  },
  "amount": 165.30,
  "currency": "SGD",
  "breakdown": [
    {
      "description": "Electricity consumption (380 kWh)",
      "amount": 135.30,
      "currency": "SGD"
    },
    {
      "description": "Service charge",
      "amount": 30.00,
      "currency": "SGD"
    }
  ],
  "dueDate": "2025-05-15T23:59:59Z",
  "lateFee": {
    "amount": 10.00,
    "currency": "SGD"
  },
  "documents": [
    {
      "type": "invoice",
      "name": "March 2025 Electricity Bill.pdf",
      "fileId": "file123"
    }
  ],
  "jurisdiction": "SINGAPORE"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "bill789",
    "billNumber": "INV-2025-003456",
    "status": "pending",
    "amount": 165.30,
    "currency": "SGD",
    "dueDate": "2025-05-15T23:59:59Z",
    "createdAt": "2025-03-24T16:00:00Z",
    "message": "Bill created successfully."
  }
}
```

### Pay Bill

```
POST /api/bill-payments/bills/:id/pay
```

**Request Body:**
```json
{
  "paymentMethod": {
    "type": "TRADITIONAL",
    "providerId": "provider123",
    "data": {
      "accountNumber": "xxxx-xxxx-xxxx-1234"
    }
  },
  "amount": 165.30,
  "currency": "SGD",
  "paymentDate": "2025-03-24T16:30:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "payment123",
    "billId": "bill789",
    "status": "completed",
    "amount": 165.30,
    "currency": "SGD",
    "paymentDate": "2025-03-24T16:30:00Z",
    "receiptNumber": "REC-2025-007890",
    "receiptUrl": "https://api.asianblockchain.example.com/receipts/REC-2025-007890.pdf",
    "createdAt": "2025-03-24T16:30:00Z",
    "message": "Payment processed successfully."
  }
}
```

### Set Up Recurring Payment

```
POST /api/bill-payments/recurring
```

**Request Body:**
```json
{
  "name": "Monthly Electricity Bill",
  "biller": {
    "id": "biller123"
  },
  "customer": {
    "id": "user456",
    "accountNumber": "SP123456789"
  },
  "paymentMethod": {
    "type": "TRADITIONAL",
    "providerId": "provider123",
    "data": {
      "accountNumber": "xxxx-xxxx-xxxx-1234"
    }
  },
  "frequency": "monthly",
  "dayOfMonth": 10,
  "startDate": "2025-04-10T00:00:00Z",
  "endDate": "2026-04-09T23:59:59Z",
  "maxAmount": 200.00,
  "currency": "SGD",
  "jurisdiction": "SINGAPORE"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "recurring123",
    "name": "Monthly Electricity Bill",
    "status": "active",
    "nextPaymentDate": "2025-04-10T00:00:00Z",
    "frequency": "monthly",
    "createdAt": "2025-03-24T16:45:00Z",
    "message": "Recurring payment set up successfully."
  }
}
```

## Payment API

### Get Payment Providers

```
GET /api/payments/providers
```

**Query Parameters:**
- `type`: Filter by provider type (TRADITIONAL, CRYPTO)
- `jurisdiction`: Filter by jurisdiction code (0-7)

**Response:**
```json
{
  "success": true,
  "data": {
    "traditional": [
      {
        "id": "provider123",
        "name": "Visa",
        "type": "CREDIT_CARD",
        "supportedJurisdictions": [0, 1, 2, 3, 4, 5, 6, 7],
        "isActive": true
      },
      {
        "id": "provider456",
        "name": "MayBank",
        "type": "BANK_TRANSFER",
        "supportedJurisdictions": [0],
        "isActive": true
      },
      {
        "id": "provider789",
        "name": "GrabPay",
        "type": "E_WALLET",
        "supportedJurisdictions": [0, 1, 2, 4, 5, 6],
        "isActive": true
      }
    ],
    "crypto": [
      {
        "id": "provider234",
        "name": "Ethereum",
        "blockchain": "ETH",
        "supportedJurisdictions": [0, 1, 2, 3, 4, 5, 6, 7],
        "requiresKYC": true,
        "isActive": true
      },
      {
        "id": "provider567",
        "name": "Bitcoin",
        "blockchain": "BTC",
        "supportedJurisdictions": [0, 1, 2, 3, 4, 5, 6, 7],
        "requiresKYC": true,
        "isActive": true
      },
      {
        "id": "provider890",
        "name": "Singapore Dollar Token",
        "blockchain": "XSGD",
        "supportedJurisdictions": [1],
        "requiresKYC": true,
        "isActive": true
      }
    ]
  }
}
```

### Process Payment

```
POST /api/payments/process
```

**Request Body:**
```json
{
  "payer": "user123",
  "payee": "merchant456",
  "amount": 1000,
  "currency": "SGD",
  "paymentMethod": {
    "type": "TRADITIONAL",
    "providerId": "provider123",
    "data": {
      "accountNumber": "xxxx-xxxx-xxxx-1234",
      "expiryDate": "12/27",
      "cvv": "123"
    }
  },
  "description": "Payment for services",
  "jurisdiction": 1,
  "metadata": {
    "orderId": "order123",
    "customerReference": "REF-2025-001"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "payment123",
    "status": "completed",
    "amount": 1000,
    "currency": "SGD",
    "processingFee": 25,
    "totalAmount": 1025,
    "transactionId": "TXN-2025-001234",
    "receiptUrl": "https://api.asianblockchain.example.com/receipts/TXN-2025-001234.pdf",
    "createdAt": "2025-03-24T17:00:00Z",
    "message": "Payment processed successfully."
  }
}
```

### Get Payment Status

```
GET /api/payments/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "payment123",
    "payer": {
      "id": "user123",
      "name": "John Doe"
    },
    "payee": {
      "id": "merchant456",
      "name": "ABC Services"
    },
    "amount": 1000,
    "currency": "SGD",
    "processingFee": 25,
    "totalAmount": 1025,
    "paymentMethod": {
      "type": "TRADITIONAL",
      "provider": "Visa",
      "last4": "1234"
    },
    "status": "completed",
    "description": "Payment for services",
    "transactionId": "TXN-2025-001234",
    "receiptUrl": "https://api.asianblockchain.example.com/receipts/TXN-2025-001234.pdf",
    "metadata": {
      "orderId": "order123",
      "customerReference": "REF-2025-001"
    },
    "jurisdiction": "SINGAPORE",
    "createdAt": "2025-03-24T17:00:00Z",
    "updatedAt": "2025-03-24T17:00:05Z"
  }
}
```

## GraphQL API

### Base URL

```
https://api.asianblockchain.example.com/graphql
```

### Authentication

Include the JWT token in the Authorization header:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Example Queries

#### Get User Profile

```graphql
query GetUserProfile {
  me {
    id
    name
    email
    phone
    address {
      street
      city
      postalCode
      country
    }
    jurisdiction
    createdAt
    updatedAt
  }
}
```

#### Get Property Details

```graphql
query GetProperty($id: ID!) {
  property(id: $id) {
    id
    tokenId
    title
    description
    type
    status
    price
    currency
    location {
      address
      city
      country
      coordinates {
        latitude
        longitude
      }
    }
    details {
      size
      sizeUnit
      bedrooms
      bathrooms
      yearBuilt
      amenities
    }
    owner {
      id
      name
    }
    documents {
      id
      type
      name
      url
      verified
    }
    jurisdiction
    complianceStatus {
      status
      checks {
        type
        status
        timestamp
      }
    }
    createdAt
    updatedAt
  }
}
```

#### Create Transaction

```graphql
mutation CreateTransaction($input: TransactionInput!) {
  createTransaction(input: $input) {
    id
    propertyId
    sellerId
    buyerId
    price
    currency
    status
    steps {
      name
      status
      dueDate
    }
    createdAt
  }
}
```

Variables:
```json
{
  "input": {
    "propertyId": "prop123",
    "buyerId": "user789",
    "price": 1450000,
    "currency": "SGD",
    "paymentMethod": {
      "type": "TRADITIONAL",
      "providerId": "provider123",
      "data": {
        "accountNumber": "xxxx-xxxx-xxxx-1234"
      }
    },
    "terms": {
      "depositAmount": 145000,
      "completionDate": "2025-04-30T00:00:00Z",
      "conditions": [
        "Subject to bank approval",
        "Subject to property inspection"
      ]
    }
  }
}
```

#### Get Supply Chain Item with Tracking History

```graphql
query GetSupplyChainItem($id: ID!) {
  supplyChainItem(id: $id) {
    id
    name
    description
    type
    status
    manufacturer {
      id
      name
    }
    origin {
      country
      region
    }
    specifications {
      weight
      weightUnit
      packaging
      batchNumber
    }
    certifications {
      type
      issuer
      issuedDate
      expiryDate
      verified
    }
    currentLocation {
      country
      city
      facility
      coordinates {
        latitude
        longitude
      }
      timestamp
    }
    trackingHistory {
      location {
        country
        city
        facility
      }
      status
      timestamp
    }
    documents {
      id
      type
      name
      url
      verified
    }
    createdAt
    updatedAt
  }
}
```

#### Create Legal Contract

```graphql
mutation CreateContract($input: ContractInput!) {
  createContract(input: $input) {
    id
    status
    createdAt
    message
  }
}
```

Variables:
```json
{
  "input": {
    "title": "Service Agreement",
    "description": "IT services agreement between ABC Corporation and XYZ Ltd",
    "type": "service",
    "templateId": "template123",
    "parties": [
      {
        "id": "user123",
        "role": "service_provider"
      },
      {
        "id": "user456",
        "role": "client"
      }
    ],
    "terms": [
      {
        "title": "Services",
        "content": "The Service Provider agrees to provide IT support services...",
        "type": "text"
      },
      {
        "title": "Payment Terms",
        "content": "The Client agrees to pay $5,000 per month...",
        "type": "payment",
        "paymentDetails": {
          "amount": 5000,
          "currency": "USD",
          "frequency": "monthly",
          "dueDay": 15
        }
      }
    ],
    "jurisdiction": "SINGAPORE",
    "governingLaw": "Laws of Singapore",
    "disputeResolution": "Arbitration in Singapore",
    "effectiveDate": "2025-04-01T00:00:00Z",
    "expirationDate": "2026-03-31T23:59:59Z"
  }
}
```

## Smart Contract API

### Core Interfaces

#### ICompliance

```solidity
interface ICompliance {
    enum Jurisdiction {
        MALAYSIA,
        SINGAPORE,
        INDONESIA,
        BRUNEI,
        THAILAND,
        CAMBODIA,
        VIETNAM,
        LAOS
    }
    
    function isOperationCompliant(
        Jurisdiction jurisdiction,
        string calldata operationType,
        bytes calldata operationData
    ) external view returns (bool isCompliant, string memory reason);
    
    function getComplianceRules(
        Jurisdiction jurisdiction,
        string calldata operationType
    ) external view returns (bytes memory rules);
    
    function addComplianceRule(
        Jurisdiction jurisdiction,
        string calldata operationType,
        bytes calldata rule
    ) external returns (bool success);
    
    function removeComplianceRule(
        Jurisdiction jurisdiction,
        string calldata operationType,
        uint256 ruleIndex
    ) external returns (bool success);
}
```

#### IAsset

```solidity
interface IAsset {
    enum AssetType {
        REAL_ESTATE,
        SUPPLY_CHAIN_ITEM,
        DOCUMENT,
        INSURANCE_POLICY,
        PAYMENT
    }
    
    function registerAsset(
        AssetType assetType,
        address owner,
        bytes calldata assetData,
        ICompliance.Jurisdiction jurisdiction
    ) external returns (bytes32 assetId);
    
    function getAsset(bytes32 assetId) external view returns (
        AssetType assetType,
        address owner,
        bytes memory assetData,
        ICompliance.Jurisdiction jurisdiction,
        uint256 createdAt,
        uint256 updatedAt
    );
    
    function updateAsset(
        bytes32 assetId,
        bytes calldata assetData
    ) external returns (bool success);
    
    function transferAsset(
        bytes32 assetId,
        address newOwner
    ) external returns (bool success);
    
    function isAssetOwner(
        bytes32 assetId,
        address owner
    ) external view returns (bool isOwner);
}
```

#### ITransaction

```solidity
interface ITransaction {
    enum TransactionStatus {
        PENDING,
        COMPLETED,
        FAILED,
        CANCELLED
    }
    
    function createTransaction(
        address from,
        address to,
        bytes32 assetId,
        uint256 amount,
        bytes calldata transactionData,
        ICompliance.Jurisdiction jurisdiction
    ) external returns (bytes32 transactionId);
    
    function getTransaction(bytes32 transactionId) external view returns (
        address from,
        address to,
        bytes32 assetId,
        uint256 amount,
        bytes memory transactionData,
        TransactionStatus status,
        ICompliance.Jurisdiction jurisdiction,
        uint256 createdAt,
        uint256 updatedAt
    );
    
    function updateTransactionStatus(
        bytes32 transactionId,
        TransactionStatus newStatus
    ) external returns (bool success);
    
    function getTransactionsByAsset(bytes32 assetId) external view returns (bytes32[] memory transactionIds);
    
    function getTransactionsByAddress(address addr) external view returns (bytes32[] memory transactionIds);
}
```

#### IDocument

```solidity
interface IDocument {
    enum DocumentType {
        CONTRACT,
        TITLE_DEED,
        CERTIFICATE,
        INVOICE,
        RECEIPT,
        INSURANCE_POLICY,
        OTHER
    }
    
    enum DocumentStatus {
        DRAFT,
        PENDING_SIGNATURE,
        SIGNED,
        EXECUTED,
        EXPIRED,
        REVOKED
    }
    
    function createDocument(
        DocumentType documentType,
        string calldata documentURI,
        bytes calldata documentHash,
        address[] calldata signatories,
        bytes calldata documentData,
        ICompliance.Jurisdiction jurisdiction
    ) external returns (bytes32 documentId);
    
    function getDocument(bytes32 documentId) external view returns (
        DocumentType documentType,
        string memory documentURI,
        bytes memory documentHash,
        address[] memory signatories,
        bytes memory documentData,
        DocumentStatus status,
        ICompliance.Jurisdiction jurisdiction,
        uint256 createdAt,
        uint256 updatedAt
    );
    
    function signDocument(
        bytes32 documentId,
        bytes calldata signature
    ) external returns (bool success);
    
    function verifyDocument(
        bytes32 documentId,
        bytes calldata documentHash
    ) external view returns (bool isValid);
    
    function updateDocumentStatus(
        bytes32 documentId,
        DocumentStatus newStatus
    ) external returns (bool success);
}
```

#### IPayment

```solidity
interface IPayment {
    enum PaymentMethod {
        TRADITIONAL,
        CRYPTO
    }
    
    function processPayment(
        address payer,
        address payee,
        uint256 amount,
        PaymentMethod paymentMethod,
        bytes calldata paymentData
    ) external returns (bytes32 paymentId);
    
    function getPayment(bytes32 paymentId) external view returns (
        address payer,
        address payee,
        uint256 amount,
        PaymentMethod paymentMethod,
        bytes memory paymentData,
        string memory status,
        uint256 createdAt,
        uint256 updatedAt
    );
    
    function updatePaymentStatus(
        bytes32 paymentId,
        string calldata newStatus
    ) external returns (bool success);
}
```

### Example Usage

```javascript
// Connect to the blockchain
const Web3 = require('web3');
const web3 = new Web3('https://rpc.asianblockchain.example.com');

// Load contract ABI
const RealEstateTokenABI = require('./abi/RealEstateToken.json');
const realEstateTokenAddress = '0x1234567890123456789012345678901234567890';

// Create contract instance
const realEstateToken = new web3.eth.Contract(RealEstateTokenABI, realEstateTokenAddress);

// Get user account
const account = '0x9876543210987654321098765432109876543210';

// Tokenize a property
async function tokenizeProperty() {
  const propertyData = {
    title: 'Luxury Condo in Singapore',
    description: 'Beautiful 3-bedroom condo with city view',
    location: {
      address: '123 Orchard Road',
      city: 'Singapore',
      country: 'Singapore',
      coordinates: {
        latitude: 1.3036,
        longitude: 103.8318
      }
    },
    details: {
      size: 120,
      sizeUnit: 'sqm',
      bedrooms: 3,
      bathrooms: 2,
      yearBuilt: 2020
    }
  };
  
  // Encode property data
  const encodedPropertyData = web3.eth.abi.encodeParameter(
    'tuple(string,string,tuple(string,string,string,tuple(string,string)),tuple(uint256,string,uint256,uint256,uint256))',
    [
      propertyData.title,
      propertyData.description,
      [
        propertyData.location.address,
        propertyData.location.city,
        propertyData.location.country,
        [
          propertyData.location.coordinates.latitude.toString(),
          propertyData.location.coordinates.longitude.toString()
        ]
      ],
      [
        propertyData.details.size,
        propertyData.details.sizeUnit,
        propertyData.details.bedrooms,
        propertyData.details.bathrooms,
        propertyData.details.yearBuilt
      ]
    ]
  );
  
  // Jurisdiction: SINGAPORE = 1
  const jurisdiction = 1;
  
  // Tokenize the property
  const result = await realEstateToken.methods.tokenizeProperty(
    account,
    encodedPropertyData,
    jurisdiction
  ).send({ from: account });
  
  console.log('Property tokenized successfully!');
  console.log('Token ID:', result.events.PropertyTokenized.returnValues.tokenId);
  console.log('Transaction Hash:', result.transactionHash);
}

// Call the function
tokenizeProperty().catch(console.error);
```

## Webhooks

The API supports webhooks for real-time event notifications.

### Webhook Registration

```
POST /api/webhooks
```

**Request Body:**
```json
{
  "url": "https://your-server.com/webhook",
  "events": [
    "payment.completed",
    "contract.signed",
    "property.transferred"
  ],
  "secret": "your-webhook-secret"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "webhook123",
    "url": "https://your-server.com/webhook",
    "events": [
      "payment.completed",
      "contract.signed",
      "property.transferred"
    ],
    "createdAt": "2025-03-24T17:30:00Z",
    "message": "Webhook registered successfully."
  }
}
```

### Webhook Payload

When an event occurs, a POST request will be sent to your webhook URL with the following payload:

```json
{
  "id": "evt_123456",
  "type": "payment.completed",
  "created": "2025-03-24T17:35:00Z",
  "data": {
    "id": "payment123",
    "status": "completed",
    "amount": 1000,
    "currency": "SGD",
    "payer": "user123",
    "payee": "merchant456",
    "transactionId": "TXN-2025-001234"
  }
}
```

### Webhook Signature

Each webhook request includes a signature in the `X-Signature` header. You should verify this signature to ensure the webhook is from the Asian Blockchain Solution:

```
X-Signature: t=1714046100,v1=5257a869e7ecebeda32affa62cdca3fa51cad7e77a0e56ff536d0ce8e108d8bd
```

To verify the signature:

1. Extract the timestamp (`t`) and signature (`v1`) from the header
2. Prepare the signed payload: `{timestamp}.{payload}`
3. Compute the HMAC-SHA256 of the signed payload using your webhook secret
4. Compare the computed signature with the received signature

## Rate Limits

The API enforces rate limits to ensure fair usage:

| API | Rate Limit |
|-----|------------|
| Authentication | 10 requests per minute |
| General API | 60 requests per minute |
| Payment Processing | 30 requests per minute |

When a rate limit is exceeded, the API returns a 429 Too Many Requests response with a Retry-After header indicating when you can retry.

## Error Handling

The API uses standard HTTP status codes and returns detailed error messages:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "amount",
        "message": "Amount must be greater than zero"
      }
    ]
  }
}
```

Common error codes:

| Code | Description |
|------|-------------|
| AUTHENTICATION_ERROR | Authentication failed |
| AUTHORIZATION_ERROR | Insufficient permissions |
| VALIDATION_ERROR | Invalid input data |
| RESOURCE_NOT_FOUND | Requested resource not found |
| COMPLIANCE_ERROR | Operation violates compliance rules |
| PAYMENT_ERROR | Payment processing failed |
| SYSTEM_ERROR | Internal system error |

## Versioning

The API uses versioning in the URL path:

- Current version: `/v1`
- Future versions: `/v2`, `/v3`, etc.

When a new version is released, the previous version will be supported for at least 12 months.
