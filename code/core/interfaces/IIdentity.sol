// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IIdentity
 * @dev Interface for identity management across different jurisdictions
 * @notice This interface defines the standard methods for identity verification and management
 */
interface IIdentity {
    /**
     * @dev Enum representing the identity verification levels
     */
    enum VerificationLevel {
        NONE,
        BASIC,
        STANDARD,
        ENHANCED
    }

    /**
     * @dev Enum representing the identity verification status
     */
    enum VerificationStatus {
        NOT_SUBMITTED,
        PENDING,
        APPROVED,
        REJECTED,
        EXPIRED
    }

    /**
     * @dev Struct containing identity verification details
     */
    struct IdentityVerification {
        address userAddress;
        uint8 jurisdiction;
        VerificationLevel level;
        VerificationStatus status;
        bytes32 documentHash;
        address verifier;
        uint256 verifiedAt;
        uint256 expiresAt;
    }

    /**
     * @dev Event emitted when an identity verification is requested
     */
    event VerificationRequested(
        address indexed userAddress,
        uint8 indexed jurisdiction,
        VerificationLevel level,
        bytes32 documentHash,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when an identity verification status is updated
     */
    event VerificationStatusUpdated(
        address indexed userAddress,
        uint8 indexed jurisdiction,
        VerificationLevel level,
        VerificationStatus previousStatus,
        VerificationStatus newStatus,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when an identity is verified
     */
    event IdentityVerified(
        address indexed userAddress,
        uint8 indexed jurisdiction,
        VerificationLevel level,
        address indexed verifier,
        uint256 timestamp,
        uint256 expiresAt
    );

    /**
     * @dev Requests identity verification
     * @param jurisdiction The jurisdiction code for the verification
     * @param level The requested verification level
     * @param documentHash IPFS hash of the identity documents
     * @param data Additional data required for verification
     * @return success Whether the request was successful
     */
    function requestVerification(
        uint8 jurisdiction,
        VerificationLevel level,
        bytes32 documentHash,
        bytes calldata data
    ) external returns (bool success);

    /**
     * @dev Verifies an identity
     * @param userAddress The address of the user to verify
     * @param jurisdiction The jurisdiction code for the verification
     * @param level The verification level
     * @param expirationTime Time when the verification expires
     * @param data Additional data for the verification
     * @return success Whether the verification was successful
     */
    function verifyIdentity(
        address userAddress,
        uint8 jurisdiction,
        VerificationLevel level,
        uint256 expirationTime,
        bytes calldata data
    ) external returns (bool success);

    /**
     * @dev Rejects an identity verification
     * @param userAddress The address of the user
     * @param jurisdiction The jurisdiction code for the verification
     * @param reason Reason for rejection
     * @return success Whether the rejection was successful
     */
    function rejectVerification(
        address userAddress,
        uint8 jurisdiction,
        string calldata reason
    ) external returns (bool success);

    /**
     * @dev Gets the verification status of an identity
     * @param userAddress The address of the user
     * @param jurisdiction The jurisdiction code for the verification
     * @return level The verification level
     * @return status The verification status
     * @return expiresAt The expiration time of the verification
     */
    function getVerificationStatus(address userAddress, uint8 jurisdiction)
        external
        view
        returns (
            VerificationLevel level,
            VerificationStatus status,
            uint256 expiresAt
        );

    /**
     * @dev Gets the full verification details of an identity
     * @param userAddress The address of the user
     * @param jurisdiction The jurisdiction code for the verification
     * @return verification The identity verification details
     */
    function getVerificationDetails(address userAddress, uint8 jurisdiction)
        external
        view
        returns (IdentityVerification memory verification);

    /**
     * @dev Checks if an identity is verified at a specific level
     * @param userAddress The address of the user
     * @param jurisdiction The jurisdiction code for the verification
     * @param requiredLevel The minimum required verification level
     * @return isVerified Whether the identity is verified at the required level
     */
    function isVerified(
        address userAddress,
        uint8 jurisdiction,
        VerificationLevel requiredLevel
    ) external view returns (bool isVerified);

    /**
     * @dev Gets the jurisdictions where an identity is verified
     * @param userAddress The address of the user
     * @return jurisdictions Array of jurisdiction codes where the identity is verified
     * @return levels Array of verification levels corresponding to each jurisdiction
     */
    function getVerifiedJurisdictions(address userAddress)
        external
        view
        returns (uint8[] memory jurisdictions, VerificationLevel[] memory levels);
}
