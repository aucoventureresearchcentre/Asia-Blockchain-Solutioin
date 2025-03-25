// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IDocument
 * @dev Interface for document management across different jurisdictions
 * @notice This interface defines the standard methods for document creation, verification, and management
 */
interface IDocument {
    /**
     * @dev Enum representing the document types
     */
    enum DocumentType {
        IDENTITY,
        PROPERTY_TITLE,
        CONTRACT,
        CERTIFICATE,
        INVOICE,
        RECEIPT,
        INSURANCE_POLICY,
        REGULATORY_FILING,
        OTHER
    }

    /**
     * @dev Enum representing the document status
     */
    enum DocumentStatus {
        DRAFT,
        SUBMITTED,
        VERIFIED,
        REJECTED,
        EXPIRED,
        REVOKED
    }

    /**
     * @dev Struct containing document details
     */
    struct Document {
        bytes32 id;
        DocumentType documentType;
        address owner;
        bytes32 contentHash;
        bytes32 metadataHash;
        DocumentStatus status;
        uint8 jurisdiction;
        string language;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 expiresAt;
    }

    /**
     * @dev Event emitted when a document is registered
     */
    event DocumentRegistered(
        bytes32 indexed documentId,
        DocumentType indexed documentType,
        address indexed owner,
        bytes32 contentHash,
        uint8 jurisdiction,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when a document status is updated
     */
    event DocumentStatusUpdated(
        bytes32 indexed documentId,
        DocumentStatus previousStatus,
        DocumentStatus newStatus,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when a document is verified
     */
    event DocumentVerified(
        bytes32 indexed documentId,
        address indexed verifier,
        uint256 timestamp
    );

    /**
     * @dev Registers a new document
     * @param documentType The type of document to register
     * @param contentHash Hash of the document content (typically IPFS hash)
     * @param metadataHash Hash of the document metadata (typically IPFS hash)
     * @param jurisdiction The jurisdiction code for the document
     * @param language The language code of the document
     * @param expirationTime Time when the document expires (0 for no expiration)
     * @param data Additional data required for document registration
     * @return documentId The unique identifier for the registered document
     */
    function registerDocument(
        DocumentType documentType,
        bytes32 contentHash,
        bytes32 metadataHash,
        uint8 jurisdiction,
        string calldata language,
        uint256 expirationTime,
        bytes calldata data
    ) external returns (bytes32 documentId);

    /**
     * @dev Verifies a document
     * @param documentId The unique identifier of the document
     * @param verificationData Additional data for the verification
     * @return success Whether the verification was successful
     */
    function verifyDocument(
        bytes32 documentId,
        bytes calldata verificationData
    ) external returns (bool success);

    /**
     * @dev Updates the status of a document
     * @param documentId The unique identifier of the document
     * @param newStatus The new status for the document
     * @param data Additional data required for the status update
     * @return success Whether the status update was successful
     */
    function updateDocumentStatus(
        bytes32 documentId,
        DocumentStatus newStatus,
        bytes calldata data
    ) external returns (bool success);

    /**
     * @dev Gets the details of a document
     * @param documentId The unique identifier of the document
     * @return document The document details
     */
    function getDocument(bytes32 documentId)
        external
        view
        returns (Document memory document);

    /**
     * @dev Verifies the integrity of a document by comparing its hash
     * @param documentId The unique identifier of the document
     * @param contentHash The hash to verify against
     * @return isValid Whether the document hash is valid
     */
    function verifyDocumentIntegrity(bytes32 documentId, bytes32 contentHash)
        external
        view
        returns (bool isValid);

    /**
     * @dev Gets the documents owned by an address
     * @param owner The address to check
     * @param documentType Optional filter by document type (0 for all types)
     * @param startIndex Start index for pagination
     * @param limit Maximum number of documents to return
     * @return documentIds Array of document IDs owned by the address
     * @return totalCount Total number of documents owned by the address
     */
    function getDocumentsByOwner(
        address owner,
        uint8 documentType,
        uint256 startIndex,
        uint256 limit
    ) external view returns (bytes32[] memory documentIds, uint256 totalCount);

    /**
     * @dev Links a document to an asset
     * @param documentId The unique identifier of the document
     * @param assetId The unique identifier of the asset
     * @param linkType The type of link between document and asset
     * @return success Whether the link was successful
     */
    function linkDocumentToAsset(
        bytes32 documentId,
        bytes32 assetId,
        string calldata linkType
    ) external returns (bool success);

    /**
     * @dev Gets the documents linked to an asset
     * @param assetId The unique identifier of the asset
     * @param linkType Optional filter by link type (empty string for all types)
     * @return documentIds Array of document IDs linked to the asset
     */
    function getDocumentsByAsset(bytes32 assetId, string calldata linkType)
        external
        view
        returns (bytes32[] memory documentIds);
}
