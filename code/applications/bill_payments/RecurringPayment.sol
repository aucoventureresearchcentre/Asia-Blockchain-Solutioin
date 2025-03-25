// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IPayment.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IJurisdiction.sol";

/**
 * @title RecurringPayment
 * @dev Implementation for managing recurring payments across Southeast Asian jurisdictions
 */
contract RecurringPayment {
    // Payment processor interface
    IPayment private _paymentProcessor;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Jurisdiction registry interface
    IJurisdiction private _jurisdictionRegistry;
    
    // BillPayment contract address
    address private _billPayment;
    
    // Contract owner
    address private _owner;
    
    // Mapping from subscription ID to subscription details
    mapping(bytes32 => Subscription) private _subscriptions;
    
    // Mapping from user address to subscription IDs
    mapping(address => bytes32[]) private _userSubscriptions;
    
    // Mapping from merchant address to subscription IDs
    mapping(address => bytes32[]) private _merchantSubscriptions;
    
    // Enum representing the subscription status
    enum SubscriptionStatus {
        ACTIVE,
        PAUSED,
        CANCELLED,
        EXPIRED
    }
    
    // Struct containing subscription details
    struct Subscription {
        bytes32 id;
        string name;
        address subscriber;
        address merchant;
        uint256 amount;
        uint8 jurisdiction;
        uint256 frequency; // in seconds
        uint256 nextPaymentDate;
        uint256 endDate; // 0 for no end date
        SubscriptionStatus status;
        IPayment.PaymentMethod paymentMethod;
        bytes paymentData;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Events
    event SubscriptionCreated(
        bytes32 indexed subscriptionId,
        address indexed subscriber,
        address indexed merchant,
        uint256 amount,
        uint256 frequency,
        uint256 timestamp
    );
    
    event SubscriptionStatusUpdated(
        bytes32 indexed subscriptionId,
        SubscriptionStatus previousStatus,
        SubscriptionStatus newStatus,
        uint256 timestamp
    );
    
    event SubscriptionPaymentProcessed(
        bytes32 indexed subscriptionId,
        bytes32 indexed paymentId,
        address indexed subscriber,
        uint256 amount,
        uint256 timestamp
    );
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "RecurringPayment: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the subscriber
     * @param subscriptionId The ID of the subscription
     */
    modifier onlySubscriber(bytes32 subscriptionId) {
        require(_subscriptions[subscriptionId].subscriber == msg.sender, "RecurringPayment: caller is not the subscriber");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the merchant
     * @param subscriptionId The ID of the subscription
     */
    modifier onlyMerchant(bytes32 subscriptionId) {
        require(_subscriptions[subscriptionId].merchant == msg.sender, "RecurringPayment: caller is not the merchant");
        _;
    }
    
    /**
     * @dev Constructor
     * @param paymentProcessor Address of the payment processor contract
     * @param complianceRegistry Address of the compliance registry contract
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     * @param billPayment Address of the bill payment contract
     */
    constructor(
        address paymentProcessor,
        address complianceRegistry,
        address jurisdictionRegistry,
        address billPayment
    ) {
        _owner = msg.sender;
        _paymentProcessor = IPayment(paymentProcessor);
        _complianceRegistry = ICompliance(complianceRegistry);
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
        _billPayment = billPayment;
    }
    
    /**
     * @dev Creates a new subscription
     * @param name The name of the subscription
     * @param merchant The address of the merchant
     * @param amount The amount of each payment
     * @param jurisdiction The jurisdiction code for the subscription
     * @param frequency The frequency of payments in seconds
     * @param startDate The start date for the subscription
     * @param endDate The end date for the subscription (0 for no end date)
     * @param paymentMethod The payment method to use
     * @param paymentData Additional payment data
     * @return subscriptionId The unique identifier for the created subscription
     */
    function createSubscription(
        string calldata name,
        address merchant,
        uint256 amount,
        uint8 jurisdiction,
        uint256 frequency,
        uint256 startDate,
        uint256 endDate,
        IPayment.PaymentMethod paymentMethod,
        bytes calldata paymentData
    ) external returns (bytes32 subscriptionId) {
        // Check that the jurisdiction is active
        require(
            _jurisdictionRegistry.isJurisdictionActive(jurisdiction),
            "RecurringPayment: jurisdiction is not active"
        );
        
        // Check that the frequency is valid
        require(frequency > 0, "RecurringPayment: frequency must be greater than zero");
        
        // Check that the start date is in the future
        require(startDate > block.timestamp, "RecurringPayment: start date must be in the future");
        
        // Check that the end date is after the start date if provided
        if (endDate > 0) {
            require(endDate > startDate, "RecurringPayment: end date must be after start date");
        }
        
        // Generate a unique subscription ID
        subscriptionId = keccak256(abi.encodePacked(msg.sender, merchant, name, block.timestamp));
        
        // Create the subscription
        Subscription memory subscription = Subscription({
            id: subscriptionId,
            name: name,
            subscriber: msg.sender,
            merchant: merchant,
            amount: amount,
            jurisdiction: jurisdiction,
            frequency: frequency,
            nextPaymentDate: startDate,
            endDate: endDate,
            status: SubscriptionStatus.ACTIVE,
            paymentMethod: paymentMethod,
            paymentData: paymentData,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        // Store the subscription
        _subscriptions[subscriptionId] = subscription;
        
        // Add the subscription to the subscriber's subscriptions
        _userSubscriptions[msg.sender].push(subscriptionId);
        
        // Add the subscription to the merchant's subscriptions
        _merchantSubscriptions[merchant].push(subscriptionId);
        
        // Check compliance
        ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
        (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
            jurisdictionEnum,
            "RECURRING_PAYMENT_CREATE",
            abi.encode(msg.sender, merchant, amount)
        );
        
        require(isCompliant, "RecurringPayment: subscription creation is not compliant");
        
        // Emit the subscription created event
        emit SubscriptionCreated(
            subscriptionId,
            msg.sender,
            merchant,
            amount,
            frequency,
            block.timestamp
        );
        
        return subscriptionId;
    }
    
    /**
     * @dev Updates the status of a subscription
     * @param subscriptionId The ID of the subscription
     * @param newStatus The new status for the subscription
     * @return success Whether the update was successful
     */
    function updateSubscriptionStatus(bytes32 subscriptionId, SubscriptionStatus newStatus)
        external
        returns (bool success)
    {
        Subscription storage subscription = _subscriptions[subscriptionId];
        
        // Check that the caller is either the subscriber or the merchant
        require(
            subscription.subscriber == msg.sender || subscription.merchant == msg.sender,
            "RecurringPayment: caller is neither the subscriber nor the merchant"
        );
        
        // Store the previous status for the event
        SubscriptionStatus previousStatus = subscription.status;
        
        // Update the subscription status
        subscription.status = newStatus;
        subscription.updatedAt = block.timestamp;
        
        // Emit the subscription status updated event
        emit SubscriptionStatusUpdated(
            subscriptionId,
            previousStatus,
            newStatus,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Processes a payment for a subscription
     * @param subscriptionId The ID of the subscription
     * @return paymentId The unique identifier for the payment
     */
    function processSubscriptionPayment(bytes32 subscriptionId) external returns (bytes32 paymentId) {
        Subscription storage subscription = _subscriptions[subscriptionId];
        
        // Check that the caller is the merchant
        require(subscription.merchant == msg.sender, "RecurringPayment: caller is not the merchant");
        
        // Check that the subscription is active
        require(subscription.status == SubscriptionStatus.ACTIVE, "RecurringPayment: subscription is not active");
        
        // Check that the current time is after the next payment date
        require(block.timestamp >= subscription.nextPaymentDate, "RecurringPayment: next payment date not reached");
        
        // Check if the subscription has expired
        if (subscription.endDate > 0 && block.timestamp > subscription.endDate) {
            subscription.status = SubscriptionStatus.EXPIRED;
            
            emit SubscriptionStatusUpdated(
                subscriptionId,
                SubscriptionStatus.ACTIVE,
                SubscriptionStatus.EXPIRED,
                block.timestamp
            );
            
            return bytes32(0);
        }
        
        // Process the payment
        paymentId = _paymentProcessor.processPayment(
            subscription.subscriber,
            subscription.merchant,
            subscription.amount,
            subscription.paymentMethod,
            subscription.paymentData
        );
        
        // Update the next payment date
        subscription.nextPaymentDate = subscription.nextPaymentDate + subscription.frequency;
        subscription.updatedAt = block.timestamp;
        
        // Emit the subscription payment processed event
        emit SubscriptionPaymentProcessed(
            subscriptionId,
            paymentId,
            subscription.subscriber,
            subscription.amount,
            block.timestamp
        );
        
        return paymentId;
    }
    
    /**
     * @dev Updates the payment method for a subscription
     * @param subscriptionId The ID of the subscription
     * @param paymentMethod The new payment method
     * @param paymentData The new payment data
     * @return success Whether the update was successful
     */
    function updatePaymentMethod(
        bytes32 subscriptionId,
        IPayment.PaymentMethod paymentMethod,
        bytes calldata paymentData
    ) external onlySubscriber(subscriptionId) returns (bool success) {
        Subscription storage subscription = _subscriptions[subscriptionId];
        
        // Update the payment method
        subscription.paymentMethod = paymentMethod;
        subscription.paymentData = paymentData;
        subscription.updatedAt = block.timestamp;
        
        return true;
    }
    
    /**
     * @dev Gets the details of a subscription
     * @param subscriptionId The ID of the subscription
     * @return subscription The subscription details
     */
    function getSubscription(bytes32 subscriptionId) external view returns (Subscription memory subscription) {
        return _subscriptions[subscriptionId];
    }
    
    /**
     * @dev Gets the subscriptions for a user
     * @param userAddress The address of the user
     * @return subscriptionIds Array of subscription IDs for the user
     */
    function getUserSubscriptions(address userAddress) external view returns (bytes32[] memory subscriptionIds) {
        return _userSubscriptions[userAddress];
    }
    
    /**
     * @dev Gets the subscriptions for a merchant
     * @param merchantAddress The address of the merchant
     * @return subscriptionIds Array of subscription IDs for the merchant
     */
    function getMerchantSubscriptions(address merchantAddress) external view returns (bytes32[] memory subscriptionIds) {
        return _merchantSubscriptions[merchantAddress];
    }
    
    /**
     * @dev Sets the payment processor address
     * @param paymentProcessor Address of the payment processor contract
     * @return success Whether the update was successful
     */
    function setPaymentProcessor(address paymentProcessor) external onlyOwner returns (bool success) {
        _paymentProcessor = IPayment(paymentProcessor);
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
     * @dev Sets the jurisdiction registry address
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     * @return success Whether the update was successful
     */
    function setJurisdictionRegistry(address jurisdictionRegistry) external onlyOwner returns (bool success) {
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
        return true;
    }
    
    /**
     * @dev Sets the bill payment address
     * @param billPayment Address of the bill payment contract
     * @return success Whether the update was successful
     */
    function setBillPayment(address billPayment) external onlyOwner returns (bool success) {
        _billPayment = billPayment;
        return true;
    }
}
