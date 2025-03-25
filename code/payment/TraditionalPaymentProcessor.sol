// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IPayment.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IJurisdiction.sol";

/**
 * @title TraditionalPaymentProcessor
 * @dev Implementation for processing traditional payments across Southeast Asian jurisdictions
 */
contract TraditionalPaymentProcessor {
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Jurisdiction registry interface
    IJurisdiction private _jurisdictionRegistry;
    
    // Contract owner
    address private _owner;
    
    // Mapping from payment provider ID to payment provider details
    mapping(bytes32 => PaymentProvider) private _paymentProviders;
    
    // Mapping from jurisdiction to payment provider IDs
    mapping(uint8 => bytes32[]) private _jurisdictionPaymentProviders;
    
    // Mapping from payment ID to payment details
    mapping(bytes32 => Payment) private _payments;
    
    // Struct containing payment provider details
    struct PaymentProvider {
        bytes32 id;
        string name;
        string providerType; // CREDIT_CARD, BANK_TRANSFER, E_WALLET, etc.
        uint8[] supportedJurisdictions;
        string apiEndpoint;
        string apiKey;
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
        bytes32 paymentProviderId;
        string referenceNumber;
        string status; // PENDING, COMPLETED, FAILED, REFUNDED
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Events
    event PaymentProviderAdded(
        bytes32 indexed providerId,
        string name,
        string providerType,
        uint256 timestamp
    );
    
    event PaymentProviderUpdated(
        bytes32 indexed providerId,
        string name,
        bool isActive,
        uint256 timestamp
    );
    
    event PaymentProcessed(
        bytes32 indexed paymentId,
        address indexed payer,
        address indexed payee,
        uint256 amount,
        bytes32 paymentProviderId,
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
        require(msg.sender == _owner, "TraditionalPaymentProcessor: caller is not the owner");
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
        
        // Initialize default payment providers for each jurisdiction
        _initializeDefaultPaymentProviders();
    }
    
    /**
     * @dev Initializes default payment providers for each jurisdiction
     */
    function _initializeDefaultPaymentProviders() internal {
        // Malaysia payment providers
        _addPaymentProvider(
            "MayBank",
            "BANK_TRANSFER",
            [0], // Malaysia
            "https://api.maybank.com/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        _addPaymentProvider(
            "CIMB Clicks",
            "BANK_TRANSFER",
            [0], // Malaysia
            "https://api.cimbclicks.com.my/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        _addPaymentProvider(
            "Touch 'n Go eWallet",
            "E_WALLET",
            [0], // Malaysia
            "https://api.tngdigital.com.my/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        _addPaymentProvider(
            "Boost",
            "E_WALLET",
            [0], // Malaysia
            "https://api.boost.com.my/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        _addPaymentProvider(
            "GrabPay",
            "E_WALLET",
            [0, 1, 2, 4, 5, 6], // Malaysia, Singapore, Indonesia, Thailand, Cambodia, Vietnam
            "https://api.grab.com/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        // Singapore payment providers
        _addPaymentProvider(
            "PayNow",
            "BANK_TRANSFER",
            [1], // Singapore
            "https://api.paynow.sg/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        _addPaymentProvider(
            "NETS",
            "BANK_TRANSFER",
            [1], // Singapore
            "https://api.nets.com.sg/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        // Indonesia payment providers
        _addPaymentProvider(
            "OVO",
            "E_WALLET",
            [2], // Indonesia
            "https://api.ovo.id/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        _addPaymentProvider(
            "GoPay",
            "E_WALLET",
            [2], // Indonesia
            "https://api.gopay.co.id/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        _addPaymentProvider(
            "DANA",
            "E_WALLET",
            [2], // Indonesia
            "https://api.dana.id/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        // Brunei payment providers
        _addPaymentProvider(
            "BIBD",
            "BANK_TRANSFER",
            [3], // Brunei
            "https://api.bibd.com.bn/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        // Thailand payment providers
        _addPaymentProvider(
            "PromptPay",
            "BANK_TRANSFER",
            [4], // Thailand
            "https://api.promptpay.io/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        _addPaymentProvider(
            "TrueMoney Wallet",
            "E_WALLET",
            [4], // Thailand
            "https://api.truemoney.com/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        // Cambodia payment providers
        _addPaymentProvider(
            "WING",
            "E_WALLET",
            [5], // Cambodia
            "https://api.wingmoney.com/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        _addPaymentProvider(
            "Pi Pay",
            "E_WALLET",
            [5], // Cambodia
            "https://api.pipay.com/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        // Vietnam payment providers
        _addPaymentProvider(
            "MoMo",
            "E_WALLET",
            [6], // Vietnam
            "https://api.momo.vn/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        _addPaymentProvider(
            "VNPay",
            "E_WALLET",
            [6], // Vietnam
            "https://api.vnpay.vn/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        // Laos payment providers
        _addPaymentProvider(
            "BCEL One",
            "BANK_TRANSFER",
            [7], // Laos
            "https://api.bcelone.com/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        // Cross-jurisdiction payment providers
        _addPaymentProvider(
            "Visa",
            "CREDIT_CARD",
            [0, 1, 2, 3, 4, 5, 6, 7], // All jurisdictions
            "https://api.visa.com/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        _addPaymentProvider(
            "Mastercard",
            "CREDIT_CARD",
            [0, 1, 2, 3, 4, 5, 6, 7], // All jurisdictions
            "https://api.mastercard.com/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
        
        _addPaymentProvider(
            "American Express",
            "CREDIT_CARD",
            [0, 1, 2, 3, 4], // Malaysia, Singapore, Indonesia, Brunei, Thailand
            "https://api.americanexpress.com/v1/payments",
            "API_KEY_PLACEHOLDER"
        );
    }
    
    /**
     * @dev Adds a new payment provider
     * @param name The name of the payment provider
     * @param providerType The type of payment provider
     * @param supportedJurisdictions Array of jurisdiction codes supported by the provider
     * @param apiEndpoint The API endpoint for the payment provider
     * @param apiKey The API key for the payment provider
     * @return providerId The unique identifier for the created payment provider
     */
    function _addPaymentProvider(
        string memory name,
        string memory providerType,
        uint8[] memory supportedJurisdictions,
        string memory apiEndpoint,
        string memory apiKey
    ) internal returns (bytes32 providerId) {
        // Generate a unique provider ID
        providerId = keccak256(abi.encodePacked(name, providerType, block.timestamp));
        
        // Create the payment provider
        PaymentProvider memory provider = PaymentProvider({
            id: providerId,
            name: name,
            providerType: providerType,
            supportedJurisdictions: supportedJurisdictions,
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            isActive: true,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        // Store the payment provider
        _paymentProviders[providerId] = provider;
        
        // Add the provider to each supported jurisdiction
        for (uint256 i = 0; i < supportedJurisdictions.length; i++) {
            _jurisdictionPaymentProviders[supportedJurisdictions[i]].push(providerId);
        }
        
        // Emit the payment provider added event
        emit PaymentProviderAdded(
            providerId,
            name,
            providerType,
            block.timestamp
        );
        
        return providerId;
    }
    
    /**
     * @dev Adds a new payment provider (public function)
     * @param name The name of the payment provider
     * @param providerType The type of payment provider
     * @param supportedJurisdictions Array of jurisdiction codes supported by the provider
     * @param apiEndpoint The API endpoint for the payment provider
     * @param apiKey The API key for the payment provider
     * @return providerId The unique identifier for the created payment provider
     */
    function addPaymentProvider(
        string calldata name,
        string calldata providerType,
        uint8[] calldata supportedJurisdictions,
        string calldata apiEndpoint,
        string calldata apiKey
    ) external onlyOwner returns (bytes32 providerId) {
        return _addPaymentProvider(name, providerType, supportedJurisdictions, apiEndpoint, apiKey);
    }
    
    /**
     * @dev Updates a payment provider
     * @param providerId The ID of the payment provider
     * @param name The new name of the payment provider
     * @param apiEndpoint The new API endpoint for the payment provider
     * @param apiKey The new API key for the payment provider
     * @param isActive Whether the payment provider is active
     * @return success Whether the update was successful
     */
    function updatePaymentProvider(
        bytes32 providerId,
        string calldata name,
        string calldata apiEndpoint,
        string calldata apiKey,
        bool isActive
    ) external onlyOwner returns (bool success) {
        PaymentProvider storage provider = _paymentProviders[providerId];
        
        // Check that the provider exists
        require(provider.id == providerId, "TraditionalPaymentProcessor: provider does not exist");
        
        // Update the provider details
        provider.name = name;
        provider.apiEndpoint = apiEndpoint;
        provider.apiKey = apiKey;
        provider.isActive = isActive;
        provider.updatedAt = block.timestamp;
        
        // Emit the payment provider updated event
        emit PaymentProviderUpdated(
            providerId,
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
     * @param paymentProviderId The ID of the payment provider to use
     * @param paymentData Additional payment data
     * @return paymentId The unique identifier for the processed payment
     */
    function processPayment(
        address payer,
        address payee,
        uint256 amount,
        uint8 jurisdiction,
        bytes32 paymentProviderId,
        bytes calldata paymentData
    ) external returns (bytes32 paymentId) {
        // Check that the jurisdiction is active
        require(
            _jurisdictionRegistry.isJurisdictionActive(jurisdiction),
            "TraditionalPaymentProcessor: jurisdiction is not active"
        );
        
        // Check that the payment provider exists and is active
        PaymentProvider storage provider = _paymentProviders[paymentProviderId];
        require(provider.id == paymentProviderId, "TraditionalPaymentProcessor: provider does not exist");
        require(provider.isActive, "TraditionalPaymentProcessor: provider is not active");
        
        // Check that the provider supports the jurisdiction
        bool jurisdictionSupported = false;
        for (uint256 i = 0; i < provider.supportedJurisdictions.length; i++) {
            if (provider.supportedJurisdictions[i] == jurisdiction) {
                jurisdictionSupported = true;
                break;
            }
        }
        require(jurisdictionSupported, "TraditionalPaymentProcessor: provider does not support jurisdiction");
        
        // Generate a unique payment ID
        paymentId = keccak256(abi.encodePacked(payer, payee, amount, block.timestamp));
        
        // Generate a reference number for the payment
        string memory referenceNumber = string(abi.encodePacked("PAY", bytes32ToHexString(paymentId)));
        
        // Create the payment
        Payment memory payment = Payment({
            id: paymentId,
            payer: payer,
            payee: payee,
            amount: amount,
            jurisdiction: jurisdiction,
            paymentProviderId: paymentProviderId,
            referenceNumber: referenceNumber,
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
            "PAYMENT_PROCESS",
            abi.encode(payer, payee, amount)
        );
        
        require(isCompliant, "TraditionalPaymentProcessor: payment is not compliant");
        
        // In a real implementation, this would call the payment provider's API
        // For this demo, we'll simulate a successful payment
        _updatePaymentStatus(paymentId, "COMPLETED");
        
        // Emit the payment processed event
        emit PaymentProcessed(
            paymentId,
            payer,
            payee,
            amount,
            paymentProviderId,
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
        require(payment.id == paymentId, "TraditionalPaymentProcessor: payment does not exist");
        
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
     * @dev Gets the details of a payment provider
     * @param providerId The ID of the payment provider
     * @return provider The payment provider details
     */
    function getPaymentProvider(bytes32 providerId) external view returns (
        bytes32 id,
        string memory name,
        string memory providerType,
        uint8[] memory supportedJurisdictions,
        string memory apiEndpoint,
        bool isActive,
        uint256 createdAt,
        uint256 updatedAt
    ) {
        PaymentProvider storage provider = _paymentProviders[providerId];
        return (
            provider.id,
            provider.name,
            provider.providerType,
            provider.supportedJurisdictions,
            provider.apiEndpoint,
            provider.isActive,
            provider.createdAt,
            provider.updatedAt
        );
    }
    
    /**
     * @dev Gets the payment providers for a jurisdiction
     * @param jurisdiction The jurisdiction code
     * @return providerIds Array of payment provider IDs for the jurisdiction
     */
    function getJurisdictionPaymentProviders(uint8 jurisdiction) external view returns (bytes32[] memory providerIds) {
        return _jurisdictionPaymentProviders[jurisdiction];
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
    
    /**
     * @dev Converts a bytes32 to a hex string
     * @param value The bytes32 value to convert
     * @return The hex string representation
     */
    function bytes32ToHexString(bytes32 value) internal pure returns (string memory) {
        bytes memory result = new bytes(64);
        bytes memory hexChars = "0123456789abcdef";
        
        for (uint256 i = 0; i < 32; i++) {
            result[i * 2] = hexChars[uint8(value[i] >> 4)];
            result[i * 2 + 1] = hexChars[uint8(value[i] & 0x0f)];
        }
        
        return string(result);
    }
}
