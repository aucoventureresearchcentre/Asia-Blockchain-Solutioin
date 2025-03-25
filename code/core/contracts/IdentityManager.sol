// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IIdentity.sol";
import "../interfaces/ICompliance.sol";

/**
 * @title IdentityManager
 * @dev Implementation of the IIdentity interface for managing identities across jurisdictions
 */
contract IdentityManager is IIdentity {
    // Mapping from user address to jurisdiction to identity verification details
    mapping(address => mapping(uint8 => IdentityVerification)) private _verifications;
    
    // Mapping from user address to verified jurisdictions
    mapping(address => uint8[]) private _userJurisdictions;
    
    // Addresses authorized to verify identities
    mapping(uint8 => mapping(address => bool)) private _authorizedVerifiers;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Contract owner
    address private _owner;
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "IdentityManager: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to authorized verifiers for a jurisdiction
     * @param jurisdiction The jurisdiction for which the caller must be authorized
     */
    modifier onlyAuthorizedVerifier(uint8 jurisdiction) {
        require(_authorizedVerifiers[jurisdiction][msg.sender], "IdentityManager: caller is not an authorized verifier");
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
     * @inheritdoc IIdentity
     */
    function requestVerification(
        uint8 jurisdiction,
        VerificationLevel level,
        bytes32 documentHash,
        bytes calldata data
    ) external override returns (bool success) {
        // Create or update the verification request
        IdentityVerification storage verification = _verifications[msg.sender][jurisdiction];
        
        // If this is a new verification for this user and jurisdiction, add to the user's jurisdictions
        if (verification.userAddress == address(0)) {
            verification.userAddress = msg.sender;
            verification.jurisdiction = jurisdiction;
            _userJurisdictions[msg.sender].push(jurisdiction);
        }
        
        // Update the verification details
        verification.level = level;
        verification.status = VerificationStatus.PENDING;
        verification.documentHash = documentHash;
        
        // Emit the verification request event
        emit VerificationRequested(
            msg.sender,
            jurisdiction,
            level,
            documentHash,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc IIdentity
     */
    function verifyIdentity(
        address userAddress,
        uint8 jurisdiction,
        VerificationLevel level,
        uint256 expirationTime,
        bytes calldata data
    ) external override onlyAuthorizedVerifier(jurisdiction) returns (bool success) {
        IdentityVerification storage verification = _verifications[userAddress][jurisdiction];
        
        // Check that the verification request exists
        require(verification.userAddress == userAddress, "IdentityManager: verification request does not exist");
        
        // Check that the verification is in a verifiable state
        require(
            verification.status == VerificationStatus.PENDING,
            "IdentityManager: verification is not in a verifiable state"
        );
        
        // Store the previous status for the event
        VerificationStatus previousStatus = verification.status;
        
        // Update the verification details
        verification.level = level;
        verification.status = VerificationStatus.APPROVED;
        verification.verifier = msg.sender;
        verification.verifiedAt = block.timestamp;
        verification.expiresAt = expirationTime > 0 ? expirationTime : 0;
        
        // Check compliance if a compliance registry is set
        if (address(_complianceRegistry) != address(0)) {
            // Convert jurisdiction to the enum type expected by the compliance registry
            ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
            
            // Record the verification in the compliance registry
            _complianceRegistry.verifyCompliance(
                jurisdictionEnum,
                userAddress,
                "IDENTITY_VERIFICATION",
                abi.encode(uint8(ICompliance.ComplianceStatus.APPROVED), "", "")
            );
        }
        
        // Emit the verification status update event
        emit VerificationStatusUpdated(
            userAddress,
            jurisdiction,
            level,
            previousStatus,
            VerificationStatus.APPROVED,
            block.timestamp
        );
        
        // Emit the identity verified event
        emit IdentityVerified(
            userAddress,
            jurisdiction,
            level,
            msg.sender,
            block.timestamp,
            expirationTime
        );
        
        return true;
    }
    
    /**
     * @inheritdoc IIdentity
     */
    function rejectVerification(
        address userAddress,
        uint8 jurisdiction,
        string calldata reason
    ) external override onlyAuthorizedVerifier(jurisdiction) returns (bool success) {
        IdentityVerification storage verification = _verifications[userAddress][jurisdiction];
        
        // Check that the verification request exists
        require(verification.userAddress == userAddress, "IdentityManager: verification request does not exist");
        
        // Check that the verification is in a rejectable state
        require(
            verification.status == VerificationStatus.PENDING,
            "IdentityManager: verification is not in a rejectable state"
        );
        
        // Store the previous status for the event
        VerificationStatus previousStatus = verification.status;
        
        // Update the verification status
        verification.status = VerificationStatus.REJECTED;
        verification.verifier = msg.sender;
        
        // Check compliance if a compliance registry is set
        if (address(_complianceRegistry) != address(0)) {
            // Convert jurisdiction to the enum type expected by the compliance registry
            ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
            
            // Record the rejection in the compliance registry
            _complianceRegistry.verifyCompliance(
                jurisdictionEnum,
                userAddress,
                "IDENTITY_VERIFICATION",
                abi.encode(uint8(ICompliance.ComplianceStatus.REJECTED), "", reason)
            );
        }
        
        // Emit the verification status update event
        emit VerificationStatusUpdated(
            userAddress,
            jurisdiction,
            verification.level,
            previousStatus,
            VerificationStatus.REJECTED,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc IIdentity
     */
    function getVerificationStatus(address userAddress, uint8 jurisdiction)
        external
        view
        override
        returns (
            VerificationLevel level,
            VerificationStatus status,
            uint256 expiresAt
        )
    {
        IdentityVerification storage verification = _verifications[userAddress][jurisdiction];
        
        // If the verification doesn't exist, return default values
        if (verification.userAddress == address(0)) {
            return (VerificationLevel.NONE, VerificationStatus.NOT_SUBMITTED, 0);
        }
        
        // Check if the verification has expired
        if (verification.expiresAt > 0 && block.timestamp > verification.expiresAt) {
            return (verification.level, VerificationStatus.EXPIRED, verification.expiresAt);
        }
        
        return (verification.level, verification.status, verification.expiresAt);
    }
    
    /**
     * @inheritdoc IIdentity
     */
    function getVerificationDetails(address userAddress, uint8 jurisdiction)
        external
        view
        override
        returns (IdentityVerification memory verification)
    {
        return _verifications[userAddress][jurisdiction];
    }
    
    /**
     * @inheritdoc IIdentity
     */
    function isVerified(
        address userAddress,
        uint8 jurisdiction,
        VerificationLevel requiredLevel
    ) external view override returns (bool isVerified) {
        IdentityVerification storage verification = _verifications[userAddress][jurisdiction];
        
        // Check if the verification exists, is approved, and meets the required level
        if (verification.userAddress == address(0) || verification.status != VerificationStatus.APPROVED) {
            return false;
        }
        
        // Check if the verification has expired
        if (verification.expiresAt > 0 && block.timestamp > verification.expiresAt) {
            return false;
        }
        
        // Check if the verification level meets the required level
        return uint8(verification.level) >= uint8(requiredLevel);
    }
    
    /**
     * @inheritdoc IIdentity
     */
    function getVerifiedJurisdictions(address userAddress)
        external
        view
        override
        returns (uint8[] memory jurisdictions, VerificationLevel[] memory levels)
    {
        uint8[] storage userJurisdictions = _userJurisdictions[userAddress];
        uint256 count = userJurisdictions.length;
        
        // Count verified jurisdictions
        uint256 verifiedCount = 0;
        for (uint256 i = 0; i < count; i++) {
            uint8 jurisdiction = userJurisdictions[i];
            IdentityVerification storage verification = _verifications[userAddress][jurisdiction];
            
            if (verification.status == VerificationStatus.APPROVED) {
                // Check if the verification has expired
                if (verification.expiresAt == 0 || block.timestamp <= verification.expiresAt) {
                    verifiedCount++;
                }
            }
        }
        
        // Create the result arrays
        jurisdictions = new uint8[](verifiedCount);
        levels = new VerificationLevel[](verifiedCount);
        
        // Fill the result arrays
        uint256 resultIndex = 0;
        for (uint256 i = 0; i < count && resultIndex < verifiedCount; i++) {
            uint8 jurisdiction = userJurisdictions[i];
            IdentityVerification storage verification = _verifications[userAddress][jurisdiction];
            
            if (verification.status == VerificationStatus.APPROVED) {
                // Check if the verification has expired
                if (verification.expiresAt == 0 || block.timestamp <= verification.expiresAt) {
                    jurisdictions[resultIndex] = jurisdiction;
                    levels[resultIndex] = verification.level;
                    resultIndex++;
                }
            }
        }
        
        return (jurisdictions, levels);
    }
    
    /**
     * @dev Authorizes a verifier for a jurisdiction
     * @param jurisdiction The jurisdiction for which to authorize the verifier
     * @param verifier The address to authorize
     * @return success Whether the authorization was successful
     */
    function authorizeVerifier(uint8 jurisdiction, address verifier) external onlyOwner returns (bool success) {
        _authorizedVerifiers[jurisdiction][verifier] = true;
        return true;
    }
    
    /**
     * @dev Revokes authorization from a verifier for a jurisdiction
     * @param jurisdiction The jurisdiction for which to revoke authorization
     * @param verifier The address to revoke authorization from
     * @return success Whether the revocation was successful
     */
    function revokeVerifier(uint8 jurisdiction, address verifier) external onlyOwner returns (bool success) {
        _authorizedVerifiers[jurisdiction][verifier] = false;
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
     * @dev Checks if a verifier is authorized for a jurisdiction
     * @param jurisdiction The jurisdiction to check
     * @param verifier The address to check
     * @return isAuthorized Whether the verifier is authorized
     */
    function isAuthorizedVerifier(uint8 jurisdiction, address verifier)
        external
        view
        returns (bool isAuthorized)
    {
        return _authorizedVerifiers[jurisdiction][verifier];
    }
}
