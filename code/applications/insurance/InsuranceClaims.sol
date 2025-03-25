// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IAsset.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IDocument.sol";
import "../../core/interfaces/IJurisdiction.sol";
import "../../core/interfaces/IPayment.sol";

/**
 * @title InsuranceClaims
 * @dev Implementation for managing insurance claims across Southeast Asian jurisdictions
 */
contract InsuranceClaims {
    // Asset registry interface
    IAsset private _assetRegistry;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Document registry interface
    IDocument private _documentRegistry;
    
    // Jurisdiction registry interface
    IJurisdiction private _jurisdictionRegistry;
    
    // Payment processor interface
    IPayment private _paymentProcessor;
    
    // InsurancePolicy contract address
    address private _insurancePolicy;
    
    // Contract owner
    address private _owner;
    
    // Mapping from claim ID to claim details
    mapping(bytes32 => Claim) private _claims;
    
    // Mapping from policy ID to claim IDs
    mapping(bytes32 => bytes32[]) private _policyClaims;
    
    // Enum representing the claim status
    enum ClaimStatus {
        SUBMITTED,
        UNDER_REVIEW,
        APPROVED,
        REJECTED,
        PAID,
        DISPUTED
    }
    
    // Struct containing claim details
    struct Claim {
        bytes32 id;
        bytes32 policyId;
        address claimant;
        string claimType;
        string description;
        uint256 amount;
        uint8 jurisdiction;
        ClaimStatus status;
        string rejectionReason;
        bytes32[] documentIds;
        uint256 submittedAt;
        uint256 updatedAt;
        uint256 paidAt;
    }
    
    // Events
    event ClaimSubmitted(
        bytes32 indexed claimId,
        bytes32 indexed policyId,
        address indexed claimant,
        string claimType,
        uint256 amount,
        uint256 timestamp
    );
    
    event ClaimStatusUpdated(
        bytes32 indexed claimId,
        ClaimStatus previousStatus,
        ClaimStatus newStatus,
        uint256 timestamp
    );
    
    event ClaimPaid(
        bytes32 indexed claimId,
        bytes32 indexed policyId,
        address indexed claimant,
        uint256 amount,
        uint256 timestamp
    );
    
    event ClaimDisputed(
        bytes32 indexed claimId,
        address indexed disputer,
        string reason,
        uint256 timestamp
    );
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "InsuranceClaims: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the insurer
     * @param claimId The ID of the claim
     */
    modifier onlyInsurer(bytes32 claimId) {
        // Get the policy ID for the claim
        bytes32 policyId = _claims[claimId].policyId;
        
        // Get the policy details from the InsurancePolicy contract
        (
            bytes32 id,
            string memory policyType,
            string memory policyNumber,
            uint8 jurisdiction,
            address insurer,
            address policyholder,
            uint256 premium,
            uint256 coverage,
            uint256 startDate,
            uint256 endDate,
            uint status,
            bytes32[] memory documentIds,
            uint256 createdAt,
            uint256 updatedAt
        ) = getPolicy(policyId);
        
        require(insurer == msg.sender, "InsuranceClaims: caller is not the insurer");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the claimant
     * @param claimId The ID of the claim
     */
    modifier onlyClaimant(bytes32 claimId) {
        require(_claims[claimId].claimant == msg.sender, "InsuranceClaims: caller is not the claimant");
        _;
    }
    
    /**
     * @dev Constructor
     * @param assetRegistry Address of the asset registry contract
     * @param complianceRegistry Address of the compliance registry contract
     * @param documentRegistry Address of the document registry contract
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     * @param paymentProcessor Address of the payment processor contract
     * @param insurancePolicy Address of the insurance policy contract
     */
    constructor(
        address assetRegistry,
        address complianceRegistry,
        address documentRegistry,
        address jurisdictionRegistry,
        address paymentProcessor,
        address insurancePolicy
    ) {
        _owner = msg.sender;
        _assetRegistry = IAsset(assetRegistry);
        _complianceRegistry = ICompliance(complianceRegistry);
        _documentRegistry = IDocument(documentRegistry);
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
        _paymentProcessor = IPayment(paymentProcessor);
        _insurancePolicy = insurancePolicy;
    }
    
    /**
     * @dev Submits a new insurance claim
     * @param policyId The ID of the policy
     * @param claimType The type of claim
     * @param description The description of the claim
     * @param amount The amount claimed
     * @param documentIds Array of document IDs associated with the claim
     * @return claimId The unique identifier for the submitted claim
     */
    function submitClaim(
        bytes32 policyId,
        string calldata claimType,
        string calldata description,
        uint256 amount,
        bytes32[] calldata documentIds
    ) external returns (bytes32 claimId) {
        // Get the policy details from the InsurancePolicy contract
        (
            bytes32 id,
            string memory policyType,
            string memory policyNumber,
            uint8 jurisdiction,
            address insurer,
            address policyholder,
            uint256 premium,
            uint256 coverage,
            uint256 startDate,
            uint256 endDate,
            uint status,
            bytes32[] memory policyDocumentIds,
            uint256 createdAt,
            uint256 updatedAt
        ) = getPolicy(policyId);
        
        // Check that the policy exists
        require(id == policyId, "InsuranceClaims: policy does not exist");
        
        // Check that the policy is active
        require(status == 1, "InsuranceClaims: policy is not active"); // 1 = ACTIVE
        
        // Check that the caller is the policyholder
        require(policyholder == msg.sender, "InsuranceClaims: caller is not the policyholder");
        
        // Check that the claim amount is within the coverage
        require(amount <= coverage, "InsuranceClaims: claim amount exceeds coverage");
        
        // Generate a unique claim ID
        claimId = keccak256(abi.encodePacked(msg.sender, policyId, block.timestamp));
        
        // Create the claim
        Claim memory claim = Claim({
            id: claimId,
            policyId: policyId,
            claimant: msg.sender,
            claimType: claimType,
            description: description,
            amount: amount,
            jurisdiction: jurisdiction,
            status: ClaimStatus.SUBMITTED,
            rejectionReason: "",
            documentIds: documentIds,
            submittedAt: block.timestamp,
            updatedAt: block.timestamp,
            paidAt: 0
        });
        
        // Store the claim
        _claims[claimId] = claim;
        
        // Add the claim to the policy's claims
        _policyClaims[policyId].push(claimId);
        
        // Check compliance
        ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
        (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
            jurisdictionEnum,
            "INSURANCE_CLAIM_SUBMIT",
            abi.encode(msg.sender, policyId, claimType, amount)
        );
        
        require(isCompliant, "InsuranceClaims: claim submission is not compliant");
        
        // Emit the claim submitted event
        emit ClaimSubmitted(
            claimId,
            policyId,
            msg.sender,
            claimType,
            amount,
            block.timestamp
        );
        
        return claimId;
    }
    
    /**
     * @dev Reviews a claim
     * @param claimId The ID of the claim
     * @param newStatus The new status for the claim
     * @param rejectionReason The reason for rejection (if rejected)
     * @return success Whether the review was successful
     */
    function reviewClaim(
        bytes32 claimId,
        ClaimStatus newStatus,
        string calldata rejectionReason
    ) external onlyInsurer(claimId) returns (bool success) {
        Claim storage claim = _claims[claimId];
        
        // Check that the claim is in a reviewable state
        require(
            claim.status == ClaimStatus.SUBMITTED || claim.status == ClaimStatus.UNDER_REVIEW,
            "InsuranceClaims: claim is not in a reviewable state"
        );
        
        // Check that the new status is valid
        require(
            newStatus == ClaimStatus.UNDER_REVIEW || newStatus == ClaimStatus.APPROVED || newStatus == ClaimStatus.REJECTED,
            "InsuranceClaims: invalid new status"
        );
        
        // If rejecting, require a reason
        if (newStatus == ClaimStatus.REJECTED) {
            require(bytes(rejectionReason).length > 0, "InsuranceClaims: rejection reason required");
            claim.rejectionReason = rejectionReason;
        }
        
        // Store the previous status for the event
        ClaimStatus previousStatus = claim.status;
        
        // Update the claim status
        claim.status = newStatus;
        claim.updatedAt = block.timestamp;
        
        // Emit the claim status updated event
        emit ClaimStatusUpdated(
            claimId,
            previousStatus,
            newStatus,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Pays a claim
     * @param claimId The ID of the claim
     * @param paymentMethod The payment method to use
     * @param paymentData Additional payment data
     * @return success Whether the payment was successful
     */
    function payClaim(
        bytes32 claimId,
        IPayment.PaymentMethod paymentMethod,
        bytes calldata paymentData
    ) external onlyInsurer(claimId) returns (bool success) {
        Claim storage claim = _claims[claimId];
        
        // Check that the claim is approved
        require(
            claim.status == ClaimStatus.APPROVED,
            "InsuranceClaims: claim is not approved"
        );
        
        // Process the payment
        bytes32 paymentId = _paymentProcessor.processPayment(
            msg.sender,
            claim.claimant,
            claim.amount,
            paymentMethod,
            paymentData
        );
        
        // Update the claim status
        claim.status = ClaimStatus.PAID;
        claim.updatedAt = block.timestamp;
        claim.paidAt = block.timestamp;
        
        // Emit the claim paid event
        emit ClaimPaid(
            claimId,
            claim.policyId,
            claim.claimant,
            claim.amount,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Disputes a claim
     * @param claimId The ID of the claim
     * @param reason The reason for the dispute
     * @return success Whether the dispute was raised successfully
     */
    function disputeClaim(bytes32 claimId, string calldata reason)
        external
        onlyClaimant(claimId)
        returns (bool success)
    {
        Claim storage claim = _claims[claimId];
        
        // Check that the claim is in a disputable state
        require(
            claim.status == ClaimStatus.REJECTED,
            "InsuranceClaims: claim is not in a disputable state"
        );
        
        // Update the claim status
        claim.status = ClaimStatus.DISPUTED;
        claim.updatedAt = block.timestamp;
        
        // Emit the claim disputed event
        emit ClaimDisputed(
            claimId,
            msg.sender,
            reason,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Gets the details of a claim
     * @param claimId The ID of the claim
     * @return claim The claim details
     */
    function getClaim(bytes32 claimId) external view returns (Claim memory claim) {
        return _claims[claimId];
    }
    
    /**
     * @dev Gets the claims for a policy
     * @param policyId The ID of the policy
     * @return claimIds Array of claim IDs for the policy
     */
    function getPolicyClaims(bytes32 policyId) external view returns (bytes32[] memory claimIds) {
        return _policyClaims[policyId];
    }
    
    /**
     * @dev Gets a policy from the InsurancePolicy contract
     * @param policyId The ID of the policy
     * @return Policy details
     */
    function getPolicy(bytes32 policyId) internal view returns (
        bytes32 id,
        string memory policyType,
        string memory policyNumber,
        uint8 jurisdiction,
        address insurer,
        address policyholder,
        uint256 premium,
        uint256 coverage,
        uint256 startDate,
        uint256 endDate,
        uint status,
        bytes32[] memory documentIds,
        uint256 createdAt,
        uint256 updatedAt
    ) {
        // Call the InsurancePolicy contract to get the policy details
        bytes memory data = abi.encodeWithSignature("getPolicy(bytes32)", policyId);
        (bool success, bytes memory returnData) = _insurancePolicy.staticcall(data);
        
        require(success, "InsuranceClaims: failed to get policy");
        
        // Decode the policy details
        return abi.decode(returnData, (
            bytes32,
            string,
            string,
            uint8,
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint,
            bytes32[],
            uint256,
            uint256
        ));
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
     * @dev Sets the payment processor address
     * @param paymentProcessor Address of the payment processor contract
     * @return success Whether the update was successful
     */
    function setPaymentProcessor(address paymentProcessor) external onlyOwner returns (bool success) {
        _paymentProcessor = IPayment(paymentProcessor);
        return true;
    }
    
    /**
     * @dev Sets the insurance policy address
     * @param insurancePolicy Address of the insurance policy contract
     * @return success Whether the update was successful
     */
    function setInsurancePolicy(address insurancePolicy) external onlyOwner returns (bool success) {
        _insurancePolicy = insurancePolicy;
        return true;
    }
}
