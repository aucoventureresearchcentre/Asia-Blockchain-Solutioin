// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IPayment.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IJurisdiction.sol";

/**
 * @title PaymentGateway
 * @dev Implementation for a unified payment gateway that supports both traditional and crypto payments
 */
contract PaymentGateway is IPayment {
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Jurisdiction registry interface
    IJurisdiction private _jurisdictionRegistry;
    
    // Traditional payment processor address
    address private _traditionalPaymentProcessor;
    
    // Crypto payment processor address
    address private _cryptoPaymentProcessor;
    
    // Contract owner
    address private _owner;
    
    // Mapping from payment ID to payment details
    mapping(bytes32 => Payment) private _payments;
    
    // Struct containing payment details
    struct Payment {
        bytes32 id;
        address payer;
        address payee;
        uint256 amount;
        uint8 jurisdiction;
        PaymentMethod paymentMethod;
        bytes32 processorPaymentId;
        string status; // PENDING, COMPLETED, FAILED, REFUNDED
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Events
    event PaymentProcessed(
        bytes32 indexed paymentId,
        address indexed payer,
        address indexed payee,
        uint256 amount,
        PaymentMethod paymentMethod,
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
        require(msg.sender == _owner, "PaymentGateway: caller is not the owner");
        _;
    }
    
    /**
     * @dev Constructor
     * @param complianceRegistry Address of the compliance registry contract
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     * @param traditionalPaymentProcessor Address of the traditional payment processor contract
     * @param cryptoPaymentProcessor Address of the crypto payment processor contract
     */
    constructor(
        address complianceRegistry,
        address jurisdictionRegistry,
        address traditionalPaymentProcessor,
        address cryptoPaymentProcessor
    ) {
        _owner = msg.sender;
        _complianceRegistry = ICompliance(complianceRegistry);
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
        _traditionalPaymentProcessor = traditionalPaymentProcessor;
        _cryptoPaymentProcessor = cryptoPaymentProcessor;
    }
    
    /**
     * @dev Processes a payment
     * @param payer The address of the payer
     * @param payee The address of the payee
     * @param amount The amount of the payment
     * @param paymentMethod The payment method to use
     * @param paymentData Additional payment data
     * @return paymentId The unique identifier for the processed payment
     */
    function processPayment(
        address payer,
        address payee,
        uint256 amount,
        PaymentMethod paymentMethod,
        bytes calldata paymentData
    ) external override returns (bytes32 paymentId) {
        // Check that the payer and payee are valid
        require(payer != address(0), "PaymentGateway: payer is the zero address");
        require(payee != address(0), "PaymentGateway: payee is the zero address");
        require(amount > 0, "PaymentGateway: amount is zero");
        
        // Extract jurisdiction from payment data
        uint8 jurisdiction;
        bytes32 providerId;
        bytes memory processorData;
        
        if (paymentMethod == PaymentMethod.TRADITIONAL) {
            (jurisdiction, providerId, processorData) = decodeTraditionalPaymentData(paymentData);
        } else if (paymentMethod == PaymentMethod.CRYPTO) {
            (jurisdiction, providerId, processorData) = decodeCryptoPaymentData(paymentData);
        } else {
            revert("PaymentGateway: unsupported payment method");
        }
        
        // Check that the jurisdiction is active
        require(
            _jurisdictionRegistry.isJurisdictionActive(jurisdiction),
            "PaymentGateway: jurisdiction is not active"
        );
        
        // Generate a unique payment ID
        paymentId = keccak256(abi.encodePacked(payer, payee, amount, paymentMethod, block.timestamp));
        
        // Process the payment through the appropriate processor
        bytes32 processorPaymentId;
        
        if (paymentMethod == PaymentMethod.TRADITIONAL) {
            processorPaymentId = processTraditionalPayment(payer, payee, amount, jurisdiction, providerId, processorData);
        } else if (paymentMethod == PaymentMethod.CRYPTO) {
            processorPaymentId = processCryptoPayment(payer, payee, amount, jurisdiction, providerId, processorData);
        }
        
        // Create the payment record
        Payment memory payment = Payment({
            id: paymentId,
            payer: payer,
            payee: payee,
            amount: amount,
            jurisdiction: jurisdiction,
            paymentMethod: paymentMethod,
            processorPaymentId: processorPaymentId,
            status: "COMPLETED", // Assuming successful payment for simplicity
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        // Store the payment
        _payments[paymentId] = payment;
        
        // Emit the payment processed event
        emit PaymentProcessed(
            paymentId,
            payer,
            payee,
            amount,
            paymentMethod,
            "COMPLETED",
            block.timestamp
        );
        
        return paymentId;
    }
    
    /**
     * @dev Processes a traditional payment
     * @param payer The address of the payer
     * @param payee The address of the payee
     * @param amount The amount of the payment
     * @param jurisdiction The jurisdiction code for the payment
     * @param providerId The ID of the payment provider to use
     * @param paymentData Additional payment data
     * @return processorPaymentId The payment ID from the traditional payment processor
     */
    function processTraditionalPayment(
        address payer,
        address payee,
        uint256 amount,
        uint8 jurisdiction,
        bytes32 providerId,
        bytes memory paymentData
    ) internal returns (bytes32 processorPaymentId) {
        // Call the traditional payment processor
        bytes memory data = abi.encodeWithSignature(
            "processPayment(address,address,uint256,uint8,bytes32,bytes)",
            payer,
            payee,
            amount,
            jurisdiction,
            providerId,
            paymentData
        );
        
        (bool success, bytes memory returnData) = _traditionalPaymentProcessor.call(data);
        
        require(success, "PaymentGateway: traditional payment processing failed");
        
        // Decode the payment ID from the return data
        processorPaymentId = abi.decode(returnData, (bytes32));
        
        return processorPaymentId;
    }
    
    /**
     * @dev Processes a crypto payment
     * @param payer The address of the payer
     * @param payee The address of the payee
     * @param amount The amount of the payment
     * @param jurisdiction The jurisdiction code for the payment
     * @param walletTypeId The ID of the wallet type to use
     * @param paymentData Additional payment data
     * @return processorPaymentId The payment ID from the crypto payment processor
     */
    function processCryptoPayment(
        address payer,
        address payee,
        uint256 amount,
        uint8 jurisdiction,
        bytes32 walletTypeId,
        bytes memory paymentData
    ) internal returns (bytes32 processorPaymentId) {
        // Extract transaction hash from payment data
        string memory transactionHash = abi.decode(paymentData, (string));
        
        // Call the crypto payment processor
        bytes memory data = abi.encodeWithSignature(
            "processPayment(address,address,uint256,uint8,bytes32,string)",
            payer,
            payee,
            amount,
            jurisdiction,
            walletTypeId,
            transactionHash
        );
        
        (bool success, bytes memory returnData) = _cryptoPaymentProcessor.call(data);
        
        require(success, "PaymentGateway: crypto payment processing failed");
        
        // Decode the payment ID from the return data
        processorPaymentId = abi.decode(returnData, (bytes32));
        
        return processorPaymentId;
    }
    
    /**
     * @dev Decodes traditional payment data
     * @param paymentData The payment data to decode
     * @return jurisdiction The jurisdiction code
     * @return providerId The payment provider ID
     * @return processorData Additional data for the processor
     */
    function decodeTraditionalPaymentData(bytes calldata paymentData) internal pure returns (
        uint8 jurisdiction,
        bytes32 providerId,
        bytes memory processorData
    ) {
        // Decode the payment data
        (jurisdiction, providerId, processorData) = abi.decode(paymentData, (uint8, bytes32, bytes));
        
        return (jurisdiction, providerId, processorData);
    }
    
    /**
     * @dev Decodes crypto payment data
     * @param paymentData The payment data to decode
     * @return jurisdiction The jurisdiction code
     * @return walletTypeId The wallet type ID
     * @return processorData Additional data for the processor
     */
    function decodeCryptoPaymentData(bytes calldata paymentData) internal pure returns (
        uint8 jurisdiction,
        bytes32 walletTypeId,
        bytes memory processorData
    ) {
        // Decode the payment data
        (jurisdiction, walletTypeId, processorData) = abi.decode(paymentData, (uint8, bytes32, bytes));
        
        return (jurisdiction, walletTypeId, processorData);
    }
    
    /**
     * @dev Updates the status of a payment
     * @param paymentId The ID of the payment
     * @param newStatus The new status for the payment
     * @return success Whether the update was successful
     */
    function updatePaymentStatus(bytes32 paymentId, string calldata newStatus) external onlyOwner returns (bool success) {
        Payment storage payment = _payments[paymentId];
        
        // Check that the payment exists
        require(payment.id == paymentId, "PaymentGateway: payment does not exist");
        
        // Store the previous status for the event
        string memory previousStatus = payment.status;
        
        // Update the payment status
        payment.status = newStatus;
        payment.updatedAt = block.timestamp;
        
        // Update the status in the appropriate processor
        if (payment.paymentMethod == PaymentMethod.TRADITIONAL) {
            updateTraditionalPaymentStatus(payment.processorPaymentId, newStatus);
        } else if (payment.paymentMethod == PaymentMethod.CRYPTO) {
            updateCryptoPaymentStatus(payment.processorPaymentId, newStatus);
        }
        
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
     * @dev Updates the status of a traditional payment
     * @param processorPaymentId The payment ID in the traditional payment processor
     * @param newStatus The new status for the payment
     */
    function updateTraditionalPaymentStatus(bytes32 processorPaymentId, string calldata newStatus) internal {
        // Call the traditional payment processor
        bytes memory data = abi.encodeWithSignature(
            "updatePaymentStatus(bytes32,string)",
            processorPaymentId,
            newStatus
        );
        
        (bool success, ) = _traditionalPaymentProcessor.call(data);
        
        require(success, "PaymentGateway: traditional payment status update failed");
    }
    
    /**
     * @dev Updates the status of a crypto payment
     * @param processorPaymentId The payment ID in the crypto payment processor
     * @param newStatus The new status for the payment
     */
    function updateCryptoPaymentStatus(bytes32 processorPaymentId, string calldata newStatus) internal {
        // Call the crypto payment processor
        bytes memory data = abi.encodeWithSignature(
            "updatePaymentStatus(bytes32,string)",
            processorPaymentId,
            newStatus
        );
        
        (bool success, ) = _cryptoPaymentProcessor.call(data);
        
        require(success, "PaymentGateway: crypto payment status update failed");
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
     * @dev Sets the traditional payment processor address
     * @param traditionalPaymentProcessor Address of the traditional payment processor contract
     * @return success Whether the update was successful
     */
    function setTraditionalPaymentProcessor(address traditionalPaymentProcessor) external onlyOwner returns (bool success) {
        _traditionalPaymentProcessor = traditionalPaymentProcessor;
        return true;
    }
    
    /**
     * @dev Sets the crypto payment processor address
     * @param cryptoPaymentProcessor Address of the crypto payment processor contract
     * @return success Whether the update was successful
     */
    function setCryptoPaymentProcessor(address cryptoPaymentProcessor) external onlyOwner returns (bool success) {
        _cryptoPaymentProcessor = cryptoPaymentProcessor;
        return true;
    }
}
