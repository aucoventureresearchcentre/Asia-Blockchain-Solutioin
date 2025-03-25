// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IPayment.sol";
import "../interfaces/ICompliance.sol";

/**
 * @title PaymentProcessor
 * @dev Implementation of the IPayment interface for managing payments across jurisdictions
 */
contract PaymentProcessor is IPayment {
    // Mapping from payment ID to payment details
    mapping(bytes32 => Payment) private _payments;
    
    // Mapping from payer to payment IDs
    mapping(address => bytes32[]) private _payerPayments;
    
    // Mapping from payee to payment IDs
    mapping(address => bytes32[]) private _payeePayments;
    
    // Mapping from recurring payment schedule ID to payment IDs
    mapping(bytes32 => bytes32[]) private _recurringPayments;
    
    // Mapping from recurring payment schedule ID to schedule details
    mapping(bytes32 => RecurringPaymentSchedule) private _recurringSchedules;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Contract owner
    address private _owner;
    
    // Struct for recurring payment schedule
    struct RecurringPaymentSchedule {
        bytes32 id;
        PaymentMethod paymentMethod;
        address payer;
        address payee;
        uint256 amount;
        string currency;
        uint8 jurisdiction;
        uint256 intervalDays;
        uint256 startTime;
        uint256 endTime;
        uint256 maxPayments;
        uint256 paymentCount;
        bytes32 metadataHash;
        bool active;
        uint256 lastPaymentTime;
        uint256 nextPaymentTime;
    }
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "PaymentProcessor: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the payment payer
     * @param paymentId The ID of the payment
     */
    modifier onlyPayer(bytes32 paymentId) {
        require(_payments[paymentId].payer == msg.sender, "PaymentProcessor: caller is not the payer");
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
     * @inheritdoc IPayment
     */
    function createPayment(
        PaymentType paymentType,
        PaymentMethod paymentMethod,
        address payee,
        uint256 amount,
        string calldata currency,
        uint8 jurisdiction,
        bytes32 referenceId,
        bytes32 metadataHash,
        uint256 expirationTime,
        bytes calldata data
    ) external override returns (bytes32 paymentId) {
        // Generate a unique payment ID
        paymentId = keccak256(abi.encodePacked(msg.sender, payee, amount, currency, block.timestamp));
        
        // Create the payment
        Payment memory payment = Payment({
            id: paymentId,
            paymentType: paymentType,
            paymentMethod: paymentMethod,
            status: PaymentStatus.CREATED,
            payer: msg.sender,
            payee: payee,
            amount: amount,
            currency: currency,
            jurisdiction: jurisdiction,
            referenceId: referenceId,
            metadataHash: metadataHash,
            createdAt: block.timestamp,
            completedAt: 0,
            expiresAt: expirationTime > 0 ? expirationTime : 0
        });
        
        // Store the payment
        _payments[paymentId] = payment;
        _payerPayments[msg.sender].push(paymentId);
        _payeePayments[payee].push(paymentId);
        
        // Check compliance if a compliance registry is set
        if (address(_complianceRegistry) != address(0)) {
            // Convert jurisdiction to the enum type expected by the compliance registry
            ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
            
            // Check if the payment creation is compliant
            (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
                jurisdictionEnum,
                "PAYMENT_CREATE",
                abi.encode(msg.sender, payee, amount, currency)
            );
            
            require(isCompliant, "PaymentProcessor: payment creation is not compliant");
        }
        
        // Emit the payment creation event
        emit PaymentCreated(
            paymentId,
            paymentType,
            msg.sender,
            payee,
            amount,
            currency,
            jurisdiction,
            block.timestamp
        );
        
        return paymentId;
    }
    
    /**
     * @inheritdoc IPayment
     */
    function processPayment(
        bytes32 paymentId,
        bytes calldata processingData
    ) external override returns (bool success) {
        Payment storage payment = _payments[paymentId];
        
        // Check that the payment exists
        require(payment.id == paymentId, "PaymentProcessor: payment does not exist");
        
        // Check that the payment is in a processable state
        require(
            payment.status == PaymentStatus.CREATED || payment.status == PaymentStatus.PENDING,
            "PaymentProcessor: payment is not in a processable state"
        );
        
        // Check that the payment has not expired
        if (payment.expiresAt > 0) {
            require(block.timestamp <= payment.expiresAt, "PaymentProcessor: payment has expired");
        }
        
        // Check that the caller is authorized to process the payment
        // In a real implementation, this would depend on the payment method and might involve oracles or external services
        bool isAuthorized = (payment.payer == msg.sender) || (payment.payee == msg.sender) || (msg.sender == _owner);
        require(isAuthorized, "PaymentProcessor: caller is not authorized to process payment");
        
        // Check compliance if a compliance registry is set
        if (address(_complianceRegistry) != address(0)) {
            // Convert jurisdiction to the enum type expected by the compliance registry
            ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(payment.jurisdiction);
            
            // Check if the payment processing is compliant
            (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
                jurisdictionEnum,
                "PAYMENT_PROCESS",
                abi.encode(msg.sender, paymentId)
            );
            
            require(isCompliant, "PaymentProcessor: payment processing is not compliant");
        }
        
        // Process the payment based on its type and method
        // This is a simplified implementation
        // In a production environment, you would have more complex processing logic
        
        // Update the payment status
        PaymentStatus previousStatus = payment.status;
        payment.status = PaymentStatus.COMPLETED;
        payment.completedAt = block.timestamp;
        
        // Emit the status update event
        emit PaymentStatusUpdated(
            paymentId,
            previousStatus,
            PaymentStatus.COMPLETED,
            block.timestamp
        );
        
        // Emit the payment completed event
        emit PaymentCompleted(
            paymentId,
            payment.payer,
            payment.payee,
            payment.amount,
            payment.currency,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc IPayment
     */
    function cancelPayment(
        bytes32 paymentId,
        string calldata reason
    ) external override onlyPayer(paymentId) returns (bool success) {
        Payment storage payment = _payments[paymentId];
        
        // Check that the payment is not already completed or cancelled
        require(
            payment.status != PaymentStatus.COMPLETED &&
            payment.status != PaymentStatus.CANCELLED,
            "PaymentProcessor: payment cannot be cancelled"
        );
        
        // Update the payment status
        PaymentStatus previousStatus = payment.status;
        payment.status = PaymentStatus.CANCELLED;
        
        // Emit the status update event
        emit PaymentStatusUpdated(
            paymentId,
            previousStatus,
            PaymentStatus.CANCELLED,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc IPayment
     */
    function refundPayment(
        bytes32 paymentId,
        uint256 amount,
        string calldata reason
    ) external override returns (bool success) {
        Payment storage payment = _payments[paymentId];
        
        // Check that the payment exists
        require(payment.id == paymentId, "PaymentProcessor: payment does not exist");
        
        // Check that the payment is completed
        require(
            payment.status == PaymentStatus.COMPLETED,
            "PaymentProcessor: payment is not completed"
        );
        
        // Check that the caller is authorized to refund the payment
        // In a real implementation, this would depend on the payment method and might involve oracles or external services
        bool isAuthorized = (payment.payee == msg.sender) || (msg.sender == _owner);
        require(isAuthorized, "PaymentProcessor: caller is not authorized to refund payment");
        
        // Check that the refund amount is valid
        uint256 refundAmount = amount > 0 ? amount : payment.amount;
        require(refundAmount <= payment.amount, "PaymentProcessor: refund amount exceeds payment amount");
        
        // Process the refund
        // This is a simplified implementation
        // In a production environment, you would have more complex refund logic
        
        // Update the payment status
        payment.status = PaymentStatus.REFUNDED;
        
        // Emit the status update event
        emit PaymentStatusUpdated(
            paymentId,
            PaymentStatus.COMPLETED,
            PaymentStatus.REFUNDED,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc IPayment
     */
    function getPayment(bytes32 paymentId)
        external
        view
        override
        returns (Payment memory payment)
    {
        return _payments[paymentId];
    }
    
    /**
     * @inheritdoc IPayment
     */
    function getPaymentsByPayer(
        address payer,
        uint8 status,
        uint256 startIndex,
        uint256 limit
    ) external view override returns (bytes32[] memory paymentIds, uint256 totalCount) {
        bytes32[] storage payerPaymentIds = _payerPayments[payer];
        uint256 payerPaymentCount = payerPaymentIds.length;
        
        // Count payments matching the status filter
        if (status > 0) {
            uint256 statusCount = 0;
            for (uint256 i = 0; i < payerPaymentCount; i++) {
                if (uint8(_payments[payerPaymentIds[i]].status) == status) {
                    statusCount++;
                }
            }
            totalCount = statusCount;
        } else {
            totalCount = payerPaymentCount;
        }
        
        // Handle pagination
        uint256 resultCount = limit;
        if (startIndex + resultCount > totalCount) {
            resultCount = totalCount > startIndex ? totalCount - startIndex : 0;
        }
        
        // Create the result array
        paymentIds = new bytes32[](resultCount);
        
        // Fill the result array
        if (resultCount > 0) {
            uint256 resultIndex = 0;
            
            for (uint256 i = 0; i < payerPaymentCount && resultIndex < resultCount; i++) {
                bytes32 currentPaymentId = payerPaymentIds[i];
                
                // Filter by status if specified
                if (status > 0 && uint8(_payments[currentPaymentId].status) != status) {
                    continue;
                }
                
                // Skip payments before the start index
                if (i < startIndex) {
                    continue;
                }
                
                paymentIds[resultIndex] = currentPaymentId;
                resultIndex++;
            }
        }
        
        return (paymentIds, totalCount);
    }
    
    /**
     * @inheritdoc IPayment
     */
    function getPaymentsByPayee(
        address payee,
        uint8 status,
        uint256 startIndex,
        uint256 limit
    ) external view override returns (bytes32[] memory paymentIds, uint256 totalCount) {
        bytes32[] storage payeePaymentIds = _payeePayments[payee];
        uint256 payeePaymentCount = payeePaymentIds.length;
        
        // Count payments matching the status filter
        if (status > 0) {
            uint256 statusCount = 0;
            for (uint256 i = 0; i < payeePaymentCount; i++) {
                if (uint8(_payments[payeePaymentIds[i]].status) == status) {
                    statusCount++;
                }
            }
            totalCount = statusCount;
        } else {
            totalCount = payeePaymentCount;
        }
        
        // Handle pagination
        uint256 resultCount = limit;
        if (startIndex + resultCount > totalCount) {
            resultCount = totalCount > startIndex ? totalCount - startIndex : 0;
        }
        
        // Create the result array
        paymentIds = new bytes32[](resultCount);
        
        // Fill the result array
        if (resultCount > 0) {
            uint256 resultIndex = 0;
            
            for (uint256 i = 0; i < payeePaymentCount && resultIndex < resultCount; i++) {
                bytes32 currentPaymentId = payeePaymentIds[i];
                
                // Filter by status if specified
                if (status > 0 && uint8(_payments[currentPaymentId].status) != status) {
                    continue;
                }
                
                // Skip payments before the start index
                if (i < startIndex) {
                    continue;
                }
                
                paymentIds[resultIndex] = currentPaymentId;
                resultIndex++;
            }
        }
        
        return (paymentIds, totalCount);
    }
    
    /**
     * @inheritdoc IPayment
     */
    function createRecurringPayment(
        PaymentMethod paymentMethod,
        address payee,
        uint256 amount,
        string calldata currency,
        uint8 jurisdiction,
        uint256 intervalDays,
        uint256 startTime,
        uint256 endTime,
        uint256 maxPayments,
        bytes32 metadataHash,
        bytes calldata data
    ) external override returns (bytes32 scheduleId) {
        // Generate a unique schedule ID
        scheduleId = keccak256(abi.encodePacked(msg.sender, payee, amount, currency, intervalDays, block.timestamp));
        
        // Calculate the next payment time
        uint256 nextPaymentTime = startTime > 0 ? startTime : block.timestamp;
        
        // Create the recurring payment schedule
        RecurringPaymentSchedule memory schedule = RecurringPaymentSchedule({
            id: scheduleId,
            paymentMethod: paymentMethod,
            payer: msg.sender,
            payee: payee,
            amount: amount,
            currency: currency,
            jurisdiction: jurisdiction,
            intervalDays: intervalDays,
            startTime: startTime > 0 ? startTime : block.timestamp,
            endTime: endTime,
            maxPayments: maxPayments,
            paymentCount: 0,
            metadataHash: metadataHash,
            active: true,
            lastPaymentTime: 0,
            nextPaymentTime: nextPaymentTime
        });
        
        // Store the schedule
        _recurringSchedules[scheduleId] = schedule;
        
        // Check compliance if a compliance registry is set
        if (address(_complianceRegistry) != address(0)) {
            // Convert jurisdiction to the enum type expected by the compliance registry
            ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
            
            // Check if the recurring payment creation is compliant
            (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
                jurisdictionEnum,
                "RECURRING_PAYMENT_CREATE",
                abi.encode(msg.sender, payee, amount, currency)
            );
            
            require(isCompliant, "PaymentProcessor: recurring payment creation is not compliant");
        }
        
        return scheduleId;
    }
    
    /**
     * @inheritdoc IPayment
     */
    function cancelRecurringPayment(
        bytes32 scheduleId,
        string calldata reason
    ) external override returns (bool success) {
        RecurringPaymentSchedule storage schedule = _recurringSchedules[scheduleId];
        
        // Check that the schedule exists
        require(schedule.id == scheduleId, "PaymentProcessor: recurring payment schedule does not exist");
        
        // Check that the caller is authorized to cancel the schedule
        require(schedule.payer == msg.sender, "PaymentProcessor: caller is not the payer");
        
        // Check that the schedule is active
        require(schedule.active, "PaymentProcessor: recurring payment schedule is not active");
        
        // Deactivate the schedule
        schedule.active = false;
        
        return true;
    }
    
    /**
     * @dev Processes the next payment for a recurring payment schedule
     * @param scheduleId The ID of the recurring payment schedule
     * @return paymentId The ID of the created payment
     */
    function processRecurringPayment(bytes32 scheduleId) external returns (bytes32 paymentId) {
        RecurringPaymentSchedule storage schedule = _recurringSchedules[scheduleId];
        
        // Check that the schedule exists
        require(schedule.id == scheduleId, "PaymentProcessor: recurring payment schedule does not exist");
        
        // Check that the schedule is active
        require(schedule.active, "PaymentProcessor: recurring payment schedule is not active");
        
        // Check that it's time for the next payment
        require(block.timestamp >= schedule.nextPaymentTime, "PaymentProcessor: not time for next payment");
        
        // Check that the maximum number of payments has not been reached
        if (schedule.maxPayments > 0) {
            require(schedule.paymentCount < schedule.maxPayments, "PaymentProcessor: maximum payments reached");
        }
        
        // Check that the end time has not been reached
        if (schedule.endTime > 0) {
            require(block.timestamp <= schedule.endTime, "PaymentProcessor: end time reached");
        }
        
        // Create the payment
        paymentId = this.createPayment(
            PaymentType.RECURRING,
            schedule.paymentMethod,
            schedule.payee,
            schedule.amount,
            schedule.currency,
            schedule.jurisdiction,
            scheduleId, // Use the schedule ID as the reference ID
            schedule.metadataHash,
            0, // No expiration for recurring payments
            ""
        );
        
        // Update the schedule
        schedule.paymentCount++;
        schedule.lastPaymentTime = block.timestamp;
        schedule.nextPaymentTime = block.timestamp + (schedule.intervalDays * 1 days);
        
        // Add the payment to the recurring payments mapping
        _recurringPayments[scheduleId].push(paymentId);
        
        return paymentId;
    }
    
    /**
     * @dev Gets the details of a recurring payment schedule
     * @param scheduleId The ID of the recurring payment schedule
     * @return schedule The recurring payment schedule details
     */
    function getRecurringPaymentSchedule(bytes32 scheduleId)
        external
        view
        returns (RecurringPaymentSchedule memory schedule)
    {
        return _recurringSchedules[scheduleId];
    }
    
    /**
     * @dev Gets the payments for a recurring payment schedule
     * @param scheduleId The ID of the recurring payment schedule
     * @return paymentIds Array of payment IDs for the schedule
     */
    function getRecurringPayments(bytes32 scheduleId)
        external
        view
        returns (bytes32[] memory paymentIds)
    {
        return _recurringPayments[scheduleId];
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
