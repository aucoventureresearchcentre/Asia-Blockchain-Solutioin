// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IAsset.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IDocument.sol";
import "../../core/interfaces/IJurisdiction.sol";
import "../../core/interfaces/IIdentity.sol";

/**
 * @title InsurancePolicy
 * @dev Implementation for managing insurance policies across Southeast Asian jurisdictions
 */
contract InsurancePolicy {
    // Asset registry interface
    IAsset private _assetRegistry;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Document registry interface
    IDocument private _documentRegistry;
    
    // Jurisdiction registry interface
    IJurisdiction private _jurisdictionRegistry;
    
    // Identity manager interface
    IIdentity private _identityManager;
    
    // Contract owner
    address private _owner;
    
    // Mapping from policy ID to policy details
    mapping(bytes32 => Policy) private _policies;
    
    // Mapping from user address to policy IDs
    mapping(address => bytes32[]) private _userPolicies;
    
    // Mapping from jurisdiction to policy types
    mapping(uint8 => string[]) private _jurisdictionPolicyTypes;
    
    // Enum representing the policy status
    enum PolicyStatus {
        CREATED,
        ACTIVE,
        EXPIRED,
        CANCELLED,
        CLAIMED
    }
    
    // Struct containing policy details
    struct Policy {
        bytes32 id;
        string policyType;
        string policyNumber;
        uint8 jurisdiction;
        address insurer;
        address policyholder;
        uint256 premium;
        uint256 coverage;
        uint256 startDate;
        uint256 endDate;
        PolicyStatus status;
        bytes32[] documentIds;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Events
    event PolicyCreated(
        bytes32 indexed policyId,
        string policyType,
        address indexed insurer,
        address indexed policyholder,
        uint8 jurisdiction,
        uint256 timestamp
    );
    
    event PolicyActivated(
        bytes32 indexed policyId,
        uint256 startDate,
        uint256 endDate,
        uint256 timestamp
    );
    
    event PolicyCancelled(
        bytes32 indexed policyId,
        string reason,
        uint256 timestamp
    );
    
    event PolicyExpired(
        bytes32 indexed policyId,
        uint256 timestamp
    );
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "InsurancePolicy: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the insurer
     * @param policyId The ID of the policy
     */
    modifier onlyInsurer(bytes32 policyId) {
        require(_policies[policyId].insurer == msg.sender, "InsurancePolicy: caller is not the insurer");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the policyholder
     * @param policyId The ID of the policy
     */
    modifier onlyPolicyholder(bytes32 policyId) {
        require(_policies[policyId].policyholder == msg.sender, "InsurancePolicy: caller is not the policyholder");
        _;
    }
    
    /**
     * @dev Constructor
     * @param assetRegistry Address of the asset registry contract
     * @param complianceRegistry Address of the compliance registry contract
     * @param documentRegistry Address of the document registry contract
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     * @param identityManager Address of the identity manager contract
     */
    constructor(
        address assetRegistry,
        address complianceRegistry,
        address documentRegistry,
        address jurisdictionRegistry,
        address identityManager
    ) {
        _owner = msg.sender;
        _assetRegistry = IAsset(assetRegistry);
        _complianceRegistry = ICompliance(complianceRegistry);
        _documentRegistry = IDocument(documentRegistry);
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
        _identityManager = IIdentity(identityManager);
        
        // Initialize policy types for each jurisdiction
        // Malaysia
        _jurisdictionPolicyTypes[0] = ["LIFE", "HEALTH", "PROPERTY", "MOTOR", "TRAVEL"];
        
        // Singapore
        _jurisdictionPolicyTypes[1] = ["LIFE", "HEALTH", "PROPERTY", "MOTOR", "TRAVEL", "BUSINESS"];
        
        // Indonesia
        _jurisdictionPolicyTypes[2] = ["LIFE", "HEALTH", "PROPERTY", "MOTOR", "TRAVEL"];
        
        // Brunei
        _jurisdictionPolicyTypes[3] = ["LIFE", "HEALTH", "PROPERTY", "MOTOR"];
        
        // Thailand
        _jurisdictionPolicyTypes[4] = ["LIFE", "HEALTH", "PROPERTY", "MOTOR", "TRAVEL"];
        
        // Cambodia
        _jurisdictionPolicyTypes[5] = ["LIFE", "HEALTH", "PROPERTY", "MOTOR"];
        
        // Vietnam
        _jurisdictionPolicyTypes[6] = ["LIFE", "HEALTH", "PROPERTY", "MOTOR", "TRAVEL"];
        
        // Laos
        _jurisdictionPolicyTypes[7] = ["LIFE", "HEALTH", "PROPERTY", "MOTOR"];
    }
    
    /**
     * @dev Creates a new insurance policy
     * @param policyType The type of policy
     * @param policyNumber The policy number
     * @param jurisdiction The jurisdiction code for the policy
     * @param policyholder The address of the policyholder
     * @param premium The premium amount
     * @param coverage The coverage amount
     * @param startDate The start date of the policy
     * @param endDate The end date of the policy
     * @param documentIds Array of document IDs associated with the policy
     * @return policyId The unique identifier for the created policy
     */
    function createPolicy(
        string calldata policyType,
        string calldata policyNumber,
        uint8 jurisdiction,
        address policyholder,
        uint256 premium,
        uint256 coverage,
        uint256 startDate,
        uint256 endDate,
        bytes32[] calldata documentIds
    ) external returns (bytes32 policyId) {
        // Check that the jurisdiction is active
        require(
            _jurisdictionRegistry.isJurisdictionActive(jurisdiction),
            "InsurancePolicy: jurisdiction is not active"
        );
        
        // Check that the policy type is valid for the jurisdiction
        bool validPolicyType = false;
        string[] storage validTypes = _jurisdictionPolicyTypes[jurisdiction];
        
        for (uint256 i = 0; i < validTypes.length; i++) {
            if (keccak256(bytes(validTypes[i])) == keccak256(bytes(policyType))) {
                validPolicyType = true;
                break;
            }
        }
        
        require(validPolicyType, "InsurancePolicy: invalid policy type for jurisdiction");
        
        // Check that the policyholder has a verified identity
        require(
            _identityManager.isVerified(policyholder, jurisdiction, IIdentity.VerificationLevel.BASIC),
            "InsurancePolicy: policyholder does not have verified identity"
        );
        
        // Generate a unique policy ID
        policyId = keccak256(abi.encodePacked(msg.sender, policyNumber, policyholder, block.timestamp));
        
        // Create the policy
        Policy memory policy = Policy({
            id: policyId,
            policyType: policyType,
            policyNumber: policyNumber,
            jurisdiction: jurisdiction,
            insurer: msg.sender,
            policyholder: policyholder,
            premium: premium,
            coverage: coverage,
            startDate: startDate,
            endDate: endDate,
            status: PolicyStatus.CREATED,
            documentIds: documentIds,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        // Store the policy
        _policies[policyId] = policy;
        
        // Add the policy to the insurer's policies
        _userPolicies[msg.sender].push(policyId);
        
        // Add the policy to the policyholder's policies
        if (policyholder != msg.sender) {
            _userPolicies[policyholder].push(policyId);
        }
        
        // Create the policy asset in the asset registry
        bytes32 assetId = _assetRegistry.createAsset(
            IAsset.AssetType.INSURANCE_POLICY,
            keccak256(abi.encodePacked(policyId)),
            jurisdiction,
            abi.encode(policyType, policyNumber, premium, coverage)
        );
        
        // Link documents to the asset
        for (uint256 i = 0; i < documentIds.length; i++) {
            _documentRegistry.linkDocumentToAsset(documentIds[i], assetId, "POLICY_DOCUMENT");
        }
        
        // Check compliance
        ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
        (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
            jurisdictionEnum,
            "INSURANCE_POLICY_CREATE",
            abi.encode(msg.sender, policyholder, policyType, premium, coverage)
        );
        
        require(isCompliant, "InsurancePolicy: policy creation is not compliant");
        
        // Emit the policy created event
        emit PolicyCreated(
            policyId,
            policyType,
            msg.sender,
            policyholder,
            jurisdiction,
            block.timestamp
        );
        
        return policyId;
    }
    
    /**
     * @dev Activates an insurance policy
     * @param policyId The ID of the policy
     * @return success Whether the activation was successful
     */
    function activatePolicy(bytes32 policyId)
        external
        onlyInsurer(policyId)
        returns (bool success)
    {
        Policy storage policy = _policies[policyId];
        
        // Check that the policy is in created status
        require(
            policy.status == PolicyStatus.CREATED,
            "InsurancePolicy: policy is not in created status"
        );
        
        // Update the policy status
        policy.status = PolicyStatus.ACTIVE;
        policy.updatedAt = block.timestamp;
        
        // Emit the policy activated event
        emit PolicyActivated(
            policyId,
            policy.startDate,
            policy.endDate,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Cancels an insurance policy
     * @param policyId The ID of the policy
     * @param reason The reason for cancellation
     * @return success Whether the cancellation was successful
     */
    function cancelPolicy(bytes32 policyId, string calldata reason)
        external
        returns (bool success)
    {
        Policy storage policy = _policies[policyId];
        
        // Check that the caller is either the insurer or the policyholder
        require(
            policy.insurer == msg.sender || policy.policyholder == msg.sender,
            "InsurancePolicy: caller is neither the insurer nor the policyholder"
        );
        
        // Check that the policy is active
        require(
            policy.status == PolicyStatus.ACTIVE,
            "InsurancePolicy: policy is not active"
        );
        
        // Update the policy status
        policy.status = PolicyStatus.CANCELLED;
        policy.updatedAt = block.timestamp;
        
        // Emit the policy cancelled event
        emit PolicyCancelled(
            policyId,
            reason,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Expires an insurance policy
     * @param policyId The ID of the policy
     * @return success Whether the expiration was successful
     */
    function expirePolicy(bytes32 policyId)
        external
        onlyInsurer(policyId)
        returns (bool success)
    {
        Policy storage policy = _policies[policyId];
        
        // Check that the policy is active
        require(
            policy.status == PolicyStatus.ACTIVE,
            "InsurancePolicy: policy is not active"
        );
        
        // Check that the current time is after the end date
        require(
            block.timestamp > policy.endDate,
            "InsurancePolicy: policy has not reached end date"
        );
        
        // Update the policy status
        policy.status = PolicyStatus.EXPIRED;
        policy.updatedAt = block.timestamp;
        
        // Emit the policy expired event
        emit PolicyExpired(
            policyId,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Gets the details of a policy
     * @param policyId The ID of the policy
     * @return policy The policy details
     */
    function getPolicy(bytes32 policyId) external view returns (Policy memory policy) {
        return _policies[policyId];
    }
    
    /**
     * @dev Gets the policies for a user
     * @param userAddress The address of the user
     * @return policyIds Array of policy IDs for the user
     */
    function getUserPolicies(address userAddress) external view returns (bytes32[] memory policyIds) {
        return _userPolicies[userAddress];
    }
    
    /**
     * @dev Gets the valid policy types for a jurisdiction
     * @param jurisdiction The jurisdiction code
     * @return policyTypes Array of valid policy types for the jurisdiction
     */
    function getJurisdictionPolicyTypes(uint8 jurisdiction) external view returns (string[] memory policyTypes) {
        return _jurisdictionPolicyTypes[jurisdiction];
    }
    
    /**
     * @dev Sets the asset registry address
     * @param assetRegistry Address of the asset registry contract
     * @return success Whether the update was successful
     */
    function setAssetRegistry(address assetRegistry) external onlyOwner returns (bool success) {
        _assetRegistry = IAsset(assetRegistry);
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
     * @dev Sets the document registry address
     * @param documentRegistry Address of the document registry contract
     * @return success Whether the update was successful
     */
    function setDocumentRegistry(address documentRegistry) external onlyOwner returns (bool success) {
        _documentRegistry = IDocument(documentRegistry);
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
