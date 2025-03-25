// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IDocument.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IJurisdiction.sol";
import "../../core/interfaces/IIdentity.sol";

/**
 * @title LegalContractExecution
 * @dev Implementation for executing legal contracts across Southeast Asian jurisdictions
 */
contract LegalContractExecution {
    // Document registry interface
    IDocument private _documentRegistry;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Jurisdiction registry interface
    IJurisdiction private _jurisdictionRegistry;
    
    // Identity manager interface
    IIdentity private _identityManager;
    
    // LegalContractTemplate contract address
    address private _legalContractTemplate;
    
    // Contract owner
    address private _owner;
    
    // Mapping from contract ID to contract details
    mapping(bytes32 => LegalContract) private _contracts;
    
    // Mapping from user address to contract IDs
    mapping(address => bytes32[]) private _userContracts;
    
    // Enum representing the contract status
    enum ContractStatus {
        DRAFT,
        PENDING_SIGNATURES,
        EXECUTED,
        EXPIRED,
        TERMINATED,
        DISPUTED
    }
    
    // Struct containing contract details
    struct LegalContract {
        bytes32 id;
        string name;
        bytes32 templateId;
        uint8 jurisdiction;
        bytes32 contentHash;
        ContractStatus status;
        address creator;
        address[] parties;
        mapping(address => bool) hasSigned;
        mapping(address => uint256) signatureTimestamps;
        uint256 effectiveDate;
        uint256 expirationDate;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Struct for returning contract details (without mappings)
    struct LegalContractView {
        bytes32 id;
        string name;
        bytes32 templateId;
        uint8 jurisdiction;
        bytes32 contentHash;
        ContractStatus status;
        address creator;
        address[] parties;
        uint256 effectiveDate;
        uint256 expirationDate;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Events
    event ContractCreated(
        bytes32 indexed contractId,
        bytes32 indexed templateId,
        address indexed creator,
        uint8 jurisdiction,
        uint256 timestamp
    );
    
    event ContractSigned(
        bytes32 indexed contractId,
        address indexed signer,
        uint256 timestamp
    );
    
    event ContractExecuted(
        bytes32 indexed contractId,
        uint256 effectiveDate,
        uint256 expirationDate,
        uint256 timestamp
    );
    
    event ContractTerminated(
        bytes32 indexed contractId,
        address indexed terminator,
        string reason,
        uint256 timestamp
    );
    
    event ContractDisputed(
        bytes32 indexed contractId,
        address indexed disputer,
        string reason,
        uint256 timestamp
    );
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "LegalContractExecution: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the contract creator
     * @param contractId The ID of the contract
     */
    modifier onlyContractCreator(bytes32 contractId) {
        require(_contracts[contractId].creator == msg.sender, "LegalContractExecution: caller is not the contract creator");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to contract parties
     * @param contractId The ID of the contract
     */
    modifier onlyContractParty(bytes32 contractId) {
        bool isParty = false;
        address[] storage parties = _contracts[contractId].parties;
        
        for (uint256 i = 0; i < parties.length; i++) {
            if (parties[i] == msg.sender) {
                isParty = true;
                break;
            }
        }
        
        require(isParty, "LegalContractExecution: caller is not a contract party");
        _;
    }
    
    /**
     * @dev Constructor
     * @param documentRegistry Address of the document registry contract
     * @param complianceRegistry Address of the compliance registry contract
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     * @param identityManager Address of the identity manager contract
     * @param legalContractTemplate Address of the legal contract template contract
     */
    constructor(
        address documentRegistry,
        address complianceRegistry,
        address jurisdictionRegistry,
        address identityManager,
        address legalContractTemplate
    ) {
        _owner = msg.sender;
        _documentRegistry = IDocument(documentRegistry);
        _complianceRegistry = ICompliance(complianceRegistry);
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
        _identityManager = IIdentity(identityManager);
        _legalContractTemplate = legalContractTemplate;
    }
    
    /**
     * @dev Creates a new legal contract
     * @param name The name of the contract
     * @param templateId The ID of the template to use
     * @param contentHash The hash of the contract content
     * @param parties Array of addresses for the contract parties
     * @param effectiveDate The date when the contract becomes effective
     * @param expirationDate The date when the contract expires
     * @return contractId The unique identifier for the created contract
     */
    function createContract(
        string calldata name,
        bytes32 templateId,
        bytes32 contentHash,
        address[] calldata parties,
        uint256 effectiveDate,
        uint256 expirationDate
    ) external returns (bytes32 contractId) {
        // Get the template details
        (
            bytes32 id,
            string memory templateName,
            string memory description,
            uint8 jurisdiction,
            bytes32 category,
            bytes32 templateContentHash,
            address creator,
            bool isApproved,
            uint256 createdAt,
            uint256 updatedAt
        ) = getTemplate(templateId);
        
        // Check that the template exists and is approved
        require(id == templateId, "LegalContractExecution: template does not exist");
        require(isApproved, "LegalContractExecution: template is not approved");
        
        // Check that the jurisdiction is active
        require(
            _jurisdictionRegistry.isJurisdictionActive(jurisdiction),
            "LegalContractExecution: jurisdiction is not active"
        );
        
        // Check that all parties have verified identities
        for (uint256 i = 0; i < parties.length; i++) {
            require(
                _identityManager.isVerified(parties[i], jurisdiction, IIdentity.VerificationLevel.BASIC),
                "LegalContractExecution: party does not have verified identity"
            );
        }
        
        // Generate a unique contract ID
        contractId = keccak256(abi.encodePacked(msg.sender, templateId, block.timestamp));
        
        // Create the contract
        LegalContract storage legalContract = _contracts[contractId];
        legalContract.id = contractId;
        legalContract.name = name;
        legalContract.templateId = templateId;
        legalContract.jurisdiction = jurisdiction;
        legalContract.contentHash = contentHash;
        legalContract.status = ContractStatus.DRAFT;
        legalContract.creator = msg.sender;
        legalContract.parties = parties;
        legalContract.effectiveDate = effectiveDate;
        legalContract.expirationDate = expirationDate;
        legalContract.createdAt = block.timestamp;
        legalContract.updatedAt = block.timestamp;
        
        // Add the contract to the creator's contracts
        _userContracts[msg.sender].push(contractId);
        
        // Add the contract to each party's contracts
        for (uint256 i = 0; i < parties.length; i++) {
            if (parties[i] != msg.sender) {
                _userContracts[parties[i]].push(contractId);
            }
        }
        
        // Check compliance
        ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
        (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
            jurisdictionEnum,
            "LEGAL_CONTRACT_CREATE",
            abi.encode(msg.sender, templateId, parties)
        );
        
        require(isCompliant, "LegalContractExecution: contract creation is not compliant");
        
        // Emit the contract created event
        emit ContractCreated(
            contractId,
            templateId,
            msg.sender,
            jurisdiction,
            block.timestamp
        );
        
        return contractId;
    }
    
    /**
     * @dev Finalizes a contract draft and changes status to pending signatures
     * @param contractId The ID of the contract
     * @return success Whether the finalization was successful
     */
    function finalizeContractDraft(bytes32 contractId)
        external
        onlyContractCreator(contractId)
        returns (bool success)
    {
        LegalContract storage legalContract = _contracts[contractId];
        
        // Check that the contract is in draft status
        require(
            legalContract.status == ContractStatus.DRAFT,
            "LegalContractExecution: contract is not in draft status"
        );
        
        // Update the contract status
        legalContract.status = ContractStatus.PENDING_SIGNATURES;
        legalContract.updatedAt = block.timestamp;
        
        return true;
    }
    
    /**
     * @dev Signs a contract
     * @param contractId The ID of the contract
     * @return success Whether the signing was successful
     */
    function signContract(bytes32 contractId)
        external
        onlyContractParty(contractId)
        returns (bool success)
    {
        LegalContract storage legalContract = _contracts[contractId];
        
        // Check that the contract is pending signatures
        require(
            legalContract.status == ContractStatus.PENDING_SIGNATURES,
            "LegalContractExecution: contract is not pending signatures"
        );
        
        // Check that the signer has not already signed
        require(
            !legalContract.hasSigned[msg.sender],
            "LegalContractExecution: signer has already signed"
        );
        
        // Record the signature
        legalContract.hasSigned[msg.sender] = true;
        legalContract.signatureTimestamps[msg.sender] = block.timestamp;
        legalContract.updatedAt = block.timestamp;
        
        // Emit the contract signed event
        emit ContractSigned(
            contractId,
            msg.sender,
            block.timestamp
        );
        
        // Check if all parties have signed
        bool allSigned = true;
        for (uint256 i = 0; i < legalContract.parties.length; i++) {
            if (!legalContract.hasSigned[legalContract.parties[i]]) {
                allSigned = false;
                break;
            }
        }
        
        // If all parties have signed, execute the contract
        if (allSigned) {
            legalContract.status = ContractStatus.EXECUTED;
            
            // Emit the contract executed event
            emit ContractExecuted(
                contractId,
                legalContract.effectiveDate,
                legalContract.expirationDate,
                block.timestamp
            );
        }
        
        return true;
    }
    
    /**
     * @dev Terminates a contract
     * @param contractId The ID of the contract
     * @param reason The reason for termination
     * @return success Whether the termination was successful
     */
    function terminateContract(bytes32 contractId, string calldata reason)
        external
        onlyContractParty(contractId)
        returns (bool success)
    {
        LegalContract storage legalContract = _contracts[contractId];
        
        // Check that the contract is executed
        require(
            legalContract.status == ContractStatus.EXECUTED,
            "LegalContractExecution: contract is not executed"
        );
        
        // Update the contract status
        legalContract.status = ContractStatus.TERMINATED;
        legalContract.updatedAt = block.timestamp;
        
        // Emit the contract terminated event
        emit ContractTerminated(
            contractId,
            msg.sender,
            reason,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Raises a dispute for a contract
     * @param contractId The ID of the contract
     * @param reason The reason for the dispute
     * @return success Whether the dispute was raised successfully
     */
    function disputeContract(bytes32 contractId, string calldata reason)
        external
        onlyContractParty(contractId)
        returns (bool success)
    {
        LegalContract storage legalContract = _contracts[contractId];
        
        // Check that the contract is executed
        require(
            legalContract.status == ContractStatus.EXECUTED,
            "LegalContractExecution: contract is not executed"
        );
        
        // Update the contract status
        legalContract.status = ContractStatus.DISPUTED;
        legalContract.updatedAt = block.timestamp;
        
        // Emit the contract disputed event
        emit ContractDisputed(
            contractId,
            msg.sender,
            reason,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Gets the details of a contract
     * @param contractId The ID of the contract
     * @return contract The contract details
     */
    function getContract(bytes32 contractId) external view returns (LegalContractView memory contract) {
        LegalContract storage legalContract = _contracts[contractId];
        
        // Create a view of the contract without mappings
        return LegalContractView({
            id: legalContract.id,
            name: legalContract.name,
            templateId: legalContract.templateId,
            jurisdiction: legalContract.jurisdiction,
            contentHash: legalContract.contentHash,
            status: legalContract.status,
            creator: legalContract.creator,
            parties: legalContract.parties,
            effectiveDate: legalContract.effectiveDate,
            expirationDate: legalContract.expirationDate,
            createdAt: legalContract.createdAt,
            updatedAt: legalContract.updatedAt
        });
    }
    
    /**
     * @dev Checks if a party has signed a contract
     * @param contractId The ID of the contract
     * @param party The address of the party
     * @return hasSigned Whether the party has signed
     * @return signatureTimestamp The timestamp of the signature (0 if not signed)
     */
    function hasPartySigned(bytes32 contractId, address party)
        external
        view
        returns (bool hasSigned, uint256 signatureTimestamp)
    {
        LegalContract storage legalContract = _contracts[contractId];
        return (legalContract.hasSigned[party], legalContract.signatureTimestamps[party]);
    }
    
    /**
     * @dev Gets the contracts for a user
     * @param userAddress The address of the user
     * @return contractIds Array of contract IDs for the user
     */
    function getUserContracts(address userAddress) external view returns (bytes32[] memory contractIds) {
        return _userContracts[userAddress];
    }
    
    /**
     * @dev Gets a template from the LegalContractTemplate contract
     * @param templateId The ID of the template
     * @return Template details
     */
    function getTemplate(bytes32 templateId) internal view returns (
        bytes32 id,
        string memory name,
        string memory description,
        uint8 jurisdiction,
        bytes32 category,
        bytes32 contentHash,
        address creator,
        bool isApproved,
        uint256 createdAt,
        uint256 updatedAt
    ) {
        // Call the LegalContractTemplate contract to get the template details
        bytes memory data = abi.encodeWithSignature("getTemplate(bytes32)", templateId);
        (bool success, bytes memory returnData) = _legalContractTemplate.staticcall(data);
        
        require(success, "LegalContractExecution: failed to get template");
        
        // Decode the template details
        return abi.decode(returnData, (
            bytes32,
            string,
            string,
            uint8,
            bytes32,
            bytes32,
            address,
            bool,
            uint256,
            uint256
        ));
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
    
    /**
     * @dev Sets the legal contract template address
     * @param legalContractTemplate Address of the legal contract template contract
     * @return success Whether the update was successful
     */
    function setLegalContractTemplate(address legalContractTemplate) external onlyOwner returns (bool success) {
        _legalContractTemplate = legalContractTemplate;
        return true;
    }
}
