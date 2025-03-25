// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IDocument.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IJurisdiction.sol";

/**
 * @title LegalContractTemplate
 * @dev Implementation for managing legal contract templates across Southeast Asian jurisdictions
 */
contract LegalContractTemplate {
    // Document registry interface
    IDocument private _documentRegistry;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Jurisdiction registry interface
    IJurisdiction private _jurisdictionRegistry;
    
    // Contract owner
    address private _owner;
    
    // Mapping from template ID to template details
    mapping(bytes32 => Template) private _templates;
    
    // Mapping from jurisdiction to template IDs
    mapping(uint8 => bytes32[]) private _jurisdictionTemplates;
    
    // Mapping from template category to template IDs
    mapping(bytes32 => bytes32[]) private _categoryTemplates;
    
    // Struct containing template details
    struct Template {
        bytes32 id;
        string name;
        string description;
        uint8 jurisdiction;
        bytes32 category;
        bytes32 contentHash;
        address creator;
        bool isApproved;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Events
    event TemplateCreated(
        bytes32 indexed templateId,
        string name,
        uint8 indexed jurisdiction,
        bytes32 indexed category,
        address creator,
        uint256 timestamp
    );
    
    event TemplateApproved(
        bytes32 indexed templateId,
        address indexed approver,
        uint256 timestamp
    );
    
    event TemplateUpdated(
        bytes32 indexed templateId,
        bytes32 previousContentHash,
        bytes32 newContentHash,
        uint256 timestamp
    );
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "LegalContractTemplate: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the template creator
     * @param templateId The ID of the template
     */
    modifier onlyTemplateCreator(bytes32 templateId) {
        require(_templates[templateId].creator == msg.sender, "LegalContractTemplate: caller is not the template creator");
        _;
    }
    
    /**
     * @dev Constructor
     * @param documentRegistry Address of the document registry contract
     * @param complianceRegistry Address of the compliance registry contract
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     */
    constructor(
        address documentRegistry,
        address complianceRegistry,
        address jurisdictionRegistry
    ) {
        _owner = msg.sender;
        _documentRegistry = IDocument(documentRegistry);
        _complianceRegistry = ICompliance(complianceRegistry);
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
    }
    
    /**
     * @dev Creates a new legal contract template
     * @param name The name of the template
     * @param description The description of the template
     * @param jurisdiction The jurisdiction code for the template
     * @param category The category of the template
     * @param contentHash The hash of the template content
     * @return templateId The unique identifier for the created template
     */
    function createTemplate(
        string calldata name,
        string calldata description,
        uint8 jurisdiction,
        bytes32 category,
        bytes32 contentHash
    ) external returns (bytes32 templateId) {
        // Check that the jurisdiction is active
        require(
            _jurisdictionRegistry.isJurisdictionActive(jurisdiction),
            "LegalContractTemplate: jurisdiction is not active"
        );
        
        // Generate a unique template ID
        templateId = keccak256(abi.encodePacked(msg.sender, name, jurisdiction, block.timestamp));
        
        // Create the template
        Template memory template = Template({
            id: templateId,
            name: name,
            description: description,
            jurisdiction: jurisdiction,
            category: category,
            contentHash: contentHash,
            creator: msg.sender,
            isApproved: false,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        // Store the template
        _templates[templateId] = template;
        
        // Add the template to the jurisdiction templates
        _jurisdictionTemplates[jurisdiction].push(templateId);
        
        // Add the template to the category templates
        _categoryTemplates[category].push(templateId);
        
        // Check compliance
        ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
        (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
            jurisdictionEnum,
            "LEGAL_TEMPLATE_CREATE",
            abi.encode(msg.sender, name, category)
        );
        
        require(isCompliant, "LegalContractTemplate: template creation is not compliant");
        
        // Emit the template created event
        emit TemplateCreated(
            templateId,
            name,
            jurisdiction,
            category,
            msg.sender,
            block.timestamp
        );
        
        return templateId;
    }
    
    /**
     * @dev Approves a legal contract template
     * @param templateId The ID of the template
     * @return success Whether the approval was successful
     */
    function approveTemplate(bytes32 templateId) external onlyOwner returns (bool success) {
        Template storage template = _templates[templateId];
        
        // Check that the template exists
        require(template.id == templateId, "LegalContractTemplate: template does not exist");
        
        // Check that the template is not already approved
        require(!template.isApproved, "LegalContractTemplate: template is already approved");
        
        // Update the template approval status
        template.isApproved = true;
        template.updatedAt = block.timestamp;
        
        // Emit the template approved event
        emit TemplateApproved(
            templateId,
            msg.sender,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Updates a legal contract template
     * @param templateId The ID of the template
     * @param description The new description of the template
     * @param contentHash The new hash of the template content
     * @return success Whether the update was successful
     */
    function updateTemplate(
        bytes32 templateId,
        string calldata description,
        bytes32 contentHash
    ) external onlyTemplateCreator(templateId) returns (bool success) {
        Template storage template = _templates[templateId];
        
        // Store the previous content hash for the event
        bytes32 previousContentHash = template.contentHash;
        
        // Update the template details
        template.description = description;
        template.contentHash = contentHash;
        template.isApproved = false; // Reset approval status
        template.updatedAt = block.timestamp;
        
        // Emit the template updated event
        emit TemplateUpdated(
            templateId,
            previousContentHash,
            contentHash,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Gets the details of a template
     * @param templateId The ID of the template
     * @return template The template details
     */
    function getTemplate(bytes32 templateId) external view returns (Template memory template) {
        return _templates[templateId];
    }
    
    /**
     * @dev Gets the templates for a jurisdiction
     * @param jurisdiction The jurisdiction code
     * @return templateIds Array of template IDs for the jurisdiction
     */
    function getJurisdictionTemplates(uint8 jurisdiction) external view returns (bytes32[] memory templateIds) {
        return _jurisdictionTemplates[jurisdiction];
    }
    
    /**
     * @dev Gets the templates for a category
     * @param category The category
     * @return templateIds Array of template IDs for the category
     */
    function getCategoryTemplates(bytes32 category) external view returns (bytes32[] memory templateIds) {
        return _categoryTemplates[category];
    }
    
    /**
     * @dev Gets the approved templates for a jurisdiction
     * @param jurisdiction The jurisdiction code
     * @return templateIds Array of approved template IDs for the jurisdiction
     */
    function getApprovedJurisdictionTemplates(uint8 jurisdiction) external view returns (bytes32[] memory templateIds) {
        bytes32[] storage allTemplates = _jurisdictionTemplates[jurisdiction];
        uint256 count = allTemplates.length;
        
        // Count approved templates
        uint256 approvedCount = 0;
        for (uint256 i = 0; i < count; i++) {
            if (_templates[allTemplates[i]].isApproved) {
                approvedCount++;
            }
        }
        
        // Create the result array
        templateIds = new bytes32[](approvedCount);
        
        // Fill the result array
        uint256 resultIndex = 0;
        for (uint256 i = 0; i < count && resultIndex < approvedCount; i++) {
            if (_templates[allTemplates[i]].isApproved) {
                templateIds[resultIndex] = allTemplates[i];
                resultIndex++;
            }
        }
        
        return templateIds;
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
}
