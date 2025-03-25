// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IPayment.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IJurisdiction.sol";
import "../../core/interfaces/IIdentity.sol";

/**
 * @title BillPayment
 * @dev Implementation for managing bill payments across Southeast Asian jurisdictions
 */
contract BillPayment {
    // Payment processor interface
    IPayment private _paymentProcessor;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Jurisdiction registry interface
    IJurisdiction private _jurisdictionRegistry;
    
    // Identity manager interface
    IIdentity private _identityManager;
    
    // Contract owner
    address private _owner;
    
    // Mapping from bill ID to bill details
    mapping(bytes32 => Bill) private _bills;
    
    // Mapping from user address to bill IDs (as payer)
    mapping(address => bytes32[]) private _userBills;
    
    // Mapping from merchant address to bill IDs (as payee)
    mapping(address => bytes32[]) private _merchantBills;
    
    // Mapping from bill ID to payment IDs
    mapping(bytes32 => bytes32[]) private _billPayments;
    
    // Enum representing the bill status
    enum BillStatus {
        CREATED,
        PENDING,
        PAID,
        OVERDUE,
        CANCELLED
    }
    
    // Enum representing the bill type
    enum BillType {
        ONE_TIME,
        RECURRING
    }
    
    // Struct containing bill details
    struct Bill {
        bytes32 id;
        string reference;
        address payer;
        address payee;
        uint256 amount;
        uint8 jurisdiction;
        BillType billType;
        BillStatus status;
        uint256 dueDate;
        uint256 recurringInterval;
        uint256 nextBillDate;
        bytes32 parentBillId;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Struct containing payment details
    struct Payment {
        bytes32 id;
        bytes32 billId;
        address payer;
        address payee;
        uint256 amount;
        uint256 timestamp;
        IPayment.PaymentMethod paymentMethod;
        bytes paymentData;
    }
    
    // Mapping from payment ID to payment details
    mapping(bytes32 => Payment) private _payments;
    
    // Events
    event BillCreated(
        bytes32 indexed billId,
        address indexed payer,
        address indexed payee,
        uint256 amount,
        BillType billType,
        uint256 dueDate,
        uint256 timestamp
    );
    
    event BillStatusUpdated(
        bytes32 indexed billId,
        BillStatus previousStatus,
        BillStatus newStatus,
        uint256 timestamp
    );
    
    event BillPaid(
        bytes32 indexed billId,
        bytes32 indexed paymentId,
        address indexed payer,
        uint256 amount,
        uint256 timestamp
    );
    
    event RecurringBillGenerated(
        bytes32 indexed newBillId,
        bytes32 indexed parentBillId,
        address indexed payer,
        uint256 amount,
        uint256 dueDate,
        uint256 timestamp
    );
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "BillPayment: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the bill payer
     * @param billId The ID of the bill
     */
    modifier onlyPayer(bytes32 billId) {
        require(_bills[billId].payer == msg.sender, "BillPayment: caller is not the bill payer");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the bill payee
     * @param billId The ID of the bill
     */
    modifier onlyPayee(bytes32 billId) {
        require(_bills[billId].payee == msg.sender, "BillPayment: caller is not the bill payee");
        _;
    }
    
    /**
     * @dev Constructor
     * @param paymentProcessor Address of the payment processor contract
     * @param complianceRegistry Address of the compliance registry contract
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     * @param identityManager Address of the identity manager contract
     */
    constructor(
        address paymentProcessor,
        address complianceRegistry,
        address jurisdictionRegistry,
        address identityManager
    ) {
        _owner = msg.sender;
        _paymentProcessor = IPayment(paymentProcessor);
        _complianceRegistry = ICompliance(complianceRegistry);
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
        _identityManager = IIdentity(identityManager);
    }
    
    /**
     * @dev Creates a new bill
     * @param reference The reference for the bill
     * @param payer The address of the payer
     * @param amount The amount of the bill
     * @param jurisdiction The jurisdiction code for the bill
     * @param billType The type of bill (one-time or recurring)
     * @param dueDate The due date for the bill
     * @param recurringInterval The interval for recurring bills (in seconds)
     * @return billId The unique identifier for the created bill
     */
    function createBill(
        string calldata reference,
        address payer,
        uint256 amount,
        uint8 jurisdiction,
        BillType billType,
        uint256 dueDate,
        uint256 recurringInterval
    ) external returns (bytes32 billId) {
        // Check that the jurisdiction is active
        require(
            _jurisdictionRegistry.isJurisdictionActive(jurisdiction),
            "BillPayment: jurisdiction is not active"
        );
        
        // Check that the due date is in the future
        require(dueDate > block.timestamp, "BillPayment: due date must be in the future");
        
        // If recurring, check that the interval is valid
        if (billType == BillType.RECURRING) {
            require(recurringInterval > 0, "BillPayment: recurring interval must be greater than zero");
        }
        
        // Generate a unique bill ID
        billId = keccak256(abi.encodePacked(msg.sender, payer, reference, block.timestamp));
        
        // Create the bill
        Bill memory bill = Bill({
            id: billId,
            reference: reference,
            payer: payer,
            payee: msg.sender,
            amount: amount,
            jurisdiction: jurisdiction,
            billType: billType,
            status: BillStatus.CREATED,
            dueDate: dueDate,
            recurringInterval: recurringInterval,
            nextBillDate: billType == BillType.RECURRING ? dueDate + recurringInterval : 0,
            parentBillId: bytes32(0),
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        // Store the bill
        _bills[billId] = bill;
        
        // Add the bill to the payer's bills
        _userBills[payer].push(billId);
        
        // Add the bill to the payee's bills
        _merchantBills[msg.sender].push(billId);
        
        // Check compliance
        ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
        (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
            jurisdictionEnum,
            "BILL_CREATE",
            abi.encode(msg.sender, payer, amount)
        );
        
        require(isCompliant, "BillPayment: bill creation is not compliant");
        
        // Emit the bill created event
        emit BillCreated(
            billId,
            payer,
            msg.sender,
            amount,
            billType,
            dueDate,
            block.timestamp
        );
        
        return billId;
    }
    
    /**
     * @dev Updates the status of a bill
     * @param billId The ID of the bill
     * @param newStatus The new status for the bill
     * @return success Whether the update was successful
     */
    function updateBillStatus(bytes32 billId, BillStatus newStatus)
        external
        returns (bool success)
    {
        Bill storage bill = _bills[billId];
        
        // Check that the caller is either the payer or the payee
        require(
            bill.payer == msg.sender || bill.payee == msg.sender,
            "BillPayment: caller is neither the payer nor the payee"
        );
        
        // Store the previous status for the event
        BillStatus previousStatus = bill.status;
        
        // Update the bill status
        bill.status = newStatus;
        bill.updatedAt = block.timestamp;
        
        // Emit the bill status updated event
        emit BillStatusUpdated(
            billId,
            previousStatus,
            newStatus,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Pays a bill
     * @param billId The ID of the bill
     * @param paymentMethod The payment method to use
     * @param paymentData Additional payment data
     * @return paymentId The unique identifier for the payment
     */
    function payBill(
        bytes32 billId,
        IPayment.PaymentMethod paymentMethod,
        bytes calldata paymentData
    ) external onlyPayer(billId) returns (bytes32 paymentId) {
        Bill storage bill = _bills[billId];
        
        // Check that the bill is in a payable state
        require(
            bill.status == BillStatus.CREATED || bill.status == BillStatus.PENDING || bill.status == BillStatus.OVERDUE,
            "BillPayment: bill is not in a payable state"
        );
        
        // Process the payment
        paymentId = _paymentProcessor.processPayment(
            msg.sender,
            bill.payee,
            bill.amount,
            paymentMethod,
            paymentData
        );
        
        // Create the payment record
        Payment memory payment = Payment({
            id: paymentId,
            billId: billId,
            payer: msg.sender,
            payee: bill.payee,
            amount: bill.amount,
            timestamp: block.timestamp,
            paymentMethod: paymentMethod,
            paymentData: paymentData
        });
        
        // Store the payment
        _payments[paymentId] = payment;
        
        // Add the payment to the bill's payments
        _billPayments[billId].push(paymentId);
        
        // Update the bill status
        bill.status = BillStatus.PAID;
        bill.updatedAt = block.timestamp;
        
        // Emit the bill paid event
        emit BillPaid(
            billId,
            paymentId,
            msg.sender,
            bill.amount,
            block.timestamp
        );
        
        // If this is a recurring bill, generate the next bill
        if (bill.billType == BillType.RECURRING) {
            generateNextRecurringBill(billId);
        }
        
        return paymentId;
    }
    
    /**
     * @dev Generates the next bill in a recurring series
     * @param parentBillId The ID of the parent bill
     * @return newBillId The ID of the newly generated bill
     */
    function generateNextRecurringBill(bytes32 parentBillId) internal returns (bytes32 newBillId) {
        Bill storage parentBill = _bills[parentBillId];
        
        // Check that this is a recurring bill
        require(parentBill.billType == BillType.RECURRING, "BillPayment: not a recurring bill");
        
        // Generate a unique bill ID
        newBillId = keccak256(abi.encodePacked(parentBill.payee, parentBill.payer, parentBill.reference, block.timestamp));
        
        // Create the new bill
        Bill memory newBill = Bill({
            id: newBillId,
            reference: parentBill.reference,
            payer: parentBill.payer,
            payee: parentBill.payee,
            amount: parentBill.amount,
            jurisdiction: parentBill.jurisdiction,
            billType: BillType.RECURRING,
            status: BillStatus.PENDING,
            dueDate: parentBill.nextBillDate,
            recurringInterval: parentBill.recurringInterval,
            nextBillDate: parentBill.nextBillDate + parentBill.recurringInterval,
            parentBillId: parentBillId,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        // Store the new bill
        _bills[newBillId] = newBill;
        
        // Add the bill to the payer's bills
        _userBills[parentBill.payer].push(newBillId);
        
        // Add the bill to the payee's bills
        _merchantBills[parentBill.payee].push(newBillId);
        
        // Update the parent bill's next bill date
        parentBill.nextBillDate = 0; // No more next bill date for the parent
        
        // Emit the recurring bill generated event
        emit RecurringBillGenerated(
            newBillId,
            parentBillId,
            parentBill.payer,
            newBill.amount,
            newBill.dueDate,
            block.timestamp
        );
        
        return newBillId;
    }
    
    /**
     * @dev Cancels a bill
     * @param billId The ID of the bill
     * @return success Whether the cancellation was successful
     */
    function cancelBill(bytes32 billId) external returns (bool success) {
        Bill storage bill = _bills[billId];
        
        // Check that the caller is either the payer or the payee
        require(
            bill.payer == msg.sender || bill.payee == msg.sender,
            "BillPayment: caller is neither the payer nor the payee"
        );
        
        // Check that the bill is in a cancellable state
        require(
            bill.status == BillStatus.CREATED || bill.status == BillStatus.PENDING,
            "BillPayment: bill is not in a cancellable state"
        );
        
        // Update the bill status
        bill.status = BillStatus.CANCELLED;
        bill.updatedAt = block.timestamp;
        
        // Emit the bill status updated event
        emit BillStatusUpdated(
            billId,
            BillStatus.PENDING,
            BillStatus.CANCELLED,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Gets the details of a bill
     * @param billId The ID of the bill
     * @return bill The bill details
     */
    function getBill(bytes32 billId) external view returns (Bill memory bill) {
        return _bills[billId];
    }
    
    /**
     * @dev Gets the bills for a user
     * @param userAddress The address of the user
     * @return billIds Array of bill IDs for the user
     */
    function getUserBills(address userAddress) external view returns (bytes32[] memory billIds) {
        return _userBills[userAddress];
    }
    
    /**
     * @dev Gets the bills for a merchant
     * @param merchantAddress The address of the merchant
     * @return billIds Array of bill IDs for the merchant
     */
    function getMerchantBills(address merchantAddress) external view returns (bytes32[] memory billIds) {
        return _merchantBills[merchantAddress];
    }
    
    /**
     * @dev Gets the payments for a bill
     * @param billId The ID of the bill
     * @return paymentIds Array of payment IDs for the bill
     */
    function getBillPayments(bytes32 billId) external view returns (bytes32[] memory paymentIds) {
        return _billPayments[billId];
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
     * @dev Sets the identity manager address
     * @param identityManager Address of the identity manager contract
     * @return success Whether the update was successful
     */
    function setIdentityManager(address identityManager) external onlyOwner returns (bool success) {
        _identityManager = IIdentity(identityManager);
        return true;
    }
}
