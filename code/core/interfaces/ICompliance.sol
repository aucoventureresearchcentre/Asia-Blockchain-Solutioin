// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ICompliance
 * @dev Interface for compliance verification across different jurisdictions
 * @notice This interface defines the standard methods for regulatory compliance checks
 */
interface ICompliance {
    /**
     * @dev Enum representing the supported jurisdictions
     */
    enum Jurisdiction {
        MALAYSIA,
        SINGAPORE,
        INDONESIA,
        BRUNEI,
        THAILAND,
        CAMBODIA,
        VIETNAM,
        LAOS
    }

    /**
     * @dev Enum representing the compliance verification status
     */
    enum ComplianceStatus {
        PENDING,
        APPROVED,
        REJECTED,
        EXEMPTED
    }

    /**
     * @dev Struct containing compliance verification details
     */
    struct ComplianceVerification {
        bytes32 id;
        Jurisdiction jurisdiction;
        address entity;
        string verificationType;
        ComplianceStatus status;
        address verifier;
        uint256 timestamp;
        string evidenceHash;
        string notes;
    }

    /**
     * @dev Event emitted when a compliance verification is performed
     */
    event ComplianceVerified(
        bytes32 indexed verificationId,
        Jurisdiction indexed jurisdiction,
        address indexed entity,
        string verificationType,
        ComplianceStatus status,
        address verifier,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when compliance requirements are updated
     */
    event ComplianceRequirementsUpdated(
        Jurisdiction indexed jurisdiction,
        string requirementType,
        string requirementHash
    );

    /**
     * @dev Verifies compliance for an entity in a specific jurisdiction
     * @param jurisdiction The jurisdiction for compliance verification
     * @param entity The address of the entity to verify
     * @param verificationType The type of verification to perform
     * @param data Additional data required for verification
     * @return verificationId The unique identifier for this verification
     * @return status The status of the compliance verification
     */
    function verifyCompliance(
        Jurisdiction jurisdiction,
        address entity,
        string calldata verificationType,
        bytes calldata data
    ) external returns (bytes32 verificationId, ComplianceStatus status);

    /**
     * @dev Gets the compliance status for an entity in a specific jurisdiction
     * @param jurisdiction The jurisdiction for compliance verification
     * @param entity The address of the entity to check
     * @param verificationType The type of verification to check
     * @return status The status of the compliance verification
     */
    function getComplianceStatus(
        Jurisdiction jurisdiction,
        address entity,
        string calldata verificationType
    ) external view returns (ComplianceStatus status);

    /**
     * @dev Gets the compliance verification details
     * @param verificationId The unique identifier for the verification
     * @return verification The compliance verification details
     */
    function getVerificationDetails(bytes32 verificationId)
        external
        view
        returns (ComplianceVerification memory verification);

    /**
     * @dev Checks if an operation is compliant in a specific jurisdiction
     * @param jurisdiction The jurisdiction for compliance verification
     * @param operationType The type of operation to check
     * @param data Additional data required for verification
     * @return isCompliant Whether the operation is compliant
     * @return requirementIds List of requirement IDs that must be met
     */
    function isOperationCompliant(
        Jurisdiction jurisdiction,
        string calldata operationType,
        bytes calldata data
    ) external view returns (bool isCompliant, bytes32[] memory requirementIds);

    /**
     * @dev Updates the compliance requirements for a jurisdiction
     * @param jurisdiction The jurisdiction to update
     * @param requirementType The type of requirement to update
     * @param requirementHash IPFS hash of the requirement documentation
     * @param data Additional data for the requirement update
     */
    function updateComplianceRequirements(
        Jurisdiction jurisdiction,
        string calldata requirementType,
        string calldata requirementHash,
        bytes calldata data
    ) external;
}
