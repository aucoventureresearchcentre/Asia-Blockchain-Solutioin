// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IAsset.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IDocument.sol";
import "../../core/interfaces/ITransaction.sol";

/**
 * @title RealEstateTransaction
 * @dev Implementation for managing real estate transactions across Southeast Asian jurisdictions
 */
contract RealEstateTransaction {
    // Asset registry interface
    IAsset private _assetRegistry;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Document registry interface
    IDocument private _documentRegistry;
    
    // Transaction manager interface
    ITransaction private _transactionManager;
    
    // RealEstateToken contract address
    address private _realEstateToken;
    
    // Contract owner
    address private _owner;
    
    // Mapping from transaction ID to property ID
    mapping(bytes32 => bytes32) private _transactionProperties;
    
    // Mapping from property ID to transaction IDs
    mapping(bytes32 => bytes32[]) private _propertyTransactions;
    
    // Events
    event TransactionInitiated(
        bytes32 indexed transactionId,
        bytes32 indexed propertyId,
        address indexed seller,
        address buyer,
        uint256 price,
        uint8 jurisdiction,
        uint256 timestamp
    );
    
    event TransactionCompleted(
        bytes32 indexed transactionId,
        bytes32 indexed propertyId,
        address indexed seller,
        address buyer,
        uint256 price,
        uint256 timestamp
    );
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "RealEstateTransaction: caller is not the owner");
        _;
    }
    
    /**
     * @dev Constructor
     * @param assetRegistry Address of the asset registry contract
     * @param complianceRegistry Address of the compliance registry contract
     * @param documentRegistry Address of the document registry contract
     * @param transactionManager Address of the transaction manager contract
     * @param realEstateToken Address of the real estate token contract
     */
    constructor(
        address assetRegistry,
        address complianceRegistry,
        address documentRegistry,
        address transactionManager,
        address realEstateToken
    ) {
        _owner = msg.sender;
        _assetRegistry = IAsset(assetRegistry);
        _complianceRegistry = ICompliance(complianceRegistry);
        _documentRegistry = IDocument(documentRegistry);
        _transactionManager = ITransaction(transactionManager);
        _realEstateToken = realEstateToken;
    }
    
    /**
     * @dev Initiates a real estate transaction
     * @param propertyId The ID of the property
     * @param buyer The address of the buyer
     * @param price The price of the property
     * @param documentIds Array of document IDs associated with the transaction
     * @param expirationTime Time when the transaction expires (0 for no expiration)
     * @return transactionId The unique identifier for the transaction
     */
    function initiateTransaction(
        bytes32 propertyId,
        address buyer,
        uint256 price,
        bytes32[] calldata documentIds,
        uint256 expirationTime
    ) external returns (bytes32 transactionId) {
        // Get the property details from the RealEstateToken contract
        (
            bytes32 id,
            string memory propertyAddress,
            uint256 area,
            string memory propertyType,
            uint8 jurisdiction,
            bytes32 assetId,
            address owner,
            uint256 value,
            bool isVerified,
            uint256 createdAt,
            uint256 updatedAt
        ) = getRealEstateProperty(propertyId);
        
        // Check that the caller is the property owner
        require(owner == msg.sender, "RealEstateTransaction: caller is not the property owner");
        
        // Check that the property is verified
        require(isVerified, "RealEstateTransaction: property is not verified");
        
        // Create transaction parties
        ITransaction.TransactionParty[] memory parties = new ITransaction.TransactionParty[](2);
        
        // Seller party
        parties[0] = ITransaction.TransactionParty({
            partyAddress: msg.sender,
            role: "SELLER",
            hasSigned: false,
            signatureTimestamp: 0
        });
        
        // Buyer party
        parties[1] = ITransaction.TransactionParty({
            partyAddress: buyer,
            role: "BUYER",
            hasSigned: false,
            signatureTimestamp: 0
        });
        
        // Create the transaction
        bytes32[] memory assetIds = new bytes32[](1);
        assetIds[0] = assetId;
        
        transactionId = _transactionManager.createTransaction(
            ITransaction.TransactionType.ASSET_TRANSFER,
            jurisdiction,
            assetIds,
            parties,
            keccak256(abi.encodePacked(propertyId, price)),
            expirationTime,
            abi.encode(propertyId, price)
        );
        
        // Store the transaction-property relationship
        _transactionProperties[transactionId] = propertyId;
        _propertyTransactions[propertyId].push(transactionId);
        
        // Link documents to the transaction
        for (uint256 i = 0; i < documentIds.length; i++) {
            bytes32 docId = documentIds[i];
            _documentRegistry.linkDocumentToAsset(docId, assetId, "TRANSACTION_DOCUMENT");
        }
        
        // Check compliance
        ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
        (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
            jurisdictionEnum,
            "PROPERTY_TRANSACTION_INITIATE",
            abi.encode(msg.sender, buyer, propertyId, price)
        );
        
        require(isCompliant, "RealEstateTransaction: transaction initiation is not compliant");
        
        // Emit the transaction initiated event
        emit TransactionInitiated(
            transactionId,
            propertyId,
            msg.sender,
            buyer,
            price,
            jurisdiction,
            block.timestamp
        );
        
        return transactionId;
    }
    
    /**
     * @dev Signs a real estate transaction
     * @param transactionId The ID of the transaction
     * @return success Whether the signing was successful
     */
    function signTransaction(bytes32 transactionId) external returns (bool success) {
        // Sign the transaction
        success = _transactionManager.signTransaction(transactionId, "");
        return success;
    }
    
    /**
     * @dev Executes a real estate transaction
     * @param transactionId The ID of the transaction
     * @return success Whether the execution was successful
     */
    function executeTransaction(bytes32 transactionId) external returns (bool success) {
        // Get the transaction details
        ITransaction.Transaction memory transaction = _transactionManager.getTransaction(transactionId);
        
        // Check that the transaction is approved
        require(
            transaction.status == ITransaction.TransactionStatus.APPROVED,
            "RealEstateTransaction: transaction is not approved"
        );
        
        // Get the property ID
        bytes32 propertyId = _transactionProperties[transactionId];
        
        // Get the buyer and seller addresses
        address seller;
        address buyer;
        
        for (uint256 i = 0; i < transaction.parties.length; i++) {
            if (keccak256(bytes(transaction.parties[i].role)) == keccak256(bytes("SELLER"))) {
                seller = transaction.parties[i].partyAddress;
            } else if (keccak256(bytes(transaction.parties[i].role)) == keccak256(bytes("BUYER"))) {
                buyer = transaction.parties[i].partyAddress;
            }
        }
        
        // Execute the transaction in the transaction manager
        success = _transactionManager.executeTransaction(transactionId, "");
        
        // Transfer the property in the RealEstateToken contract
        (bool transferSuccess) = transferRealEstateProperty(propertyId, buyer);
        require(transferSuccess, "RealEstateTransaction: property transfer failed");
        
        // Get the price from the transaction metadata
        uint256 price = extractPriceFromTransaction(transactionId);
        
        // Emit the transaction completed event
        emit TransactionCompleted(
            transactionId,
            propertyId,
            seller,
            buyer,
            price,
            block.timestamp
        );
        
        return success;
    }
    
    /**
     * @dev Gets the property ID for a transaction
     * @param transactionId The ID of the transaction
     * @return propertyId The ID of the property
     */
    function getTransactionProperty(bytes32 transactionId) external view returns (bytes32 propertyId) {
        return _transactionProperties[transactionId];
    }
    
    /**
     * @dev Gets the transactions for a property
     * @param propertyId The ID of the property
     * @return transactionIds Array of transaction IDs for the property
     */
    function getPropertyTransactions(bytes32 propertyId) external view returns (bytes32[] memory transactionIds) {
        return _propertyTransactions[propertyId];
    }
    
    /**
     * @dev Gets a property from the RealEstateToken contract
     * @param propertyId The ID of the property
     * @return Property details
     */
    function getRealEstateProperty(bytes32 propertyId) internal view returns (
        bytes32 id,
        string memory propertyAddress,
        uint256 area,
        string memory propertyType,
        uint8 jurisdiction,
        bytes32 assetId,
        address owner,
        uint256 value,
        bool isVerified,
        uint256 createdAt,
        uint256 updatedAt
    ) {
        // Call the RealEstateToken contract to get the property details
        bytes memory data = abi.encodeWithSignature("getProperty(bytes32)", propertyId);
        (bool success, bytes memory returnData) = _realEstateToken.staticcall(data);
        
        require(success, "RealEstateTransaction: failed to get property");
        
        // Decode the property details
        return abi.decode(returnData, (
            bytes32,
            string,
            uint256,
            string,
            uint8,
            bytes32,
            address,
            uint256,
            bool,
            uint256,
            uint256
        ));
    }
    
    /**
     * @dev Transfers a property in the RealEstateToken contract
     * @param propertyId The ID of the property
     * @param newOwner The address of the new owner
     * @return success Whether the transfer was successful
     */
    function transferRealEstateProperty(bytes32 propertyId, address newOwner) internal returns (bool success) {
        // Call the RealEstateToken contract to transfer the property
        bytes memory data = abi.encodeWithSignature("transferProperty(bytes32,address)", propertyId, newOwner);
        (bool callSuccess, bytes memory returnData) = _realEstateToken.call(data);
        
        if (callSuccess) {
            return abi.decode(returnData, (bool));
        } else {
            return false;
        }
    }
    
    /**
     * @dev Extracts the price from a transaction
     * @param transactionId The ID of the transaction
     * @return price The price of the property
     */
    function extractPriceFromTransaction(bytes32 transactionId) internal view returns (uint256 price) {
        // This is a simplified implementation
        // In a production environment, you would store and retrieve the price more robustly
        return 0;
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
     * @dev Sets the real estate token address
     * @param realEstateToken Address of the real estate token contract
     * @return success Whether the update was successful
     */
    function setRealEstateToken(address realEstateToken) external onlyOwner returns (bool success) {
        _realEstateToken = realEstateToken;
        return true;
    }
}
