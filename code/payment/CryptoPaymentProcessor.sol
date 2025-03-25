// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IPayment.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IJurisdiction.sol";

/**
 * @title CryptoPaymentProcessor
 * @dev Implementation for processing cryptocurrency payments across Southeast Asian jurisdictions
 */
contract CryptoPaymentProcessor {
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Jurisdiction registry interface
    IJurisdiction private _jurisdictionRegistry;
    
    // Contract owner
    address private _owner;
    
    // Mapping from wallet type ID to wallet type details
    mapping(bytes32 => WalletType) private _walletTypes;
    
    // Mapping from jurisdiction to wallet type IDs
    mapping(uint8 => bytes32[]) private _jurisdictionWalletTypes;
    
    // Mapping from payment ID to payment details
    mapping(bytes32 => Payment) private _payments;
    
    // Struct containing wallet type details
    struct WalletType {
        bytes32 id;
        string name;
        string blockchain; // ETH, BTC, BNB, etc.
        uint8[] supportedJurisdictions;
        bool requiresKYC;
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Struct containing payment details
    struct Payment {
        bytes32 id;
        address payer;
        address payee;
        uint256 amount;
        uint8 jurisdiction;
        bytes32 walletTypeId;
        string transactionHash;
        string status; // PENDING, COMPLETED, FAILED, REFUNDED
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Events
    event WalletTypeAdded(
        bytes32 indexed walletTypeId,
        string name,
        string blockchain,
        bool requiresKYC,
        uint256 timestamp
    );
    
    event WalletTypeUpdated(
        bytes32 indexed walletTypeId,
        string name,
        bool isActive,
        uint256 timestamp
    );
    
    event PaymentProcessed(
        bytes32 indexed paymentId,
        address indexed payer,
        address indexed payee,
        uint256 amount,
        bytes32 walletTypeId,
        string transactionHash,
        string status,
        uint256 timestamp
    );
    
    event PaymentStatusUpdated(
        bytes32 indexed paymentId,
        string previousStatus,
        string newStatus,
        uint256 timestamp
    );
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "CryptoPaymentProcessor: caller is not the owner");
        _;
    }
    
    /**
     * @dev Constructor
     * @param complianceRegistry Address of the compliance registry contract
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     */
    constructor(
        address complianceRegistry,
        address jurisdictionRegistry
    ) {
        _owner = msg.sender;
        _complianceRegistry = ICompliance(complianceRegistry);
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
        
        // Initialize default wallet types
        _initializeDefaultWalletTypes();
    }
    
    /**
     * @dev Initializes default wallet types
     */
    function _initializeDefaultWalletTypes() internal {
        // Add Ethereum wallet type (supported in all jurisdictions)
        _addWalletType(
            "Ethereum",
            "ETH",
            [0, 1, 2, 3, 4, 5, 6, 7], // All jurisdictions
            true
        );
        
        // Add Bitcoin wallet type (supported in all jurisdictions)
        _addWalletType(
            "Bitcoin",
            "BTC",
            [0, 1, 2, 3, 4, 5, 6, 7], // All jurisdictions
            true
        );
        
        // Add Binance Smart Chain wallet type (supported in all jurisdictions)
        _addWalletType(
            "Binance Smart Chain",
            "BNB",
            [0, 1, 2, 3, 4, 5, 6, 7], // All jurisdictions
            true
        );
        
        // Add Polygon wallet type (supported in all jurisdictions)
        _addWalletType(
            "Polygon",
            "MATIC",
            [0, 1, 2, 3, 4, 5, 6, 7], // All jurisdictions
            true
        );
        
        // Add Solana wallet type (supported in all jurisdictions)
        _addWalletType(
            "Solana",
            "SOL",
            [0, 1, 2, 3, 4, 5, 6, 7], // All jurisdictions
            true
        );
        
        // Add Ripple wallet type (supported in all jurisdictions)
        _addWalletType(
            "Ripple",
            "XRP",
            [0, 1, 2, 3, 4, 5, 6, 7], // All jurisdictions
            true
        );
        
        // Add Cardano wallet type (supported in all jurisdictions)
        _addWalletType(
            "Cardano",
            "ADA",
            [0, 1, 2, 3, 4, 5, 6, 7], // All jurisdictions
            true
        );
        
        // Add Tether wallet type (supported in all jurisdictions)
        _addWalletType(
            "Tether",
            "USDT",
            [0, 1, 2, 3, 4, 5, 6, 7], // All jurisdictions
            true
        );
        
        // Add USD Coin wallet type (supported in all jurisdictions)
        _addWalletType(
            "USD Coin",
            "USDC",
            [0, 1, 2, 3, 4, 5, 6, 7], // All jurisdictions
            true
        );
        
        // Add country-specific cryptocurrencies
        
        // Singapore - Singapore Dollar Token
        _addWalletType(
            "Singapore Dollar Token",
            "XSGD",
            [1], // Singapore
            true
        );
        
        // Thailand - Thai Baht Digital
        _addWalletType(
            "Thai Baht Digital",
            "THB",
            [4], // Thailand
            true
        );
        
        // Malaysia - Malaysia Ringgit Token
        _addWalletType(
            "Malaysia Ringgit Token",
            "XMYR",
            [0], // Malaysia
            true
        );
    }
    
    /**
     * @dev Adds a new wallet type
     * @param name The name of the wallet type
     * @param blockchain The blockchain for the wallet type
     * @param supportedJurisdictions Array of jurisdiction codes supported by the wallet type
     * @param requiresKYC Whether the wallet type requires KYC
     * @return walletTypeId The unique identifier for the created wallet type
     */
    function _addWalletType(
        string memory name,
        string memory blockchain,
        uint8[] memory supportedJurisdictions,
        bool requiresKYC
    ) internal returns (bytes32 walletTypeId) {
        // Generate a unique wallet type ID
        walletTypeId = keccak256(abi.encodePacked(name, blockchain, block.timestamp));
        
        // Create the wallet type
        WalletType memory walletType = WalletType({
            id: walletTypeId,
            name: name,
            blockchain: blockchain,
            supportedJurisdictions: supportedJurisdictions,
            requiresKYC: requiresKYC,
            isActive: true,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        // Store the wallet type
        _walletTypes[walletTypeId] = walletType;
        
        // Add the wallet type to each supported jurisdiction
        for (uint256 i = 0; i < supportedJurisdictions.length; i++) {
            _jurisdictionWalletTypes[supportedJurisdictions[i]].push(walletTypeId);
        }
        
        // Emit the wallet type added event
        emit WalletTypeAdded(
            walletTypeId,
            name,
            blockchain,
            requiresKYC,
            block.timestamp
        );
        
        return walletTypeId;
    }
    
    /**
     * @dev Adds a new wallet type (public function)
     * @param name The name of the wallet type
     * @param blockchain The blockchain for the wallet type
     * @param supportedJurisdictions Array of jurisdiction codes supported by the wallet type
     * @param requiresKYC Whether the wallet type requires KYC
     * @return walletTypeId The unique identifier for the created wallet type
     */
    function addWalletType(
        string calldata name,
        string calldata blockchain,
        uint8[] calldata supportedJurisdictions,
        bool requiresKYC
    ) external onlyOwner returns (bytes32 walletTypeId) {
        return _addWalletType(name, blockchain, supportedJurisdictions, requiresKYC);
    }
    
    /**
     * @dev Updates a wallet type
     * @param walletTypeId The ID of the wallet type
     * @param name The new name of the wallet type
     * @param requiresKYC Whether the wallet type requires KYC
     * @param isActive Whether the wallet type is active
     * @return success Whether the update was successful
     */
    function updateWalletType(
        bytes32 walletTypeId,
        string calldata name,
        bool requiresKYC,
        bool isActive
    ) external onlyOwner returns (bool success) {
        WalletType storage walletType = _walletTypes[walletTypeId];
        
        // Check that the wallet type exists
        require(walletType.id == walletTypeId, "CryptoPaymentProcessor: wallet type does not exist");
        
        // Update the wallet type details
        walletType.name = name;
        walletType.requiresKYC = requiresKYC;
        walletType.isActive = isActive;
        walletType.updatedAt = block.timestamp;
        
        // Emit the wallet type updated event
        emit WalletTypeUpdated(
            walletTypeId,
            name,
            isActive,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Processes a payment
     * @param payer The address of the payer
     * @param payee The address of the payee
     * @param amount The amount of the payment
     * @param jurisdiction The jurisdiction code for the payment
     * @param walletTypeId The ID of the wallet type to use
     * @param transactionHash The transaction hash for the payment
     * @return paymentId The unique identifier for the processed payment
     */
    function processPayment(
        address payer,
        address payee,
        uint256 amount,
        uint8 jurisdiction,
        bytes32 walletTypeId,
        string calldata transactionHash
    ) external returns (bytes32 paymentId) {
        // Check that the jurisdiction is active
        require(
            _jurisdictionRegistry.isJurisdictionActive(jurisdiction),
            "CryptoPaymentProcessor: jurisdiction is not active"
        );
        
        // Check that the wallet type exists and is active
        WalletType storage walletType = _walletTypes[walletTypeId];
        require(walletType.id == walletTypeId, "CryptoPaymentProcessor: wallet type does not exist");
        require(walletType.isActive, "CryptoPaymentProcessor: wallet type is not active");
        
        // Check that the wallet type supports the jurisdiction
        bool jurisdictionSupported = false;
        for (uint256 i = 0; i < walletType.supportedJurisdictions.length; i++) {
            if (walletType.supportedJurisdictions[i] == jurisdiction) {
                jurisdictionSupported = true;
                break;
            }
        }
        require(jurisdictionSupported, "CryptoPaymentProcessor: wallet type does not support jurisdiction");
        
        // Generate a unique payment ID
        paymentId = keccak256(abi.encodePacked(payer, payee, amount, transactionHash, block.timestamp));
        
        // Create the payment
        Payment memory payment = Payment({
            id: paymentId,
            payer: payer,
            payee: payee,
            amount: amount,
            jurisdiction: jurisdiction,
            walletTypeId: walletTypeId,
            transactionHash: transactionHash,
            status: "PENDING",
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        // Store the payment
        _payments[paymentId] = payment;
        
        // Check compliance
        ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
        (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
            jurisdictionEnum,
            "CRYPTO_PAYMENT_PROCESS",
            abi.encode(payer, payee, amount, walletType.blockchain)
        );
        
        require(isCompliant, "CryptoPaymentProcessor: payment is not compliant");
        
        // In a real implementation, this would verify the transaction on the blockchain
        // For this demo, we'll simulate a successful payment
        _updatePaymentStatus(paymentId, "COMPLETED");
        
        // Emit the payment processed event
        emit PaymentProcessed(
            paymentId,
            payer,
            payee,
            amount,
            walletTypeId,
            transactionHash,
            "COMPLETED",
            block.timestamp
        );
        
        return paymentId;
    }
    
    /**
     * @dev Updates the status of a payment
     * @param paymentId The ID of the payment
     * @param newStatus The new status for the payment
     * @return success Whether the update was successful
     */
    function _updatePaymentStatus(bytes32 paymentId, string memory newStatus) internal returns (bool success) {
        Payment storage payment = _payments[paymentId];
        
        // Check that the payment exists
        require(payment.id == paymentId, "CryptoPaymentProcessor: payment does not exist");
        
        // Store the previous status for the event
        string memory previousStatus = payment.status;
        
        // Update the payment status
        payment.status = newStatus;
        payment.updatedAt = block.timestamp;
        
        // Emit the payment status updated event
        emit PaymentStatusUpdated(
            paymentId,
            previousStatus,
            newStatus,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Updates the status of a payment (public function)
     * @param paymentId The ID of the payment
     * @param newStatus The new status for the payment
     * @return success Whether the update was successful
     */
    function updatePaymentStatus(bytes32 paymentId, string calldata newStatus) external onlyOwner returns (bool success) {
        return _updatePaymentStatus(paymentId, newStatus);
    }
    
    /**
     * @dev Gets the details of a wallet type
     * @param walletTypeId The ID of the wallet type
     * @return walletType The wallet type details
     */
    function getWalletType(bytes32 walletTypeId) external view returns (
        bytes32 id,
        string memory name,
        string memory blockchain,
        uint8[] memory supportedJurisdictions,
        bool requiresKYC,
        bool isActive,
        uint256 createdAt,
        uint256 updatedAt
    ) {
        WalletType storage walletType = _walletTypes[walletTypeId];
        return (
            walletType.id,
            walletType.name,
            walletType.blockchain,
            walletType.supportedJurisdictions,
            walletType.requiresKYC,
            walletType.isActive,
            walletType.createdAt,
            walletType.updatedAt
        );
    }
    
    /**
     * @dev Gets the wallet types for a jurisdiction
     * @param jurisdiction The jurisdiction code
     * @return walletTypeIds Array of wallet type IDs for the jurisdiction
     */
    function getJurisdictionWalletTypes(uint8 jurisdiction) external view returns (bytes32[] memory walletTypeIds) {
        return _jurisdictionWalletTypes[jurisdiction];
    }
    
    /**
     * @dev Gets the details of a payment
     * @param paymentId The ID of the payment
     * @return payment The payment details
     */
    function getPayment(bytes32 paymentId) external view returns (Payment memory payment) {
        return _payments[paymentId];
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
     * @dev Sets the jurisdiction registry address
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     * @return success Whether the update was successful
     */
    function setJurisdictionRegistry(address jurisdictionRegistry) external onlyOwner returns (bool success) {
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
        return true;
    }
}
