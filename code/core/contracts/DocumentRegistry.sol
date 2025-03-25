// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IDocument.sol";
import "../interfaces/ICompliance.sol";

/**
 * @title DocumentRegistry
 * @dev Implementation of the IDocument interface for managing documents across jurisdictions
 */
contract DocumentRegistry is IDocument {
    // Mapping from document ID to document details
    mapping(bytes32 => Document) private _documents;
    
    // Mapping from owner to document IDs
    mapping(address => bytes32[]) private _ownerDocuments;
    
    // Mapping from asset ID to document IDs
    mapping(bytes32 => bytes32[]) private _assetDocuments;
    
    // Mapping from asset ID to document ID to link type
    mapping(bytes32 => mapping(bytes32 => string)) private _documentAssetLinks;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Contract owner
    address private _owner;
    
    // Addresses authorized to verify documents
    mapping(uint8 => mapping(address => bool)) private _authorizedVerifiers;
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "DocumentRegistry: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the document owner
     * @param documentId The ID of the document
     */
    modifier onlyDocumentOwner(bytes32 documentId) {
        require(_documents[documentId].owner == msg.sender, "DocumentRegistry: caller is not the document owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to authorized verifiers for a jurisdiction
     * @param jurisdiction The jurisdiction for which the caller must be authorized
     */
    modifier onlyAuthorizedVerifier(uint8 jurisdiction) {
        require(_authorizedVerifiers[jurisdiction][msg.sender], "DocumentRegistry: caller is not an authorized verifier");
        _;
    }
    
    /**
     * @dev Constructor
     * @param complianceRegistry Address of the compliance registry contract
     */
    constructor(address complianceRegistry) {
        _owner = msg.sender;
        _complianceRegistry = ICompliance(complianceRegistry);
    }
    
    /**
     * @inheritdoc IDocument
     */
    function registerDocument(
        DocumentType documentType,
        bytes32 contentHash,
        bytes32 metadataHash,
        uint8 jurisdiction,
        string calldata language,
        uint256 expirationTime,
        bytes calldata data
    ) external override returns (bytes32 documentId) {
        // Generate a unique document ID
        documentId = keccak256(abi.encodePacked(msg.sender, documentType, contentHash, block.timestamp));
        
        // Create the document
        Document memory document = Document({
            id: documentId,
            documentType: documentType,
            owner: msg.sender,
            contentHash: contentHash,
            metadataHash: metadataHash,
            status: DocumentStatus.DRAFT,
            jurisdiction: jurisdiction,
            language: language,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            expiresAt: expirationTime > 0 ? expirationTime : 0
        });
        
        // Store the document
        _documents[documentId] = document;
        _ownerDocuments[msg.sender].push(documentId);
        
        // Check compliance if a compliance registry is set
        if (address(_complianceRegistry) != address(0)) {
            // Convert jurisdiction to the enum type expected by the compliance registry
            ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
            
            // Check if the document registration is compliant
            (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
                jurisdictionEnum,
                "DOCUMENT_REGISTER",
                abi.encode(msg.sender, uint8(documentType), jurisdiction)
            );
            
            require(isCompliant, "DocumentRegistry: document registration is not compliant");
        }
        
        // Emit the document registration event
        emit DocumentRegistered(
            documentId,
            documentType,
            msg.sender,
            contentHash,
            jurisdiction,
            block.timestamp
        );
        
        return documentId;
    }
    
    /**
     * @inheritdoc IDocument
     */
    function verifyDocument(
        bytes32 documentId,
        bytes calldata verificationData
    ) external override onlyAuthorizedVerifier(_documents[documentId].jurisdiction) returns (bool success) {
        Document storage document = _documents[documentId];
        
        // Check that the document exists
        require(document.id == documentId, "DocumentRegistry: document does not exist");
        
        // Check that the document is in a verifiable state
        require(
            document.status == DocumentStatus.DRAFT || document.status == DocumentStatus.SUBMITTED,
            "DocumentRegistry: document is not in a verifiable state"
        );
        
        // Update the document status
        DocumentStatus previousStatus = document.status;
        document.status = DocumentStatus.VERIFIED;
        document.updatedAt = block.timestamp;
        
        // Emit the document status update event
        emit DocumentStatusUpdated(
            documentId,
            previousStatus,
            DocumentStatus.VERIFIED,
            block.timestamp
        );
        
        // Emit the document verification event
        emit DocumentVerified(
            documentId,
            msg.sender,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc IDocument
     */
    function updateDocumentStatus(
        bytes32 documentId,
        DocumentStatus newStatus,
        bytes calldata data
    ) external override returns (bool success) {
        Document storage document = _documents[documentId];
        
        // Check that the document exists
        require(document.id == documentId, "DocumentRegistry: document does not exist");
        
        // Check that the caller is authorized to update the status
        bool isOwner = document.owner == msg.sender;
        bool isVerifier = _authorizedVerifiers[document.jurisdiction][msg.sender];
        
        // Owner can submit documents
        if (newStatus == DocumentStatus.SUBMITTED) {
            require(isOwner, "DocumentRegistry: only document owner can submit");
        }
        // Only verifiers can verify, reject, or revoke documents
        else if (newStatus == DocumentStatus.VERIFIED || newStatus == DocumentStatus.REJECTED || newStatus == DocumentStatus.REVOKED) {
            require(isVerifier, "DocumentRegistry: only authorized verifiers can verify, reject, or revoke");
        }
        // Other status updates require ownership
        else {
            require(isOwner, "DocumentRegistry: only document owner can update status");
        }
        
        // Store the previous status for the event
        DocumentStatus previousStatus = document.status;
        
        // Update the document status
        document.status = newStatus;
        document.updatedAt = block.timestamp;
        
        // Emit the document status update event
        emit DocumentStatusUpdated(
            documentId,
            previousStatus,
            newStatus,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc IDocument
     */
    function getDocument(bytes32 documentId)
        external
        view
        override
        returns (Document memory document)
    {
        return _documents[documentId];
    }
    
    /**
     * @inheritdoc IDocument
     */
    function verifyDocumentIntegrity(bytes32 documentId, bytes32 contentHash)
        external
        view
        override
        returns (bool isValid)
    {
        return _documents[documentId].contentHash == contentHash;
    }
    
    /**
     * @inheritdoc IDocument
     */
    function getDocumentsByOwner(
        address owner,
        uint8 documentType,
        uint256 startIndex,
        uint256 limit
    ) external view override returns (bytes32[] memory documentIds, uint256 totalCount) {
        bytes32[] storage ownerDocumentIds = _ownerDocuments[owner];
        uint256 ownerDocumentCount = ownerDocumentIds.length;
        
        // Count documents of the specified type
        if (documentType > 0) {
            uint256 typeCount = 0;
            for (uint256 i = 0; i < ownerDocumentCount; i++) {
                if (uint8(_documents[ownerDocumentIds[i]].documentType) == documentType) {
                    typeCount++;
                }
            }
            totalCount = typeCount;
        } else {
            totalCount = ownerDocumentCount;
        }
        
        // Handle pagination
        uint256 resultCount = limit;
        if (startIndex + resultCount > totalCount) {
            resultCount = totalCount > startIndex ? totalCount - startIndex : 0;
        }
        
        // Create the result array
        documentIds = new bytes32[](resultCount);
        
        // Fill the result array
        if (resultCount > 0) {
            uint256 resultIndex = 0;
            
            for (uint256 i = 0; i < ownerDocumentCount && resultIndex < resultCount; i++) {
                bytes32 currentDocumentId = ownerDocumentIds[i];
                
                // Filter by document type if specified
                if (documentType > 0 && uint8(_documents[currentDocumentId].documentType) != documentType) {
                    continue;
                }
                
                // Skip documents before the start index
                if (i < startIndex) {
                    continue;
                }
                
                documentIds[resultIndex] = currentDocumentId;
                resultIndex++;
            }
        }
        
        return (documentIds, totalCount);
    }
    
    /**
     * @inheritdoc IDocument
     */
    function linkDocumentToAsset(
        bytes32 documentId,
        bytes32 assetId,
        string calldata linkType
    ) external override onlyDocumentOwner(documentId) returns (bool success) {
        // Check that the document exists
        require(_documents[documentId].id == documentId, "DocumentRegistry: document does not exist");
        
        // Store the link
        _assetDocuments[assetId].push(documentId);
        _documentAssetLinks[assetId][documentId] = linkType;
        
        return true;
    }
    
    /**
     * @inheritdoc IDocument
     */
    function getDocumentsByAsset(bytes32 assetId, string calldata linkType)
        external
        view
        override
        returns (bytes32[] memory documentIds)
    {
        bytes32[] storage assetDocumentIds = _assetDocuments[assetId];
        
        // If no link type filter, return all documents
        if (bytes(linkType).length == 0) {
            return assetDocumentIds;
        }
        
        // Count documents with the specified link type
        uint256 matchingCount = 0;
        for (uint256 i = 0; i < assetDocumentIds.length; i++) {
            bytes32 documentId = assetDocumentIds[i];
            if (keccak256(bytes(_documentAssetLinks[assetId][documentId])) == keccak256(bytes(linkType))) {
                matchingCount++;
            }
        }
        
        // Create the result array
        documentIds = new bytes32[](matchingCount);
        
        // Fill the result array
        uint256 resultIndex = 0;
        for (uint256 i = 0; i < assetDocumentIds.length && resultIndex < matchingCount; i++) {
            bytes32 documentId = assetDocumentIds[i];
            if (keccak256(bytes(_documentAssetLinks[assetId][documentId])) == keccak256(bytes(linkType))) {
                documentIds[resultIndex] = documentId;
                resultIndex++;
            }
        }
        
        return documentIds;
    }
    
    /**
     * @dev Authorizes a verifier for a jurisdiction
     * @param jurisdiction The jurisdiction for which to authorize the verifier
     * @param verifier The address to authorize
     * @return success Whether the authorization was successful
     */
    function authorizeVerifier(uint8 jurisdiction, address verifier) external onlyOwner returns (bool success) {
        _authorizedVerifiers[jurisdiction][verifier] = true;
        return true;
    }
    
    /**
     * @dev Revokes authorization from a verifier for a jurisdiction
     * @param jurisdiction The jurisdiction for which to revoke authorization
     * @param verifier The address to revoke authorization from
     * @return success Whether the revocation was successful
     */
    function revokeVerifier(uint8 jurisdiction, address verifier) external onlyOwner returns (bool success) {
        _authorizedVerifiers[jurisdiction][verifier] = false;
        return true;
    }
    
    /**
     * @dev Sets the compliance registry address
     * @param complianceRegistry Address of the compliance registry contract
     * @return success Whether the update was successful
     */
    function setComplianceRegistry(address complianceRegistry) external onlyOwner returns (bool success) {
        _complianceRegistry = ICompliance(complianceRegistry);
        return true;
    }
    
    /**
     * @dev Checks if a verifier is authorized for a jurisdiction
     * @param jurisdiction The jurisdiction to check
     * @param verifier The address to check
     * @return isAuthorized Whether the verifier is authorized
     */
    function isAuthorizedVerifier(uint8 jurisdiction, address verifier)
        external
        view
        returns (bool isAuthorized)
    {
        return _authorizedVerifiers[jurisdiction][verifier];
    }
}
