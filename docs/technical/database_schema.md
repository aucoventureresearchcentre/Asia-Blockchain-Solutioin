# Database Schema Design for Southeast Asian Blockchain Solution

## 1. Introduction

This document outlines the database schema design for our blockchain solution targeting Southeast Asian markets. The database architecture supports both on-chain and off-chain data storage, with careful consideration for regulatory requirements across Malaysia, Singapore, Indonesia, Brunei, Thailand, Cambodia, Vietnam, and Laos.

## 2. Database Architecture Overview

The solution employs a hybrid database architecture with the following components:

1. **On-Chain Storage**: Data stored directly on the blockchain
2. **Off-Chain Distributed Storage**: IPFS for immutable document storage
3. **Off-Chain Relational Database**: PostgreSQL for structured data
4. **Off-Chain Document Database**: MongoDB for flexible document storage
5. **Country-Specific Data Stores**: For compliance with data localization requirements

## 3. Data Classification

Data is classified according to storage requirements:

### 3.1 On-Chain Data
- Transaction records
- Smart contract state
- Ownership records
- Verification hashes
- Audit trails

### 3.2 Off-Chain Data
- Document content
- User profiles
- Historical records
- Analytics data
- Large media files
- Personally identifiable information (PII)

## 4. On-Chain Data Schema

### 4.1 Core Entities

#### 4.1.1 User
```
User {
  address: Address (PK)
  publicKey: Bytes
  roles: Role[]
  status: UserStatus
  kycVerified: Boolean
  jurisdictions: Jurisdiction[]
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

#### 4.1.2 Asset
```
Asset {
  id: UUID (PK)
  owner: Address
  assetType: AssetType
  metadata: IPFS_Hash
  status: AssetStatus
  jurisdiction: Jurisdiction
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

#### 4.1.3 Transaction
```
Transaction {
  id: UUID (PK)
  transactionType: TransactionType
  parties: Address[]
  assets: UUID[]
  status: TransactionStatus
  jurisdiction: Jurisdiction
  complianceVerifications: ComplianceVerification[]
  createdAt: Timestamp
  completedAt: Timestamp
}
```

#### 4.1.4 ComplianceVerification
```
ComplianceVerification {
  id: UUID (PK)
  transactionId: UUID (FK)
  verificationType: VerificationType
  jurisdiction: Jurisdiction
  status: VerificationStatus
  verifier: Address
  timestamp: Timestamp
  evidenceHash: Bytes
}
```

### 4.2 Application-Specific Entities

#### 4.2.1 RealEstateProperty
```
RealEstateProperty {
  assetId: UUID (FK)
  propertyType: PropertyType
  registryId: String
  location: GeoLocation
  size: Decimal
  features: String[]
  legalDocumentHashes: Bytes[]
  transferTaxRate: Decimal
  coolingPeriodDays: Integer
}
```

#### 4.2.2 SupplyChainItem
```
SupplyChainItem {
  assetId: UUID (FK)
  productId: String
  manufacturer: Address
  currentCustodian: Address
  custodyChain: Address[]
  certifications: Certification[]
  crossBorderStatus: CrossBorderStatus
}
```

#### 4.2.3 LegalContract
```
LegalContract {
  assetId: UUID (FK)
  contractType: ContractType
  parties: Address[]
  terms: IPFS_Hash
  signatures: Signature[]
  effectiveDate: Timestamp
  expirationDate: Timestamp
  governingLaw: Jurisdiction
  disputeResolution: DisputeResolutionMethod
}
```

#### 4.2.4 InsurancePolicy
```
InsurancePolicy {
  assetId: UUID (FK)
  policyType: PolicyType
  insurer: Address
  insured: Address
  coverageAmount: Decimal
  premium: Decimal
  startDate: Timestamp
  endDate: Timestamp
  claimProcedure: IPFS_Hash
  regulatoryApprovals: RegulatoryApproval[]
}
```

#### 4.2.5 PaymentRecord
```
PaymentRecord {
  id: UUID (PK)
  payer: Address
  payee: Address
  amount: Decimal
  currency: Currency
  paymentMethod: PaymentMethod
  status: PaymentStatus
  purpose: String
  relatedAsset: UUID
  timestamp: Timestamp
  receiptHash: Bytes
}
```

## 5. Off-Chain Relational Database Schema

### 5.1 User Management

#### 5.1.1 Users
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  blockchain_address VARCHAR(42) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE,
  phone_number VARCHAR(20),
  full_name VARCHAR(255),
  date_of_birth DATE,
  nationality VARCHAR(100),
  id_document_type VARCHAR(50),
  id_document_number VARCHAR(100),
  id_document_country VARCHAR(100),
  id_document_expiry DATE,
  residential_address TEXT,
  kyc_status VARCHAR(20) NOT NULL,
  kyc_verification_date TIMESTAMP,
  kyc_verifier VARCHAR(100),
  account_status VARCHAR(20) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

#### 5.1.2 UserRoles
```sql
CREATE TABLE user_roles (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  role VARCHAR(50) NOT NULL,
  jurisdiction VARCHAR(50),
  granted_by INTEGER REFERENCES users(id),
  granted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);
```

### 5.2 Document Management

#### 5.2.1 Documents
```sql
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  document_type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  ipfs_hash VARCHAR(100) UNIQUE NOT NULL,
  content_hash VARCHAR(100) NOT NULL,
  file_size INTEGER NOT NULL,
  file_type VARCHAR(50) NOT NULL,
  jurisdiction VARCHAR(50),
  language VARCHAR(50),
  version INTEGER NOT NULL DEFAULT 1,
  is_template BOOLEAN NOT NULL DEFAULT FALSE,
  created_by INTEGER REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

#### 5.2.2 DocumentRelationships
```sql
CREATE TABLE document_relationships (
  id SERIAL PRIMARY KEY,
  parent_document_id INTEGER REFERENCES documents(id),
  child_document_id INTEGER REFERENCES documents(id),
  relationship_type VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### 5.3 Compliance Records

#### 5.3.1 ComplianceChecks
```sql
CREATE TABLE compliance_checks (
  id SERIAL PRIMARY KEY,
  check_type VARCHAR(50) NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id VARCHAR(100) NOT NULL,
  jurisdiction VARCHAR(50) NOT NULL,
  result VARCHAR(20) NOT NULL,
  details TEXT,
  performed_by INTEGER REFERENCES users(id),
  performed_at TIMESTAMP NOT NULL DEFAULT NOW(),
  evidence_references TEXT[]
);
```

#### 5.3.2 RegulatoryReports
```sql
CREATE TABLE regulatory_reports (
  id SERIAL PRIMARY KEY,
  report_type VARCHAR(50) NOT NULL,
  jurisdiction VARCHAR(50) NOT NULL,
  reporting_period_start DATE NOT NULL,
  reporting_period_end DATE NOT NULL,
  submission_date DATE,
  status VARCHAR(20) NOT NULL,
  submitted_by INTEGER REFERENCES users(id),
  report_data JSONB NOT NULL,
  confirmation_reference VARCHAR(100),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### 5.4 Transaction Records

#### 5.4.1 TransactionDetails
```sql
CREATE TABLE transaction_details (
  id SERIAL PRIMARY KEY,
  blockchain_tx_id VARCHAR(100) UNIQUE NOT NULL,
  transaction_type VARCHAR(50) NOT NULL,
  status VARCHAR(20) NOT NULL,
  jurisdiction VARCHAR(50) NOT NULL,
  initiated_by INTEGER REFERENCES users(id),
  initiated_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP,
  value_amount DECIMAL(20,2),
  value_currency VARCHAR(10),
  fee_amount DECIMAL(20,2),
  fee_currency VARCHAR(10),
  metadata JSONB
);
```

#### 5.4.2 TransactionParties
```sql
CREATE TABLE transaction_parties (
  id SERIAL PRIMARY KEY,
  transaction_id INTEGER REFERENCES transaction_details(id),
  user_id INTEGER REFERENCES users(id),
  role VARCHAR(50) NOT NULL,
  signature_status VARCHAR(20),
  signature_timestamp TIMESTAMP,
  signature_method VARCHAR(50),
  signature_evidence VARCHAR(100)
);
```

## 6. Off-Chain Document Database Schema

### 6.1 User Profiles
```json
{
  "_id": "ObjectId",
  "blockchain_address": "String",
  "profile": {
    "display_name": "String",
    "profile_image": "String",
    "bio": "String",
    "preferences": {
      "language": "String",
      "notification_settings": "Object",
      "ui_preferences": "Object"
    }
  },
  "verification_status": {
    "email_verified": "Boolean",
    "phone_verified": "Boolean",
    "identity_verified": "Boolean",
    "address_verified": "Boolean",
    "verification_timestamps": "Object"
  },
  "activity_log": [
    {
      "action": "String",
      "timestamp": "Date",
      "details": "Object"
    }
  ],
  "security": {
    "two_factor_enabled": "Boolean",
    "recovery_options": "Array",
    "last_password_change": "Date",
    "login_history": "Array"
  },
  "created_at": "Date",
  "updated_at": "Date"
}
```

### 6.2 Asset Metadata
```json
{
  "_id": "ObjectId",
  "asset_id": "String",
  "asset_type": "String",
  "title": "String",
  "description": "String",
  "images": ["String"],
  "documents": [
    {
      "title": "String",
      "description": "String",
      "ipfs_hash": "String",
      "document_type": "String"
    }
  ],
  "attributes": {
    "key1": "value1",
    "key2": "value2"
  },
  "history": [
    {
      "action": "String",
      "timestamp": "Date",
      "actor": "String",
      "details": "Object"
    }
  ],
  "jurisdiction_data": {
    "country_code": "String",
    "region": "String",
    "regulatory_classification": "String",
    "compliance_status": "String"
  },
  "created_at": "Date",
  "updated_at": "Date"
}
```

### 6.3 Transaction Logs
```json
{
  "_id": "ObjectId",
  "blockchain_tx_id": "String",
  "transaction_type": "String",
  "status": "String",
  "parties": [
    {
      "address": "String",
      "role": "String",
      "signature_status": "String"
    }
  ],
  "assets": ["String"],
  "timeline": [
    {
      "stage": "String",
      "timestamp": "Date",
      "actor": "String",
      "action": "String",
      "status": "String",
      "notes": "String"
    }
  ],
  "documents": [
    {
      "title": "String",
      "ipfs_hash": "String",
      "document_type": "String"
    }
  ],
  "compliance_checks": [
    {
      "check_type": "String",
      "result": "String",
      "timestamp": "Date",
      "details": "Object"
    }
  ],
  "financial_details": {
    "amount": "Number",
    "currency": "String",
    "payment_method": "String",
    "fees": "Object"
  },
  "metadata": "Object",
  "created_at": "Date",
  "updated_at": "Date"
}
```

### 6.4 Compliance Records
```json
{
  "_id": "ObjectId",
  "entity_type": "String",
  "entity_id": "String",
  "jurisdiction": "String",
  "compliance_type": "String",
  "status": "String",
  "verification_details": {
    "verifier": "String",
    "verification_method": "String",
    "verification_timestamp": "Date",
    "expiration_date": "Date"
  },
  "documents": [
    {
      "document_type": "String",
      "ipfs_hash": "String",
      "submission_date": "Date",
      "verification_status": "String"
    }
  ],
  "audit_trail": [
    {
      "action": "String",
      "actor": "String",
      "timestamp": "Date",
      "details": "String"
    }
  ],
  "regulatory_requirements": {
    "requirement1": "Boolean",
    "requirement2": "Boolean"
  },
  "notes": "String",
  "created_at": "Date",
  "updated_at": "Date"
}
```

## 7. Country-Specific Data Stores

### 7.1 Indonesia Data Store (Data Localization Requirement)
```sql
-- User personal data stored in Indonesia
CREATE TABLE indonesia_user_data (
  id SERIAL PRIMARY KEY,
  global_user_id INTEGER NOT NULL,
  full_name VARCHAR(255),
  national_id_number VARCHAR(100),
  tax_id_number VARCHAR(100),
  residential_address TEXT,
  contact_information JSONB,
  sensitive_data JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Transaction data stored in Indonesia
CREATE TABLE indonesia_transaction_data (
  id SERIAL PRIMARY KEY,
  global_transaction_id VARCHAR(100) NOT NULL,
  transaction_details JSONB NOT NULL,
  party_information JSONB,
  financial_data JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### 7.2 Vietnam Data Store (Stricter E-signature Requirements)
```sql
-- Enhanced signature verification for Vietnam
CREATE TABLE vietnam_signature_verifications (
  id SERIAL PRIMARY KEY,
  global_user_id INTEGER NOT NULL,
  signature_type VARCHAR(50) NOT NULL,
  signature_hash VARCHAR(100) NOT NULL,
  verification_method VARCHAR(50) NOT NULL,
  verification_authority VARCHAR(100),
  verification_timestamp TIMESTAMP NOT NULL,
  certificate_details JSONB,
  is_foreign_signature BOOLEAN NOT NULL,
  representative_office_verification JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

## 8. Data Synchronization and Consistency

### 8.1 Synchronization Mechanisms
- Event-driven architecture for data consistency
- Change Data Capture (CDC) for database synchronization
- Merkle tree verification for on-chain/off-chain consistency

### 8.2 Consistency Checks
```sql
CREATE TABLE data_consistency_checks (
  id SERIAL PRIMARY KEY,
  entity_type VARCHAR(50) NOT NULL,
  entity_id VARCHAR(100) NOT NULL,
  on_chain_hash VARCHAR(100) NOT NULL,
  off_chain_hash VARCHAR(100) NOT NULL,
  is_consistent BOOLEAN NOT NULL,
  check_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
  resolution_action VARCHAR(50),
  resolution_timestamp TIMESTAMP
);
```

## 9. Data Retention and Compliance

### 9.1 Data Retention Policies
```sql
CREATE TABLE data_retention_policies (
  id SERIAL PRIMARY KEY,
  data_type VARCHAR(50) NOT NULL,
  jurisdiction VARCHAR(50) NOT NULL,
  retention_period_days INTEGER NOT NULL,
  legal_basis TEXT NOT NULL,
  deletion_method VARCHAR(50) NOT NULL,
  exceptions TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### 9.2 Data Deletion Records
```sql
CREATE TABLE data_deletion_records (
  id SERIAL PRIMARY KEY,
  data_type VARCHAR(50) NOT NULL,
  entity_id VARCHAR(100) NOT NULL,
  deletion_reason VARCHAR(50) NOT NULL,
  deletion_method VARCHAR(50) NOT NULL,
  performed_by INTEGER REFERENCES users(id),
  deletion_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
  verification_hash VARCHAR(100),
  retention_policy_id INTEGER REFERENCES data_retention_policies(id)
);
```

## 10. Implementation Considerations

### 10.1 Database Technology Selection
- **Blockchain**: Hyperledger Fabric with CouchDB state database
- **Relational Database**: PostgreSQL 14+
- **Document Database**: MongoDB 5+
- **Distributed Storage**: IPFS with Pinata pinning service
- **Caching Layer**: Redis for high-performance caching

### 10.2 Data Security Measures
- Encryption at rest for all databases
- Field-level encryption for sensitive data
- Key management system for encryption keys
- Access control based on roles and jurisdictions
- Audit logging for all data access

### 10.3 Scalability Considerations
- Horizontal scaling for all database components
- Sharding strategy for MongoDB collections
- Read replicas for PostgreSQL databases
- Connection pooling and query optimization
- Caching strategy for frequently accessed data

### 10.4 Disaster Recovery
- Regular database backups
- Point-in-time recovery capability
- Multi-region replication where allowed by regulations
- Automated failover mechanisms
- Recovery time objective (RTO) and recovery point objective (RPO) definitions

## 11. Conclusion

This database schema design provides a comprehensive framework for storing and managing data in our Southeast Asian blockchain solution. The hybrid approach with on-chain and off-chain storage addresses both technical requirements and regulatory compliance needs across all target countries.

The schema is designed to be flexible and adaptable to evolving regulatory requirements while maintaining data integrity, security, and performance. Country-specific data stores ensure compliance with data localization requirements and other jurisdiction-specific regulations.
