// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/ITransaction.sol";
import "../interfaces/IAsset.sol";
import "../interfaces/ICompliance.sol";

/**
 * @title TransactionManager
 * @dev Implementation of the ITransaction interface for managing transactions across jurisdictions
 */
contract TransactionManager is ITransaction {
    // Mapping from transaction ID to transaction details
    mapping(bytes32 => Transaction) private _transactions;
    
    // Mapping from party address to transaction IDs
    mapping(address => bytes32[]) private _partyTransactions;
    
    // Mapping from asset ID to transaction IDs
    mapping(bytes32 => bytes32[]) private _assetTransactions;
    
    // Asset registry interface
    IAsset private _assetRegistry;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Contract owner
    address private _owner;
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "TransactionManager: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to transaction parties
     * @param transactionId The ID of the transaction
     */
    modifier onlyTransactionParty(bytes32 transactionId) {
        bool isParty = false;
        Transaction storage transaction = _transactions[transactionId];
        
        for (uint256 i = 0; i < transaction.parties.length; i++) {
            if (transaction.parties[i].partyAddress == msg.sender) {
                isParty = true;
                break;
            }
        }
        
        require(isParty, "TransactionManager: caller is not a transaction party");
        _;
    }
    
    /**
     * @dev Constructor
     * @param assetRegistry Address of the asset registry contract
     * @param complianceRegistry Address of the compliance registry contract
     */
    constructor(address assetRegistry, address complianceRegistry) {
        _owner = msg.sender;
        _assetRegistry = IAsset(assetRegistry);
        _complianceRegistry = ICompliance(complianceRegistry);
    }
    
    /**
     * @inheritdoc ITransaction
     */
    function createTransaction(
        TransactionType transactionType,
        uint8 jurisdiction,
        bytes32[] calldata assetIds,
        TransactionParty[] calldata parties,
        bytes32 metadataHash,
        uint256 expirationTime,
        bytes calldata data
    ) external override returns (bytes32 transactionId) {
        // Generate a unique transaction ID
        transactionId = keccak256(abi.encodePacked(msg.sender, transactionType, metadataHash, block.timestamp));
        
        // Validate that the caller is one of the parties
        bool callerIsParty = false;
        for (uint256 i = 0; i < parties.length; i++) {
            if (parties[i].partyAddress == msg.sender) {
                callerIsParty = true;
                break;
            }
        }
        require(callerIsParty, "TransactionManager: caller must be a transaction party");
        
        // Create the transaction
        Transaction storage transaction = _transactions[transactionId];
        transaction.id = transactionId;
        transaction.transactionType = transactionType;
        transaction.status = TransactionStatus.CREATED;
        transaction.jurisdiction = jurisdiction;
        transaction.metadataHash = metadataHash;
        transaction.createdAt = block.timestamp;
        transaction.updatedAt = block.timestamp;
        transaction.expiresAt = expirationTime > 0 ? expirationTime : 0;
        
        // Add assets to the transaction
        for (uint256 i = 0; i < assetIds.length; i++) {
            transaction.assetIds.push(assetIds[i]);
            _assetTransactions[assetIds[i]].push(transactionId);
        }
        
        // Add parties to the transaction
        for (uint256 i = 0; i < parties.length; i++) {
            TransactionParty memory party = parties[i];
            
            // Mark the creator as having signed
            if (party.partyAddress == msg.sender) {
                party.hasSigned = true;
                party.signatureTimestamp = block.timestamp;
            } else {
                party.hasSigned = false;
                party.signatureTimestamp = 0;
            }
            
            transaction.parties.push(party);
            _partyTransactions[party.partyAddress].push(transactionId);
        }
        
        // Check compliance if a compliance registry is set
        if (address(_complianceRegistry) != address(0)) {
            // Convert jurisdiction to the enum type expected by the compliance registry
            ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
            
            // Check if the transaction creation is compliant
            (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
                jurisdictionEnum,
                "TRANSACTION_CREATE",
                abi.encode(msg.sender, transactionType, jurisdiction)
            );
            
            require(isCompliant, "TransactionManager: transaction creation is not compliant");
        }
        
        // Emit the transaction creation event
        emit TransactionCreated(
            transactionId,
            transactionType,
            msg.sender,
            jurisdiction,
            block.timestamp
        );
        
        // If the creator has signed, emit the signature event
        emit TransactionSigned(
            transactionId,
            msg.sender,
            getPartyRole(transactionId, msg.sender),
            block.timestamp
        );
        
        return transactionId;
    }
    
    /**
     * @inheritdoc ITransaction
     */
    function signTransaction(
        bytes32 transactionId,
        bytes calldata signatureData
    ) external override onlyTransactionParty(transactionId) returns (bool success) {
        Transaction storage transaction = _transactions[transactionId];
        
        // Check that the transaction is in a signable state
        require(
            transaction.status == TransactionStatus.CREATED || transaction.status == TransactionStatus.PENDING,
            "TransactionManager: transaction is not in a signable state"
        );
        
        // Check that the transaction has not expired
        if (transaction.expiresAt > 0) {
            require(block.timestamp <= transaction.expiresAt, "TransactionManager: transaction has expired");
        }
        
        // Find the party and mark as signed
        bool found = false;
        for (uint256 i = 0; i < transaction.parties.length; i++) {
            if (transaction.parties[i].partyAddress == msg.sender) {
                require(!transaction.parties[i].hasSigned, "TransactionManager: party has already signed");
                transaction.parties[i].hasSigned = true;
                transaction.parties[i].signatureTimestamp = block.timestamp;
                found = true;
                break;
            }
        }
        
        require(found, "TransactionManager: caller is not a transaction party");
        
        // Update transaction status to pending if it was just created
        if (transaction.status == TransactionStatus.CREATED) {
            transaction.status = TransactionStatus.PENDING;
            transaction.updatedAt = block.timestamp;
            
            emit TransactionStatusUpdated(
                transactionId,
                TransactionStatus.CREATED,
                TransactionStatus.PENDING,
                block.timestamp
            );
        }
        
        // Emit the signature event
        emit TransactionSigned(
            transactionId,
            msg.sender,
            getPartyRole(transactionId, msg.sender),
            block.timestamp
        );
        
        // Check if all parties have signed
        bool allSigned = true;
        for (uint256 i = 0; i < transaction.parties.length; i++) {
            if (!transaction.parties[i].hasSigned) {
                allSigned = false;
                break;
            }
        }
        
        // If all parties have signed, the transaction is ready for execution
        if (allSigned) {
            transaction.status = TransactionStatus.APPROVED;
            transaction.updatedAt = block.timestamp;
            
            emit TransactionStatusUpdated(
                transactionId,
                TransactionStatus.PENDING,
                TransactionStatus.APPROVED,
                block.timestamp
            );
        }
        
        return true;
    }
    
    /**
     * @inheritdoc ITransaction
     */
    function executeTransaction(
        bytes32 transactionId,
        bytes calldata executionData
    ) external override onlyTransactionParty(transactionId) returns (bool success) {
        Transaction storage transaction = _transactions[transactionId];
        
        // Check that the transaction is approved
        require(
            transaction.status == TransactionStatus.APPROVED,
            "TransactionManager: transaction is not approved"
        );
        
        // Check that the transaction has not expired
        if (transaction.expiresAt > 0) {
            require(block.timestamp <= transaction.expiresAt, "TransactionManager: transaction has expired");
        }
        
        // Check compliance if a compliance registry is set
        if (address(_complianceRegistry) != address(0)) {
            // Convert jurisdiction to the enum type expected by the compliance registry
            ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(transaction.jurisdiction);
            
            // Check if the transaction execution is compliant
            (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
                jurisdictionEnum,
                "TRANSACTION_EXECUTE",
                abi.encode(msg.sender, transactionId)
            );
            
            require(isCompliant, "TransactionManager: transaction execution is not compliant");
        }
        
        // Execute the transaction based on its type
        // This is a simplified implementation
        // In a production environment, you would have more complex execution logic
        
        // Update the transaction status
        transaction.status = TransactionStatus.EXECUTED;
        transaction.updatedAt = block.timestamp;
        
        // Emit the status update event
        emit TransactionStatusUpdated(
            transactionId,
            TransactionStatus.APPROVED,
            TransactionStatus.EXECUTED,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc ITransaction
     */
    function cancelTransaction(
        bytes32 transactionId,
        string calldata reason
    ) external override onlyTransactionParty(transactionId) returns (bool success) {
        Transaction storage transaction = _transactions[transactionId];
        
        // Check that the transaction is not already executed or cancelled
        require(
            transaction.status != TransactionStatus.EXECUTED &&
            transaction.status != TransactionStatus.CANCELLED,
            "TransactionManager: transaction cannot be cancelled"
        );
        
        // Update the transaction status
        TransactionStatus previousStatus = transaction.status;
        transaction.status = TransactionStatus.CANCELLED;
        transaction.updatedAt = block.timestamp;
        
        // Emit the status update event
        emit TransactionStatusUpdated(
            transactionId,
            previousStatus,
            TransactionStatus.CANCELLED,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc ITransaction
     */
    function getTransaction(bytes32 transactionId)
        external
        view
        override
        returns (Transaction memory transaction)
    {
        return _transactions[transactionId];
    }
    
    /**
     * @inheritdoc ITransaction
     */
    function getTransactionsByParty(
        address partyAddress,
        uint8 transactionType,
        uint8 status,
        uint256 startIndex,
        uint256 limit
    ) external view override returns (bytes32[] memory transactionIds, uint256 totalCount) {
        bytes32[] storage partyTransactionIds = _partyTransactions[partyAddress];
        uint256 partyTransactionCount = partyTransactionIds.length;
        
        // Count transactions matching the filters
        uint256 matchingCount = 0;
        for (uint256 i = 0; i < partyTransactionCount; i++) {
            bytes32 txId = partyTransactionIds[i];
            Transaction storage tx = _transactions[txId];
            
            if ((transactionType == 0 || uint8(tx.transactionType) == transactionType) &&
                (status == 0 || uint8(tx.status) == status)) {
                matchingCount++;
            }
        }
        
        totalCount = matchingCount;
        
        // Handle pagination
        uint256 resultCount = limit;
        if (startIndex + resultCount > totalCount) {
            resultCount = totalCount > startIndex ? totalCount - startIndex : 0;
        }
        
        // Create the result array
        transactionIds = new bytes32[](resultCount);
        
        // Fill the result array
        if (resultCount > 0) {
            uint256 resultIndex = 0;
            uint256 matchIndex = 0;
            
            for (uint256 i = 0; i < partyTransactionCount && resultIndex < resultCount; i++) {
                bytes32 txId = partyTransactionIds[i];
                Transaction storage tx = _transactions[txId];
                
                if ((transactionType == 0 || uint8(tx.transactionType) == transactionType) &&
                    (status == 0 || uint8(tx.status) == status)) {
                    
                    if (matchIndex >= startIndex) {
                        transactionIds[resultIndex] = txId;
                        resultIndex++;
                    }
                    matchIndex++;
                }
            }
        }
        
        return (transactionIds, totalCount);
    }
    
    /**
     * @inheritdoc ITransaction
     */
    function getTransactionsByAsset(
        bytes32 assetId,
        uint256 startIndex,
        uint256 limit
    ) external view override returns (bytes32[] memory transactionIds, uint256 totalCount) {
        bytes32[] storage assetTransactionIds = _assetTransactions[assetId];
        totalCount = assetTransactionIds.length;
        
        // Handle pagination
        uint256 resultCount = limit;
        if (startIndex + resultCount > totalCount) {
            resultCount = totalCount > startIndex ? totalCount - startIndex : 0;
        }
        
        // Create the result array
        transactionIds = new bytes32[](resultCount);
        
        // Fill the result array
        for (uint256 i = 0; i < resultCount; i++) {
            transactionIds[i] = assetTransactionIds[startIndex + i];
        }
        
        return (transactionIds, totalCount);
    }
    
    /**
     * @dev Gets the role of a party in a transaction
     * @param transactionId The ID of the transaction
     * @param partyAddress The address of the party
     * @return role The role of the party
     */
    function getPartyRole(bytes32 transactionId, address partyAddress) public view returns (string memory role) {
        Transaction storage transaction = _transactions[transactionId];
        
        for (uint256 i = 0; i < transaction.parties.length; i++) {
            if (transaction.parties[i].partyAddress == partyAddress) {
                return transaction.parties[i].role;
            }
        }
        
        return "";
    }
    
    /**
     * @dev Sets the asset registry address
     * @param assetRegistry Address of the asset registry contract
     * @return success Whether the update was successful
     */
    function setAssetRegistry(address assetRegistry) external onlyOwner returns (bool success) {
        _assetRegistry = IAsset(assetRegistry);
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
}
