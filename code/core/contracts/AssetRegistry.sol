// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IAsset.sol";
import "../interfaces/ICompliance.sol";

/**
 * @title AssetRegistry
 * @dev Implementation of the IAsset interface for managing assets across jurisdictions
 */
contract AssetRegistry is IAsset {
    // Mapping from asset ID to asset details
    mapping(bytes32 => Asset) private _assets;
    
    // Mapping from owner to asset IDs
    mapping(address => bytes32[]) private _ownerAssets;
    
    // Mapping from asset type to asset IDs
    mapping(AssetType => bytes32[]) private _assetsByType;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Contract owner
    address private _owner;
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "AssetRegistry: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the asset owner
     * @param assetId The ID of the asset
     */
    modifier onlyAssetOwner(bytes32 assetId) {
        require(_assets[assetId].owner == msg.sender, "AssetRegistry: caller is not the asset owner");
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
     * @inheritdoc IAsset
     */
    function createAsset(
        AssetType assetType,
        bytes32 metadataHash,
        uint8 jurisdiction,
        bytes calldata data
    ) external override returns (bytes32 assetId) {
        // Generate a unique asset ID
        assetId = keccak256(abi.encodePacked(msg.sender, assetType, metadataHash, block.timestamp));
        
        // Create the asset
        Asset memory asset = Asset({
            id: assetId,
            assetType: assetType,
            owner: msg.sender,
            metadataHash: metadataHash,
            status: AssetStatus.CREATED,
            jurisdiction: jurisdiction,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        // Store the asset
        _assets[assetId] = asset;
        _ownerAssets[msg.sender].push(assetId);
        _assetsByType[assetType].push(assetId);
        
        // Emit the asset creation event
        emit AssetCreated(
            assetId,
            assetType,
            msg.sender,
            metadataHash,
            jurisdiction,
            block.timestamp
        );
        
        return assetId;
    }
    
    /**
     * @inheritdoc IAsset
     */
    function transferAsset(
        bytes32 assetId,
        address newOwner,
        bytes calldata data
    ) external override onlyAssetOwner(assetId) returns (bool success) {
        // Check that the asset exists and is transferable
        Asset storage asset = _assets[assetId];
        require(asset.status == AssetStatus.ACTIVE, "AssetRegistry: asset is not active");
        
        // Check compliance if a compliance registry is set
        if (address(_complianceRegistry) != address(0)) {
            // Convert jurisdiction to the enum type expected by the compliance registry
            ICompliance.Jurisdiction jurisdiction = ICompliance.Jurisdiction(asset.jurisdiction);
            
            // Check if the transfer is compliant
            (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
                jurisdiction,
                "ASSET_TRANSFER",
                abi.encode(msg.sender, newOwner, assetId)
            );
            
            require(isCompliant, "AssetRegistry: transfer is not compliant");
        }
        
        // Store the previous owner for the event
        address previousOwner = asset.owner;
        
        // Update the asset owner
        asset.owner = newOwner;
        asset.updatedAt = block.timestamp;
        
        // Update the owner-asset mappings
        // Note: This is a simplified implementation that doesn't remove the asset from the previous owner's list
        // In a production environment, you would want to maintain this mapping more carefully
        _ownerAssets[newOwner].push(assetId);
        
        // Emit the asset transfer event
        emit AssetTransferred(
            assetId,
            previousOwner,
            newOwner,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc IAsset
     */
    function getAsset(bytes32 assetId) external view override returns (Asset memory asset) {
        return _assets[assetId];
    }
    
    /**
     * @inheritdoc IAsset
     */
    function ownerOf(bytes32 assetId) external view override returns (address owner) {
        return _assets[assetId].owner;
    }
    
    /**
     * @inheritdoc IAsset
     */
    function updateAssetStatus(
        bytes32 assetId,
        AssetStatus newStatus,
        bytes calldata data
    ) external override onlyAssetOwner(assetId) returns (bool success) {
        Asset storage asset = _assets[assetId];
        AssetStatus previousStatus = asset.status;
        
        // Update the asset status
        asset.status = newStatus;
        asset.updatedAt = block.timestamp;
        
        // Emit the asset status update event
        emit AssetStatusUpdated(
            assetId,
            previousStatus,
            newStatus,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc IAsset
     */
    function updateAssetMetadata(
        bytes32 assetId,
        bytes32 newMetadataHash,
        bytes calldata data
    ) external override onlyAssetOwner(assetId) returns (bool success) {
        Asset storage asset = _assets[assetId];
        
        // Update the asset metadata
        asset.metadataHash = newMetadataHash;
        asset.updatedAt = block.timestamp;
        
        return true;
    }
    
    /**
     * @inheritdoc IAsset
     */
    function getAssetsByOwner(
        address owner,
        uint8 assetType,
        uint256 startIndex,
        uint256 limit
    ) external view override returns (bytes32[] memory assetIds, uint256 totalCount) {
        bytes32[] storage ownerAssetIds = _ownerAssets[owner];
        uint256 ownerAssetCount = ownerAssetIds.length;
        
        // Count assets of the specified type
        if (assetType > 0) {
            uint256 typeCount = 0;
            for (uint256 i = 0; i < ownerAssetCount; i++) {
                if (uint8(_assets[ownerAssetIds[i]].assetType) == assetType) {
                    typeCount++;
                }
            }
            totalCount = typeCount;
        } else {
            totalCount = ownerAssetCount;
        }
        
        // Handle pagination
        uint256 resultCount = limit;
        if (startIndex + resultCount > totalCount) {
            resultCount = totalCount > startIndex ? totalCount - startIndex : 0;
        }
        
        // Create the result array
        assetIds = new bytes32[](resultCount);
        
        // Fill the result array
        if (resultCount > 0) {
            uint256 resultIndex = 0;
            
            for (uint256 i = 0; i < ownerAssetCount && resultIndex < resultCount; i++) {
                bytes32 currentAssetId = ownerAssetIds[i];
                
                // Filter by asset type if specified
                if (assetType > 0 && uint8(_assets[currentAssetId].assetType) != assetType) {
                    continue;
                }
                
                // Skip assets before the start index
                if (i < startIndex) {
                    continue;
                }
                
                assetIds[resultIndex] = currentAssetId;
                resultIndex++;
            }
        }
        
        return (assetIds, totalCount);
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
     * @dev Gets all assets of a specific type
     * @param assetType The type of assets to get
     * @param startIndex Start index for pagination
     * @param limit Maximum number of assets to return
     * @return assetIds Array of asset IDs of the specified type
     * @return totalCount Total number of assets of the specified type
     */
    function getAssetsByType(
        AssetType assetType,
        uint256 startIndex,
        uint256 limit
    ) external view returns (bytes32[] memory assetIds, uint256 totalCount) {
        bytes32[] storage typeAssetIds = _assetsByType[assetType];
        totalCount = typeAssetIds.length;
        
        // Handle pagination
        uint256 resultCount = limit;
        if (startIndex + resultCount > totalCount) {
            resultCount = totalCount > startIndex ? totalCount - startIndex : 0;
        }
        
        // Create the result array
        assetIds = new bytes32[](resultCount);
        
        // Fill the result array
        for (uint256 i = 0; i < resultCount; i++) {
            assetIds[i] = typeAssetIds[startIndex + i];
        }
        
        return (assetIds, totalCount);
    }
}
