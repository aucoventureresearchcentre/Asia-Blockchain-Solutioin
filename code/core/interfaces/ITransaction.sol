// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ITransaction
 * @dev Interface for transaction management across different jurisdictions
 * @notice This interface defines the standard methods for transaction creation, execution, and management
 */
interface ITransaction {
    /**
     * @dev Enum representing the transaction types
     */
    enum TransactionType {
        ASSET_TRANSFER,
        CONTRACT_EXECUTION,
        PAYMENT,
        CLAIM_PROCESSING,
        DOCUMENT_VERIFICATION
    }

    /**
     * @dev Enum representing the transaction status
     */
    enum TransactionStatus {
        CREATED,
        PENDING,
        APPROVED,
        REJECTED,
        EXECUTED,
        CANCELLED,
        EXPIRED
    }

    /**
     * @dev Struct containing party information for a transaction
     */
    struct TransactionParty {
        address partyAddress;
        string role;
        bool hasSigned;
        uint256 signatureTimestamp;
    }

    /**
     * @dev Struct containing transaction details
     */
    struct Transaction {
        bytes32 id;
        TransactionType transactionType;
        TransactionStatus status;
        uint8 jurisdiction;
        bytes32[] assetIds;
        TransactionParty[] parties;
        bytes32 metadataHash;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 expiresAt;
    }

    /**
     * @dev Event emitted when a transaction is created
     */
    event TransactionCreated(
        bytes32 indexed transactionId,
        TransactionType indexed transactionType,
        address indexed initiator,
        uint8 jurisdiction,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when a transaction is signed by a party
     */
    event TransactionSigned(
        bytes32 indexed transactionId,
        address indexed signer,
        string role,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when a transaction status is updated
     */
    event TransactionStatusUpdated(
        bytes32 indexed transactionId,
        TransactionStatus previousStatus,
        TransactionStatus newStatus,
        uint256 timestamp
    );

    /**
     * @dev Creates a new transaction
     * @param transactionType The type of transaction to create
     * @param jurisdiction The jurisdiction code for the transaction
     * @param assetIds Array of asset IDs involved in the transaction
     * @param parties Array of party addresses and roles
     * @param metadataHash IPFS hash of the transaction metadata
     * @param expirationTime Time when the transaction expires (0 for no expiration)
     * @param data Additional data required for transaction creation
     * @return transactionId The unique identifier for the created transaction
     */
    function createTransaction(
        TransactionType transactionType,
        uint8 jurisdiction,
        bytes32[] calldata assetIds,
        TransactionParty[] calldata parties,
        bytes32 metadataHash,
        uint256 expirationTime,
        bytes calldata data
    ) external returns (bytes32 transactionId);

    /**
     * @dev Signs a transaction
     * @param transactionId The unique identifier of the transaction
     * @param signatureData Additional data for the signature
     * @return success Whether the signing was successful
     */
    function signTransaction(
        bytes32 transactionId,
        bytes calldata signatureData
    ) external returns (bool success);

    /**
     * @dev Executes a transaction
     * @param transactionId The unique identifier of the transaction
     * @param executionData Additional data required for execution
     * @return success Whether the execution was successful
     */
    function executeTransaction(
        bytes32 transactionId,
        bytes calldata executionData
    ) external returns (bool success);

    /**
     * @dev Cancels a transaction
     * @param transactionId The unique identifier of the transaction
     * @param reason Reason for cancellation
     * @return success Whether the cancellation was successful
     */
    function cancelTransaction(
        bytes32 transactionId,
        string calldata reason
    ) external returns (bool success);

    /**
     * @dev Gets the details of a transaction
     * @param transactionId The unique identifier of the transaction
     * @return transaction The transaction details
     */
    function getTransaction(bytes32 transactionId)
        external
        view
        returns (Transaction memory transaction);

    /**
     * @dev Gets the transactions involving a specific party
     * @param partyAddress The address of the party
     * @param transactionType Optional filter by transaction type (0 for all types)
     * @param status Optional filter by status (0 for all statuses)
     * @param startIndex Start index for pagination
     * @param limit Maximum number of transactions to return
     * @return transactionIds Array of transaction IDs involving the party
     * @return totalCount Total number of transactions involving the party
     */
    function getTransactionsByParty(
        address partyAddress,
        uint8 transactionType,
        uint8 status,
        uint256 startIndex,
        uint256 limit
    ) external view returns (bytes32[] memory transactionIds, uint256 totalCount);

    /**
     * @dev Gets the transactions involving a specific asset
     * @param assetId The unique identifier of the asset
     * @param startIndex Start index for pagination
     * @param limit Maximum number of transactions to return
     * @return transactionIds Array of transaction IDs involving the asset
     * @return totalCount Total number of transactions involving the asset
     */
    function getTransactionsByAsset(
        bytes32 assetId,
        uint256 startIndex,
        uint256 limit
    ) external view returns (bytes32[] memory transactionIds, uint256 totalCount);
}
