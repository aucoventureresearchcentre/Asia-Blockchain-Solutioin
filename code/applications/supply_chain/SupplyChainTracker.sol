// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IAsset.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IDocument.sol";
import "../../core/interfaces/ITransaction.sol";

/**
 * @title SupplyChainTracker
 * @dev Implementation for tracking supply chain transactions across Southeast Asian jurisdictions
 */
contract SupplyChainTracker {
    // Asset registry interface
    IAsset private _assetRegistry;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Document registry interface
    IDocument private _documentRegistry;
    
    // Transaction manager interface
    ITransaction private _transactionManager;
    
    // SupplyChainItem contract address
    address private _supplyChainItem;
    
    // Contract owner
    address private _owner;
    
    // Mapping from transaction ID to verification details
    mapping(bytes32 => VerificationRecord) private _verifications;
    
    // Struct containing verification record details
    struct VerificationRecord {
        bytes32 transactionId;
        bytes32 itemId;
        address verifier;
        bool isVerified;
        string notes;
        uint256 timestamp;
    }
    
    // Events
    event ItemVerified(
        bytes32 indexed transactionId,
        bytes32 indexed itemId,
        address indexed verifier,
        bool isVerified,
        uint256 timestamp
    );
    
    event BatchVerified(
        bytes32 indexed transactionId,
        bytes32 indexed batchId,
        address indexed verifier,
        bool isVerified,
        uint256 timestamp
    );
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "SupplyChainTracker: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to authorized verifiers
     */
    modifier onlyVerifier() {
        // In a production environment, this would check against a list of authorized verifiers
        // For simplicity, we're allowing the contract owner to be a verifier
        require(msg.sender == _owner, "SupplyChainTracker: caller is not an authorized verifier");
        _;
    }
    
    /**
     * @dev Constructor
     * @param assetRegistry Address of the asset registry contract
     * @param complianceRegistry Address of the compliance registry contract
     * @param documentRegistry Address of the document registry contract
     * @param transactionManager Address of the transaction manager contract
     * @param supplyChainItem Address of the supply chain item contract
     */
    constructor(
        address assetRegistry,
        address complianceRegistry,
        address documentRegistry,
        address transactionManager,
        address supplyChainItem
    ) {
        _owner = msg.sender;
        _assetRegistry = IAsset(assetRegistry);
        _complianceRegistry = ICompliance(complianceRegistry);
        _documentRegistry = IDocument(documentRegistry);
        _transactionManager = ITransaction(transactionManager);
        _supplyChainItem = supplyChainItem;
    }
    
    /**
     * @dev Creates a verification transaction for an item
     * @param itemId The ID of the item to verify
     * @param documentIds Array of document IDs associated with the verification
     * @param expirationTime Time when the transaction expires (0 for no expiration)
     * @return transactionId The unique identifier for the transaction
     */
    function createVerificationTransaction(
        bytes32 itemId,
        bytes32[] calldata documentIds,
        uint256 expirationTime
    ) external returns (bytes32 transactionId) {
        // Get the item details from the SupplyChainItem contract
        (
            bytes32 id,
            string memory name,
            string memory description,
            string memory manufacturer,
            uint8 originJurisdiction,
            uint8 currentJurisdiction,
            bytes32 assetId,
            address owner,
            bytes32 batchId,
            uint status,
            uint256 createdAt,
            uint256 updatedAt
        ) = getSupplyChainItem(itemId);
        
        // Create transaction parties
        ITransaction.TransactionParty[] memory parties = new ITransaction.TransactionParty[](2);
        
        // Item owner party
        parties[0] = ITransaction.TransactionParty({
            partyAddress: owner,
            role: "ITEM_OWNER",
            hasSigned: false,
            signatureTimestamp: 0
        });
        
        // Verifier party
        parties[1] = ITransaction.TransactionParty({
            partyAddress: msg.sender,
            role: "VERIFIER",
            hasSigned: false,
            signatureTimestamp: 0
        });
        
        // Create the transaction
        bytes32[] memory assetIds = new bytes32[](1);
        assetIds[0] = assetId;
        
        transactionId = _transactionManager.createTransaction(
            ITransaction.TransactionType.DOCUMENT_VERIFICATION,
            currentJurisdiction,
            assetIds,
            parties,
            keccak256(abi.encodePacked(itemId, "VERIFICATION")),
            expirationTime,
            abi.encode(itemId)
        );
        
        // Link documents to the transaction
        for (uint256 i = 0; i < documentIds.length; i++) {
            bytes32 docId = documentIds[i];
            _documentRegistry.linkDocumentToAsset(docId, assetId, "VERIFICATION_DOCUMENT");
        }
        
        // Create a verification record
        VerificationRecord memory record = VerificationRecord({
            transactionId: transactionId,
            itemId: itemId,
            verifier: address(0), // Will be set when verified
            isVerified: false,
            notes: "",
            timestamp: 0
        });
        
        // Store the verification record
        _verifications[transactionId] = record;
        
        return transactionId;
    }
    
    /**
     * @dev Signs a verification transaction
     * @param transactionId The ID of the transaction
     * @return success Whether the signing was successful
     */
    function signVerificationTransaction(bytes32 transactionId) external returns (bool success) {
        // Sign the transaction
        success = _transactionManager.signTransaction(transactionId, "");
        return success;
    }
    
    /**
     * @dev Verifies an item
     * @param transactionId The ID of the verification transaction
     * @param isVerified Whether the item is verified
     * @param notes Additional notes about the verification
     * @return success Whether the verification was successful
     */
    function verifyItem(bytes32 transactionId, bool isVerified, string calldata notes)
        external
        onlyVerifier
        returns (bool success)
    {
        // Get the transaction details
        ITransaction.Transaction memory transaction = _transactionManager.getTransaction(transactionId);
        
        // Check that the transaction is approved
        require(
            transaction.status == ITransaction.TransactionStatus.APPROVED,
            "SupplyChainTracker: transaction is not approved"
        );
        
        // Get the verification record
        VerificationRecord storage record = _verifications[transactionId];
        
        // Check that the record exists
        require(record.transactionId == transactionId, "SupplyChainTracker: verification record does not exist");
        
        // Check that the item has not been verified yet
        require(!record.isVerified, "SupplyChainTracker: item has already been verified");
        
        // Update the verification record
        record.verifier = msg.sender;
        record.isVerified = isVerified;
        record.notes = notes;
        record.timestamp = block.timestamp;
        
        // Execute the transaction in the transaction manager
        success = _transactionManager.executeTransaction(transactionId, "");
        
        // Emit the item verified event
        emit ItemVerified(
            transactionId,
            record.itemId,
            msg.sender,
            isVerified,
            block.timestamp
        );
        
        return success;
    }
    
    /**
     * @dev Verifies a batch of items
     * @param batchId The ID of the batch
     * @param isVerified Whether the batch is verified
     * @param notes Additional notes about the verification
     * @return success Whether the verification was successful
     */
    function verifyBatch(bytes32 batchId, bool isVerified, string calldata notes)
        external
        onlyVerifier
        returns (bool success)
    {
        // Get the items in the batch
        bytes32[] memory itemIds = getBatchItems(batchId);
        
        // Check that the batch has items
        require(itemIds.length > 0, "SupplyChainTracker: batch has no items");
        
        // Create a transaction for the batch verification
        bytes32 transactionId = keccak256(abi.encodePacked(batchId, block.timestamp));
        
        // Verify each item in the batch
        for (uint256 i = 0; i < itemIds.length; i++) {
            // Create a verification record for each item
            VerificationRecord memory record = VerificationRecord({
                transactionId: transactionId,
                itemId: itemIds[i],
                verifier: msg.sender,
                isVerified: isVerified,
                notes: notes,
                timestamp: block.timestamp
            });
            
            // Store the verification record
            _verifications[keccak256(abi.encodePacked(transactionId, itemIds[i]))] = record;
            
            // Emit the item verified event
            emit ItemVerified(
                transactionId,
                itemIds[i],
                msg.sender,
                isVerified,
                block.timestamp
            );
        }
        
        // Emit the batch verified event
        emit BatchVerified(
            transactionId,
            batchId,
            msg.sender,
            isVerified,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Gets the verification record for a transaction
     * @param transactionId The ID of the transaction
     * @return record The verification record
     */
    function getVerificationRecord(bytes32 transactionId) external view returns (VerificationRecord memory record) {
        return _verifications[transactionId];
    }
    
    /**
     * @dev Gets an item from the SupplyChainItem contract
     * @param itemId The ID of the item
     * @return Item details
     */
    function getSupplyChainItem(bytes32 itemId) internal view returns (
        bytes32 id,
        string memory name,
        string memory description,
        string memory manufacturer,
        uint8 originJurisdiction,
        uint8 currentJurisdiction,
        bytes32 assetId,
        address owner,
        bytes32 batchId,
        uint status,
        uint256 createdAt,
        uint256 updatedAt
    ) {
        // Call the SupplyChainItem contract to get the item details
        bytes memory data = abi.encodeWithSignature("getItem(bytes32)", itemId);
        (bool success, bytes memory returnData) = _supplyChainItem.staticcall(data);
        
        require(success, "SupplyChainTracker: failed to get item");
        
        // Decode the item details
        return abi.decode(returnData, (
            bytes32,
            string,
            string,
            string,
            uint8,
            uint8,
            bytes32,
            address,
            bytes32,
            uint,
            uint256,
            uint256
        ));
    }
    
    /**
     * @dev Gets the items in a batch from the SupplyChainItem contract
     * @param batchId The ID of the batch
     * @return itemIds Array of item IDs in the batch
     */
    function getBatchItems(bytes32 batchId) internal view returns (bytes32[] memory itemIds) {
        // Call the SupplyChainItem contract to get the batch items
        bytes memory data = abi.encodeWithSignature("getBatchItems(bytes32)", batchId);
        (bool success, bytes memory returnData) = _supplyChainItem.staticcall(data);
        
        require(success, "SupplyChainTracker: failed to get batch items");
        
        // Decode the batch items
        return abi.decode(returnData, (bytes32[]));
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
    
    /**
     * @dev Sets the document registry address
     * @param documentRegistry Address of the document registry contract
     * @return success Whether the update was successful
     */
    function setDocumentRegistry(address documentRegistry) external onlyOwner returns (bool success) {
        _documentRegistry = IDocument(documentRegistry);
        return true;
    }
    
    /**
     * @dev Sets the transaction manager address
     * @param transactionManager Address of the transaction manager contract
     * @return success Whether the update was successful
     */
    function setTransactionManager(address transactionManager) external onlyOwner returns (bool success) {
        _transactionManager = ITransaction(transactionManager);
        return true;
    }
    
    /**
     * @dev Sets the supply chain item address
     * @param supplyChainItem Address of the supply chain item contract
     * @return success Whether the update was successful
     */
    function setSupplyChainItem(address supplyChainItem) external onlyOwner returns (bool success) {
        _supplyChainItem = supplyChainItem;
        return true;
    }
}
