// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IAsset.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IDocument.sol";
import "../../core/interfaces/IJurisdiction.sol";

/**
 * @title RealEstateToken
 * @dev Implementation for tokenizing real estate properties across Southeast Asian jurisdictions
 */
contract RealEstateToken {
    // Asset registry interface
    IAsset private _assetRegistry;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Document registry interface
    IDocument private _documentRegistry;
    
    // Jurisdiction registry interface
    IJurisdiction private _jurisdictionRegistry;
    
    // Contract owner
    address private _owner;
    
    // Mapping from property ID to property details
    mapping(bytes32 => Property) private _properties;
    
    // Mapping from jurisdiction to required document types
    mapping(uint8 => IDocument.DocumentType[]) private _requiredDocuments;
    
    // Struct containing property details
    struct Property {
        bytes32 id;
        string propertyAddress;
        uint256 area;
        string propertyType;
        uint8 jurisdiction;
        bytes32 assetId;
        address owner;
        uint256 value;
        bool isVerified;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Events
    event PropertyTokenized(
        bytes32 indexed propertyId,
        bytes32 indexed assetId,
        address indexed owner,
        string propertyAddress,
        uint8 jurisdiction,
        uint256 timestamp
    );
    
    event PropertyTransferred(
        bytes32 indexed propertyId,
        address indexed previousOwner,
        address indexed newOwner,
        uint256 timestamp
    );
    
    event PropertyVerified(
        bytes32 indexed propertyId,
        address indexed verifier,
        uint256 timestamp
    );
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "RealEstateToken: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the property owner
     * @param propertyId The ID of the property
     */
    modifier onlyPropertyOwner(bytes32 propertyId) {
        require(_properties[propertyId].owner == msg.sender, "RealEstateToken: caller is not the property owner");
        _;
    }
    
    /**
     * @dev Constructor
     * @param assetRegistry Address of the asset registry contract
     * @param complianceRegistry Address of the compliance registry contract
     * @param documentRegistry Address of the document registry contract
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     */
    constructor(
        address assetRegistry,
        address complianceRegistry,
        address documentRegistry,
        address jurisdictionRegistry
    ) {
        _owner = msg.sender;
        _assetRegistry = IAsset(assetRegistry);
        _complianceRegistry = ICompliance(complianceRegistry);
        _documentRegistry = IDocument(documentRegistry);
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
        
        // Initialize required documents for each jurisdiction
        // Malaysia
        _requiredDocuments[0] = [
            IDocument.DocumentType.PROPERTY_TITLE,
            IDocument.DocumentType.IDENTITY,
            IDocument.DocumentType.CERTIFICATE
        ];
        
        // Singapore
        _requiredDocuments[1] = [
            IDocument.DocumentType.PROPERTY_TITLE,
            IDocument.DocumentType.IDENTITY,
            IDocument.DocumentType.CERTIFICATE,
            IDocument.DocumentType.REGULATORY_FILING
        ];
        
        // Indonesia
        _requiredDocuments[2] = [
            IDocument.DocumentType.PROPERTY_TITLE,
            IDocument.DocumentType.IDENTITY,
            IDocument.DocumentType.CERTIFICATE
        ];
        
        // Brunei
        _requiredDocuments[3] = [
            IDocument.DocumentType.PROPERTY_TITLE,
            IDocument.DocumentType.IDENTITY,
            IDocument.DocumentType.CERTIFICATE
        ];
        
        // Thailand
        _requiredDocuments[4] = [
            IDocument.DocumentType.PROPERTY_TITLE,
            IDocument.DocumentType.IDENTITY,
            IDocument.DocumentType.CERTIFICATE
        ];
        
        // Cambodia
        _requiredDocuments[5] = [
            IDocument.DocumentType.PROPERTY_TITLE,
            IDocument.DocumentType.IDENTITY,
            IDocument.DocumentType.CERTIFICATE
        ];
        
        // Vietnam
        _requiredDocuments[6] = [
            IDocument.DocumentType.PROPERTY_TITLE,
            IDocument.DocumentType.IDENTITY,
            IDocument.DocumentType.CERTIFICATE,
            IDocument.DocumentType.REGULATORY_FILING
        ];
        
        // Laos
        _requiredDocuments[7] = [
            IDocument.DocumentType.PROPERTY_TITLE,
            IDocument.DocumentType.IDENTITY,
            IDocument.DocumentType.CERTIFICATE
        ];
    }
    
    /**
     * @dev Tokenizes a real estate property
     * @param propertyAddress The physical address of the property
     * @param area The area of the property in square meters
     * @param propertyType The type of property (e.g., "Residential", "Commercial")
     * @param jurisdiction The jurisdiction code for the property
     * @param value The value of the property
     * @param documentIds Array of document IDs associated with the property
     * @return propertyId The unique identifier for the tokenized property
     */
    function tokenizeProperty(
        string calldata propertyAddress,
        uint256 area,
        string calldata propertyType,
        uint8 jurisdiction,
        uint256 value,
        bytes32[] calldata documentIds
    ) external returns (bytes32 propertyId) {
        // Check that the jurisdiction is active
        require(
            _jurisdictionRegistry.isJurisdictionActive(jurisdiction),
            "RealEstateToken: jurisdiction is not active"
        );
        
        // Verify required documents
        verifyRequiredDocuments(jurisdiction, documentIds);
        
        // Generate a unique property ID
        propertyId = keccak256(abi.encodePacked(msg.sender, propertyAddress, block.timestamp));
        
        // Create the property asset in the asset registry
        bytes32 assetId = _assetRegistry.createAsset(
            IAsset.AssetType.REAL_ESTATE,
            keccak256(abi.encodePacked(propertyId)),
            jurisdiction,
            abi.encode(propertyAddress, area, propertyType, value)
        );
        
        // Create the property
        Property memory property = Property({
            id: propertyId,
            propertyAddress: propertyAddress,
            area: area,
            propertyType: propertyType,
            jurisdiction: jurisdiction,
            assetId: assetId,
            owner: msg.sender,
            value: value,
            isVerified: false,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        // Store the property
        _properties[propertyId] = property;
        
        // Link documents to the asset
        for (uint256 i = 0; i < documentIds.length; i++) {
            _documentRegistry.linkDocumentToAsset(documentIds[i], assetId, "PROPERTY_DOCUMENT");
        }
        
        // Check compliance
        ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(jurisdiction);
        (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
            jurisdictionEnum,
            "PROPERTY_TOKENIZE",
            abi.encode(msg.sender, propertyAddress, value)
        );
        
        require(isCompliant, "RealEstateToken: property tokenization is not compliant");
        
        // Emit the property tokenized event
        emit PropertyTokenized(
            propertyId,
            assetId,
            msg.sender,
            propertyAddress,
            jurisdiction,
            block.timestamp
        );
        
        return propertyId;
    }
    
    /**
     * @dev Transfers ownership of a property
     * @param propertyId The ID of the property
     * @param newOwner The address of the new owner
     * @return success Whether the transfer was successful
     */
    function transferProperty(bytes32 propertyId, address newOwner)
        external
        onlyPropertyOwner(propertyId)
        returns (bool success)
    {
        Property storage property = _properties[propertyId];
        
        // Check that the property is verified
        require(property.isVerified, "RealEstateToken: property is not verified");
        
        // Transfer the asset in the asset registry
        bool assetTransferred = _assetRegistry.transferAsset(
            property.assetId,
            newOwner,
            abi.encode(propertyId)
        );
        
        require(assetTransferred, "RealEstateToken: asset transfer failed");
        
        // Store the previous owner for the event
        address previousOwner = property.owner;
        
        // Update the property owner
        property.owner = newOwner;
        property.updatedAt = block.timestamp;
        
        // Emit the property transferred event
        emit PropertyTransferred(
            propertyId,
            previousOwner,
            newOwner,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Verifies a property
     * @param propertyId The ID of the property
     * @return success Whether the verification was successful
     */
    function verifyProperty(bytes32 propertyId) external onlyOwner returns (bool success) {
        Property storage property = _properties[propertyId];
        
        // Check that the property exists
        require(property.id == propertyId, "RealEstateToken: property does not exist");
        
        // Check that the property is not already verified
        require(!property.isVerified, "RealEstateToken: property is already verified");
        
        // Update the property verification status
        property.isVerified = true;
        property.updatedAt = block.timestamp;
        
        // Update the asset status in the asset registry
        _assetRegistry.updateAssetStatus(
            property.assetId,
            IAsset.AssetStatus.ACTIVE,
            abi.encode(propertyId)
        );
        
        // Emit the property verified event
        emit PropertyVerified(
            propertyId,
            msg.sender,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Gets the details of a property
     * @param propertyId The ID of the property
     * @return property The property details
     */
    function getProperty(bytes32 propertyId) external view returns (Property memory property) {
        return _properties[propertyId];
    }
    
    /**
     * @dev Gets the documents associated with a property
     * @param propertyId The ID of the property
     * @return documentIds Array of document IDs associated with the property
     */
    function getPropertyDocuments(bytes32 propertyId) external view returns (bytes32[] memory documentIds) {
        Property storage property = _properties[propertyId];
        return _documentRegistry.getDocumentsByAsset(property.assetId, "PROPERTY_DOCUMENT");
    }
    
    /**
     * @dev Verifies that all required documents for a jurisdiction are provided
     * @param jurisdiction The jurisdiction code
     * @param documentIds Array of document IDs to verify
     */
    function verifyRequiredDocuments(uint8 jurisdiction, bytes32[] calldata documentIds) internal view {
        IDocument.DocumentType[] storage required = _requiredDocuments[jurisdiction];
        
        // Check that all required document types are provided
        for (uint256 i = 0; i < required.length; i++) {
            bool found = false;
            IDocument.DocumentType requiredType = required[i];
            
            for (uint256 j = 0; j < documentIds.length; j++) {
                IDocument.Document memory doc = _documentRegistry.getDocument(documentIds[j]);
                
                if (doc.documentType == requiredType && doc.jurisdiction == jurisdiction) {
                    found = true;
                    break;
                }
            }
            
            require(found, "RealEstateToken: missing required document");
        }
    }
    
    /**
     * @dev Updates the required documents for a jurisdiction
     * @param jurisdiction The jurisdiction code
     * @param documentTypes Array of required document types
     * @return success Whether the update was successful
     */
    function updateRequiredDocuments(uint8 jurisdiction, IDocument.DocumentType[] calldata documentTypes)
        external
        onlyOwner
        returns (bool success)
    {
        _requiredDocuments[jurisdiction] = documentTypes;
        return true;
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
}
