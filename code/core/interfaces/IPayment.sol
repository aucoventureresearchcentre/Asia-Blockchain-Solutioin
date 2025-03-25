// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IPayment
 * @dev Interface for payment processing across different jurisdictions
 * @notice This interface defines the standard methods for payment processing and management
 */
interface IPayment {
    /**
     * @dev Enum representing the payment types
     */
    enum PaymentType {
        DIRECT_TRANSFER,
        ESCROW,
        RECURRING,
        INSTALLMENT,
        CONDITIONAL
    }

    /**
     * @dev Enum representing the payment status
     */
    enum PaymentStatus {
        CREATED,
        PENDING,
        COMPLETED,
        FAILED,
        REFUNDED,
        CANCELLED
    }

    /**
     * @dev Enum representing the payment methods
     */
    enum PaymentMethod {
        FIAT_BANK_TRANSFER,
        FIAT_CREDIT_CARD,
        CRYPTOCURRENCY,
        DIGITAL_WALLET,
        MOBILE_PAYMENT
    }

    /**
     * @dev Struct containing payment details
     */
    struct Payment {
        bytes32 id;
        PaymentType paymentType;
        PaymentMethod paymentMethod;
        PaymentStatus status;
        address payer;
        address payee;
        uint256 amount;
        string currency;
        uint8 jurisdiction;
        bytes32 referenceId;
        bytes32 metadataHash;
        uint256 createdAt;
        uint256 completedAt;
        uint256 expiresAt;
    }

    /**
     * @dev Event emitted when a payment is created
     */
    event PaymentCreated(
        bytes32 indexed paymentId,
        PaymentType indexed paymentType,
        address indexed payer,
        address payee,
        uint256 amount,
        string currency,
        uint8 jurisdiction,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when a payment status is updated
     */
    event PaymentStatusUpdated(
        bytes32 indexed paymentId,
        PaymentStatus previousStatus,
        PaymentStatus newStatus,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when a payment is completed
     */
    event PaymentCompleted(
        bytes32 indexed paymentId,
        address indexed payer,
        address indexed payee,
        uint256 amount,
        string currency,
        uint256 timestamp
    );

    /**
     * @dev Creates a new payment
     * @param paymentType The type of payment to create
     * @param paymentMethod The method of payment
     * @param payee The address of the payment recipient
     * @param amount The payment amount
     * @param currency The currency code (e.g., "USD", "SGD", "BTC")
     * @param jurisdiction The jurisdiction code for the payment
     * @param referenceId Optional reference ID (e.g., invoice number, order ID)
     * @param metadataHash IPFS hash of the payment metadata
     * @param expirationTime Time when the payment expires (0 for no expiration)
     * @param data Additional data required for payment creation
     * @return paymentId The unique identifier for the created payment
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
    ) external returns (bytes32 paymentId);

    /**
     * @dev Processes a payment
     * @param paymentId The unique identifier of the payment
     * @param processingData Additional data required for processing
     * @return success Whether the processing was successful
     */
    function processPayment(
        bytes32 paymentId,
        bytes calldata processingData
    ) external returns (bool success);

    /**
     * @dev Cancels a payment
     * @param paymentId The unique identifier of the payment
     * @param reason Reason for cancellation
     * @return success Whether the cancellation was successful
     */
    function cancelPayment(
        bytes32 paymentId,
        string calldata reason
    ) external returns (bool success);

    /**
     * @dev Refunds a payment
     * @param paymentId The unique identifier of the payment
     * @param amount The amount to refund (0 for full refund)
     * @param reason Reason for refund
     * @return success Whether the refund was successful
     */
    function refundPayment(
        bytes32 paymentId,
        uint256 amount,
        string calldata reason
    ) external returns (bool success);

    /**
     * @dev Gets the details of a payment
     * @param paymentId The unique identifier of the payment
     * @return payment The payment details
     */
    function getPayment(bytes32 paymentId)
        external
        view
        returns (Payment memory payment);

    /**
     * @dev Gets the payments made by an address
     * @param payer The address of the payer
     * @param status Optional filter by payment status (0 for all statuses)
     * @param startIndex Start index for pagination
     * @param limit Maximum number of payments to return
     * @return paymentIds Array of payment IDs made by the payer
     * @return totalCount Total number of payments made by the payer
     */
    function getPaymentsByPayer(
        address payer,
        uint8 status,
        uint256 startIndex,
        uint256 limit
    ) external view returns (bytes32[] memory paymentIds, uint256 totalCount);

    /**
     * @dev Gets the payments received by an address
     * @param payee The address of the payee
     * @param status Optional filter by payment status (0 for all statuses)
     * @param startIndex Start index for pagination
     * @param limit Maximum number of payments to return
     * @return paymentIds Array of payment IDs received by the payee
     * @return totalCount Total number of payments received by the payee
     */
    function getPaymentsByPayee(
        address payee,
        uint8 status,
        uint256 startIndex,
        uint256 limit
    ) external view returns (bytes32[] memory paymentIds, uint256 totalCount);

    /**
     * @dev Creates a recurring payment schedule
     * @param paymentMethod The method of payment
     * @param payee The address of the payment recipient
     * @param amount The payment amount per interval
     * @param currency The currency code
     * @param jurisdiction The jurisdiction code for the payment
     * @param intervalDays The interval between payments in days
     * @param startTime The time of the first payment
     * @param endTime The time when recurring payments end (0 for no end)
     * @param maxPayments Maximum number of payments (0 for unlimited)
     * @param metadataHash IPFS hash of the payment metadata
     * @param data Additional data required for recurring payment creation
     * @return scheduleId The unique identifier for the created payment schedule
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
    ) external returns (bytes32 scheduleId);

    /**
     * @dev Cancels a recurring payment schedule
     * @param scheduleId The unique identifier of the payment schedule
     * @param reason Reason for cancellation
     * @return success Whether the cancellation was successful
     */
    function cancelRecurringPayment(
        bytes32 scheduleId,
        string calldata reason
    ) external returns (bool success);
}
