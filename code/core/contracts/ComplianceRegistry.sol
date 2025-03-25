// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/ICompliance.sol";

/**
 * @title ComplianceRegistry
 * @dev Implementation of the ICompliance interface for managing compliance across jurisdictions
 */
contract ComplianceRegistry is ICompliance {
    // Mapping from verification ID to compliance verification details
    mapping(bytes32 => ComplianceVerification) private _verifications;
    
    // Mapping from jurisdiction to entity to verification type to verification ID
    mapping(Jurisdiction => mapping(address => mapping(string => bytes32))) private _entityVerifications;
    
    // Mapping from jurisdiction to requirement type to requirement hash
    mapping(Jurisdiction => mapping(string => string)) private _complianceRequirements;
    
    // Addresses authorized to perform verifications
    mapping(Jurisdiction => mapping(address => bool)) private _authorizedVerifiers;
    
    // Contract owner
    address private _owner;
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "ComplianceRegistry: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to authorized verifiers for a jurisdiction
     * @param jurisdiction The jurisdiction for which the caller must be authorized
     */
    modifier onlyAuthorizedVerifier(Jurisdiction jurisdiction) {
        require(_authorizedVerifiers[jurisdiction][msg.sender], "ComplianceRegistry: caller is not an authorized verifier");
        _;
    }
    
    /**
     * @dev Constructor
     */
    constructor() {
        _owner = msg.sender;
    }
    
    /**
     * @dev Authorizes a verifier for a jurisdiction
     * @param jurisdiction The jurisdiction for which to authorize the verifier
     * @param verifier The address to authorize
     * @return success Whether the authorization was successful
     */
    function authorizeVerifier(Jurisdiction jurisdiction, address verifier) external onlyOwner returns (bool success) {
        _authorizedVerifiers[jurisdiction][verifier] = true;
        return true;
    }
    
    /**
     * @dev Revokes authorization from a verifier for a jurisdiction
     * @param jurisdiction The jurisdiction for which to revoke authorization
     * @param verifier The address to revoke authorization from
     * @return success Whether the revocation was successful
     */
    function revokeVerifier(Jurisdiction jurisdiction, address verifier) external onlyOwner returns (bool success) {
        _authorizedVerifiers[jurisdiction][verifier] = false;
        return true;
    }
    
    /**
     * @inheritdoc ICompliance
     */
    function verifyCompliance(
        Jurisdiction jurisdiction,
        address entity,
        string calldata verificationType,
        bytes calldata data
    ) external override onlyAuthorizedVerifier(jurisdiction) returns (bytes32 verificationId, ComplianceStatus status) {
        // Generate a unique verification ID
        verificationId = keccak256(abi.encodePacked(jurisdiction, entity, verificationType, block.timestamp));
        
        // Parse the verification status from the data
        ComplianceStatus verificationStatus = ComplianceStatus(abi.decode(data, (uint8)));
        
        // Create the compliance verification
        ComplianceVerification memory verification = ComplianceVerification({
            id: verificationId,
            jurisdiction: jurisdiction,
            entity: entity,
            verificationType: verificationType,
            status: verificationStatus,
            verifier: msg.sender,
            timestamp: block.timestamp,
            evidenceHash: "",
            notes: ""
        });
        
        // If additional data is provided, extract evidence hash and notes
        if (data.length > 32) {
            (uint8 statusValue, string memory evidenceHash, string memory notes) = abi.decode(data, (uint8, string, string));
            verification.evidenceHash = evidenceHash;
            verification.notes = notes;
        }
        
        // Store the verification
        _verifications[verificationId] = verification;
        _entityVerifications[jurisdiction][entity][verificationType] = verificationId;
        
        // Emit the verification event
        emit ComplianceVerified(
            verificationId,
            jurisdiction,
            entity,
            verificationType,
            verification.status,
            msg.sender,
            block.timestamp
        );
        
        return (verificationId, verification.status);
    }
    
    /**
     * @inheritdoc ICompliance
     */
    function getComplianceStatus(
        Jurisdiction jurisdiction,
        address entity,
        string calldata verificationType
    ) external view override returns (ComplianceStatus status) {
        bytes32 verificationId = _entityVerifications[jurisdiction][entity][verificationType];
        
        if (verificationId == bytes32(0)) {
            return ComplianceStatus.PENDING;
        }
        
        return _verifications[verificationId].status;
    }
    
    /**
     * @inheritdoc ICompliance
     */
    function getVerificationDetails(bytes32 verificationId)
        external
        view
        override
        returns (ComplianceVerification memory verification)
    {
        return _verifications[verificationId];
    }
    
    /**
     * @inheritdoc ICompliance
     */
    function isOperationCompliant(
        Jurisdiction jurisdiction,
        string calldata operationType,
        bytes calldata data
    ) external view override returns (bool isCompliant, bytes32[] memory requirementIds) {
        // This is a simplified implementation
        // In a production environment, this would check against specific regulatory requirements
        
        // For demonstration purposes, we'll check if the entity has been verified for this operation type
        address entity = abi.decode(data, (address));
        bytes32 verificationId = _entityVerifications[jurisdiction][entity][operationType];
        
        if (verificationId == bytes32(0)) {
            return (false, new bytes32[](0));
        }
        
        ComplianceVerification memory verification = _verifications[verificationId];
        bool compliant = verification.status == ComplianceStatus.APPROVED;
        
        // Create a single-element array with the verification ID
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = verificationId;
        
        return (compliant, ids);
    }
    
    /**
     * @inheritdoc ICompliance
     */
    function updateComplianceRequirements(
        Jurisdiction jurisdiction,
        string calldata requirementType,
        string calldata requirementHash,
        bytes calldata data
    ) external override onlyOwner {
        _complianceRequirements[jurisdiction][requirementType] = requirementHash;
        
        emit ComplianceRequirementsUpdated(
            jurisdiction,
            requirementType,
            requirementHash
        );
    }
    
    /**
     * @dev Gets the compliance requirement hash for a jurisdiction and requirement type
     * @param jurisdiction The jurisdiction to check
     * @param requirementType The type of requirement to check
     * @return requirementHash The IPFS hash of the requirement documentation
     */
    function getComplianceRequirement(Jurisdiction jurisdiction, string calldata requirementType)
        external
        view
        returns (string memory requirementHash)
    {
        return _complianceRequirements[jurisdiction][requirementType];
    }
    
    /**
     * @dev Checks if a verifier is authorized for a jurisdiction
     * @param jurisdiction The jurisdiction to check
     * @param verifier The address to check
     * @return isAuthorized Whether the verifier is authorized
     */
    function isAuthorizedVerifier(Jurisdiction jurisdiction, address verifier)
        external
        view
        returns (bool isAuthorized)
    {
        return _authorizedVerifiers[jurisdiction][verifier];
    }
}
